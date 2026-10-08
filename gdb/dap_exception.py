"""Keep control when a DAP step crosses a `throw`, and walk the unwinding.

gdb follows an exception through a step only with libgcc's
`_Unwind_DebugHook`. Arcadia binaries link LLVM libunwind and libcxxrt,
which have none, so `next` over a call that throws runs until some unrelated
stop. This rebuilds the tracking from outside, with the stops a reader wants:

- a next/stepIn/stepOut cut short by an exception stops at the throw
  (reason "exception"), the throw site on top of the stack;
- from there next/stepIn stop at each cleanup landing pad outside skipped
  code (a frame being unwound destroying its locals), then in the `catch`
  body; stepOut goes straight to the `catch` body;
- an exception thrown and caught inside the stepped call, or on another
  fiber's stack, is ignored.

What it relies on (read in the sources, checked on unittester-formats):
- libcxxrt's personality routine installs every landing pad with
  `_Unwind_SetIP(context, pad)` (exception.cc) and enters it with the
  selector in rdx: 0 for a cleanup, > 0 for a catch clause.
- By the first `_Unwind_SetIP` of an exception, libunwind's search phase has
  stored the stack pointer of the catching frame in
  `exception_object->private_2` (UnwindLevel1.c) and nothing is unwound yet:
  comparing it with the stepped frame's tells whether the exception escapes
  the step while the throw site is still on the stack.
- A catch clause starts with `__cxa_begin_catch(e)`; its return address is
  the start of the catch body.

gdb forbids creating breakpoints in Breakpoint.stop(), and the next stop
point (a pad, a return address) is only known there. So stop() "relays": it
stops, the DAP client is not told, a posted event plants the breakpoint and
continues. Inside a dap_step.py chain, the chain loop does the planting
between its moves instead (chain_fast / chain_landed).

Needs dap_step.py sourced before it: every stop reaches the client through
gdb.dap.events._on_stop, looked up by name by dap_step's gdb.events.stop
hook, which this wraps; dap_step's skip matcher decides what library code is.
Sourced files share __main__, hence the _dapexc/_DapExc prefixes. x86-64 only
(rsp, rdx). See ~/a/notes/gdb-step-over-throw-loses-control.md.
"""

import __main__
import sys

import gdb
import gdb.dap.events as _dapexc_events
import gdb.dap.next as _dapexc_next
import gdb.dap.server
from gdb.dap.breakpoint import suppress_new_breakpoint_event as _dapexc_quiet
from gdb.dap.startup import log as _dapexc_log
from gdb.FrameDecorator import FrameDecorator as _DapExcFrameDecorator

# Not `import gdb.dap.server as ...`: that reads the package attribute, which
# gdb.dap.run() rebinds to the Server instance.
_dapexc_server = sys.modules["gdb.dap.server"]

# Fail at load, before touching anything, if a name this relies on is gone.
for _dapexc_owner, _dapexc_names in (
    (_dapexc_events, ("_on_stop", "_expected_stop_reason", "inferior_running", "exec_and_expect_stop")),
    (_dapexc_next, ("_handle_thread_step",)),
    (_dapexc_server, ("_commands", "request", "send_gdb_with_response")),
    (__main__, ("_enabled_skips", "_in_skipped_code", "_step_through")),
):
    for _dapexc_name in _dapexc_names:
        if not hasattr(_dapexc_owner, _dapexc_name):
            raise ImportError("dap_exception.py: %s.%s is missing (dap_step.py sourced first?)"
                              % (_dapexc_owner.__name__, _dapexc_name))
if getattr(_dapexc_events._on_stop, "_dapexc", False):
    raise ImportError("dap_exception.py: already loaded")

# Where control enters the unwinder. A dap_step chain arriving in one of them
# continues to the next landing pad instead of stepping through the unwinder.
_DAPEXC_UNWINDER_ENTRIES = frozenset((
    "__cxa_throw", "__cxa_rethrow", "_Unwind_RaiseException", "_Unwind_Resume",
    "_Unwind_Resume_or_Rethrow",
))
# The runtime is library code even when no skip rule covers it.
_DAPEXC_RUNTIME_DIRS = ("/contrib/libs/libunwind/", "/contrib/libs/cxxsupp/libcxxrt/")
# How far from the throw to look for the stepped frame; beyond, not ours.
_DAPEXC_MAX_DEPTH = 512
# Callers of the stepped frame kept as fallback references (escaping_site).
_DAPEXC_CALLERS = 32


class _DapExc:
    """All state and logic; one class so dap_step.py can reach it by name."""

    armed = False         # a step request is in flight: the breakpoints act
    stepped = []          # the stepped frame, then its callers; []: only `tracked` counts
    strict = False        # stepOut: a catch in the stepped frame itself ends nothing
    mode = "step"         # "step": stop at pads outside library code; "catch": only in the catch
    skips = []
    tracked = None        # address of the _Unwind_Exception being followed
    pending_pad = None    # (pad, thread) at a throw stop: where the walk goes next
    throw_site = None     # gdb.Frame shown on top at a throw stop
    at_throw = False
    last_stop = None      # (breakpoint, kind) of the last stop() that returned True
    relay = None          # (class, address, thread) to plant after a relay stop
    relay_pending = False # dap_step chain: continue again, a breakpoint was just planted
    chain_thread = None   # thread whose dap_step chain is following an exception
    set_ip_bp = None
    begin_catch_bp = None
    planted = []

    # -- breakpoint callbacks (no breakpoint changes in here) ------------------

    @classmethod
    def stopped_by(cls, bp, kind):
        cls.last_stop = (bp, kind)
        return True

    @classmethod
    def relay_to(cls, bp, klass, address, thread):
        cls.relay = (klass, address, thread)
        return cls.stopped_by(bp, "relay")

    @classmethod
    def on_set_ip(cls, bp):
        if not cls.armed:
            return False
        thread = gdb.selected_thread().global_num
        chain = cls.chain_thread == thread
        top = gdb.newest_frame()
        pad = int(top.read_var("value"))
        exception = top.older().read_var("exceptionObject")
        if int(exception["private_1"]) != 0:
            return False  # forced unwinding (thread cancellation), not a throw
        address = int(exception)
        if address == cls.tracked and not cls.resumed(top):
            cls.tracked = None  # a new throw (or rethrow) of that object: start over
        if address != cls.tracked:
            site = cls.escaping_site(top, int(exception["private_2"]))
            if site is not None:
                cls.tracked, cls.pending_pad, cls.throw_site = address, (pad, thread), site
                return cls.stopped_by(bp, "throw")
            if not chain:
                return False  # caught inside the stepped call, or not on its stack
            cls.tracked = address  # a chain goes wherever the exception goes
        if cls.mode == "catch" or (not chain and cls.is_library_pc(pad)):
            return False
        return cls.relay_to(bp, _DapExcPad, pad, thread)

    @classmethod
    def on_begin_catch(cls, bp):
        if not cls.armed or cls.tracked is None:
            return False
        top = gdb.newest_frame()
        if int(top.read_var("e")) != cls.tracked:
            return False
        return cls.relay_to(bp, _DapExcCatchBody, top.older().pc(),
                            gdb.selected_thread().global_num)

    @staticmethod
    def resumed(top):
        """Whether this unwinding continues after a cleanup (`_Unwind_Resume`)
        rather than starting at a throw (`_Unwind_RaiseException`)."""
        frame = top.older()
        for _ in range(8):
            if frame is None:
                return False
            name = (frame.name() or "").split("(")[0]
            if name == "_Unwind_Resume":
                return True
            if name in ("_Unwind_RaiseException", "_Unwind_Resume_or_Rethrow", "_Unwind_ForcedUnwind"):
                return False
            frame = frame.older()
        return False

    @classmethod
    def escaping_site(cls, top, handler_sp):
        """The frame to show if the exception escapes the stepped frame, else None.

        The reference is the stepped frame or, once it has returned, the
        nearest caller still there: a step off the end of a function goes on
        in the caller, and a throw there cuts it short just the same."""
        if not cls.stepped:
            return None
        site = None
        frame = top
        for _ in range(_DAPEXC_MAX_DEPTH):
            if frame is None:
                return None
            if any(frame == stepped for stepped in cls.stepped):
                # Both are the frame's SP at its call site: libunwind's cursor
                # and gdb's unwound rsp. The stack grows down.
                sp = int(frame.read_register("rsp"))
                if handler_sp > sp or (handler_sp == sp and not cls.strict):
                    return site or frame
                return None
            if site is None and not cls.is_library_frame(frame):
                site = frame
            frame = frame.older()
        return None

    @classmethod
    def is_library_frame(cls, frame):
        function = frame.function()
        if function is None:
            return True
        if cls.in_runtime(function.symtab):
            return True
        return __main__._in_skipped_code(frame, cls.skips)

    @classmethod
    def is_library_pc(cls, pc):
        block = gdb.block_for_pc(pc)
        while block is not None and block.function is None:
            block = block.superblock
        if block is None:
            return True
        function = block.function
        if cls.in_runtime(function.symtab):
            return True
        return any(s.matches(function.print_name, function.symtab) for s in cls.skips)

    @staticmethod
    def in_runtime(symtab):
        return symtab is not None and any(d in symtab.filename for d in _DAPEXC_RUNTIME_DIRS)

    # -- outside stop(): arming, planting, stop reporting -----------------------

    @classmethod
    def enable_breakpoints(cls):
        with _dapexc_quiet():
            if cls.set_ip_bp is None or not cls.set_ip_bp.is_valid():
                if (gdb.lookup_global_symbol("_Unwind_SetIP") is None
                        or gdb.lookup_global_symbol("__cxa_begin_catch") is None):
                    return False  # not LLVM libunwind + libcxxrt with debug info
                cls.set_ip_bp = _DapExcSetIP("_Unwind_SetIP", internal=True)
                cls.begin_catch_bp = _DapExcBeginCatch("__cxa_begin_catch", internal=True)
            for bp in (cls.set_ip_bp, cls.begin_catch_bp):
                if not bp.enabled:
                    bp.enabled = True
        return True

    @classmethod
    def arm(cls, name, args):
        for thread in gdb.selected_inferior().threads():
            if thread.global_num == args.get("threadId"):
                thread.switch()
        top = gdb.newest_frame()
        if not top.architecture().name().startswith("i386:x86-64"):
            return
        if not cls.enable_breakpoints():
            return
        try:
            cls.skips = __main__._enabled_skips()
        except gdb.GdbError:
            cls.skips = []
        cls.stepped = []
        frame = top
        while frame is not None and len(cls.stepped) < _DAPEXC_CALLERS:
            cls.stepped.append(frame)
            frame = frame.older()
        cls.strict = name == "stepOut"
        cls.mode = "catch" if name == "stepOut" else "step"
        cls.armed = True

    @classmethod
    def route(cls, name, args):
        """In the gdb thread, before next/stepIn/stepOut: "walk" at a throw
        stop (the request goes on to the next pad or the catch), otherwise arm
        for the request and let the registered implementation run it."""
        if _dapexc_events.inferior_running:
            return "orig"  # it answers notStopped
        if cls.at_throw:
            return "walk"
        try:
            cls.arm(name, args)
        except Exception as e:
            _dapexc_log("dap_exception: not armed: %s" % e)
        return "orig"

    @classmethod
    def walk(cls, thread_id, single_thread, mode):
        """From a throw stop, which is inside the unwinder: continue to the
        pending pad (mode "step") or to the catch (mode "catch")."""
        _dapexc_next._handle_thread_step(thread_id, single_thread)
        pad, thread = cls.pending_pad
        cls.at_throw = False
        cls.pending_pad = None
        cls.stepped = []
        cls.strict = False
        cls.mode = mode
        if cls.enable_breakpoints():
            cls.armed = True
            if mode == "step" and not cls.is_library_pc(pad):
                cls.relay = (_DapExcPad, pad, thread)
                cls.plant()
        _dapexc_events.exec_and_expect_stop("continue &")

    @classmethod
    def plant(cls):
        klass, address, thread = cls.relay
        cls.relay = None
        with _dapexc_quiet():
            bp = klass("*%#x" % address, internal=True)
            bp.thread = thread
        bp.live = True
        cls.planted.append(bp)

    @classmethod
    def kind_of(cls, event):
        if (cls.last_stop is not None and isinstance(event, gdb.BreakpointEvent)
                and cls.last_stop[0] in event.breakpoints):
            return cls.last_stop[1]
        return None

    @classmethod
    def resume_after_relay(cls):
        try:
            cls.plant()
        except Exception as e:
            _dapexc_log("dap_exception: relay failed: %s" % e)
        _dapexc_events.exec_and_expect_stop("continue &")

    @classmethod
    def reported(cls, kind):
        """A stop is going to the client: the request is over."""
        cls.armed = False
        cls.chain_thread = None
        cls.relay_pending = False
        cls.relay = None
        cls.at_throw = kind == "throw"
        if kind != "throw":
            cls.pending_pad = None
            cls.throw_site = None
        if kind == "catch":
            cls.tracked = None
        # Otherwise `tracked` survives: stepping line by line through cleanup
        # code, then over its `_Unwind_Resume`, walks on to the next pad.
        # on_set_ip drops it when the object is thrown anew.
        if kind == "throw":
            _dapexc_events._expected_stop_reason = "exception"
        elif kind in ("cleanup", "catch"):
            _dapexc_events._expected_stop_reason = "step"
        gdb.post_event(cls.disarm)

    @classmethod
    def disarm(cls):
        with _dapexc_quiet():
            if not cls.armed:
                for bp in (cls.set_ip_bp, cls.begin_catch_bp):
                    if bp is not None and bp.is_valid() and bp.enabled:
                        bp.enabled = False
            for bp in cls.planted:
                if bp.is_valid():
                    bp.delete()
        cls.planted = []

    @classmethod
    def reset(cls, event=None):
        cls.tracked = None
        cls.reported(None)

    # -- dap_step.py chain --------------------------------------------------------

    @classmethod
    def chain_fast(cls, frame):
        """True when the chain's next move should be `continue`, which this
        module stops at the exception's next landing pad, catch body or throw,
        instead of a line step through the unwinder."""
        if not cls.armed or cls.set_ip_bp is None:
            return False
        if not cls.relay_pending:
            function = frame.function()
            name = function.name if function is not None else frame.name()
            if name is None or name.split("(")[0] not in _DAPEXC_UNWINDER_ENTRIES:
                return False
        cls.relay_pending = False
        cls.chain_thread = gdb.selected_thread().global_num
        return True

    @classmethod
    def chain_landed(cls, event):
        """After chain_fast's `continue`: None to continue again (a breakpoint
        was just planted); True at a landing pad or catch body, where the chain
        goes on as after a step; False for any other stop (the throw stop, a
        user breakpoint, a signal), which the chain reports."""
        if cls.kind_of(event) == "relay":
            cls.last_stop = None
            cls.plant()
            cls.relay_pending = True
            return None
        cls.chain_thread = None
        kind = cls.kind_of(event)
        if kind == "catch":
            cls.tracked = None
        return kind in ("cleanup", "catch")


class _DapExcBreakpoint(gdb.Breakpoint):
    """Internal breakpoint whose stop() never lets a bug stop the inferior."""

    def stop(self):
        try:
            return self.check()
        except Exception as e:
            _dapexc_log("dap_exception: %s: %s" % (type(self).__name__, e))
            return False


class _DapExcSetIP(_DapExcBreakpoint):
    def check(self):
        return _DapExc.on_set_ip(self)


class _DapExcBeginCatch(_DapExcBreakpoint):
    def check(self):
        return _DapExc.on_begin_catch(self)


class _DapExcPad(_DapExcBreakpoint):
    """A landing pad of the followed exception."""

    def check(self):
        if not self.live or not _DapExc.armed:
            return False
        self.live = False
        if int(gdb.newest_frame().read_register("rdx")) > 0:
            return False  # a catch clause: __cxa_begin_catch leads to its body
        return _DapExc.stopped_by(self, "cleanup")


class _DapExcCatchBody(_DapExcBreakpoint):
    """The return address of __cxa_begin_catch: the catch body."""

    def check(self):
        if not self.live or not _DapExc.armed:
            return False
        self.live = False
        return _DapExc.stopped_by(self, "catch")


class _DapExcElided(_DapExcFrameDecorator):
    def __init__(self, base, hidden):
        super().__init__(base)
        self._hidden = hidden

    def elided(self):
        return iter(self._hidden)


class _DapExcThrowSite:
    """At a throw stop, fold the unwinder's frames into the throw site. The
    DAP stack trace drops elided frames unless the client asks for all of
    them (nvim-dap does not), so the editor opens at the throw."""

    def __init__(self):
        self.name = "dap-exception-throw-site"
        self.priority = 1000
        self.enabled = True
        gdb.frame_filters[self.name] = self

    def filter(self, frames):
        if not _DapExc.at_throw or _DapExc.throw_site is None:
            return frames
        return self._fold(frames, _DapExc.throw_site)

    @staticmethod
    def _fold(frames, site):
        hidden = []
        for decorator in frames:
            if hidden is None:
                yield decorator
            elif decorator.inferior_frame() == site:
                yield _DapExcElided(decorator, hidden)
                hidden = None
            else:
                hidden.append(decorator)
        if hidden:
            yield from hidden


_DapExcThrowSite()

_dapexc_upstream_on_stop = _dapexc_events._on_stop


def _dapexc_on_stop(event):
    kind = _DapExc.kind_of(event)
    _DapExc.last_stop = None
    if kind == "relay":
        # Not for the client: plant the next breakpoint and go on.
        gdb.post_event(_DapExc.resume_after_relay)
        return
    _DapExc.reported(kind)
    _dapexc_upstream_on_stop(event)


_dapexc_on_stop._dapexc = True
_dapexc_events._on_stop = _dapexc_on_stop
gdb.events.exited.connect(_DapExc.reset)


def _dapexc_walk_next(*, threadId: int, singleThread: bool = False,
                      granularity: str = "statement", **args):
    _DapExc.walk(threadId, singleThread, "step")


def _dapexc_walk_step_out(*, threadId: int, singleThread: bool = False, **args):
    _DapExc.walk(threadId, singleThread, "catch")


def _dapexc_register(name, walk_function, response):
    # Build the walk request with gdb's own decorator (thread dispatch,
    # notStopped check, deferred events), then unregister its temporary name.
    temporary = "dapException_" + name
    walk = _dapexc_server.request(temporary, response=response)(walk_function)
    del _dapexc_server._commands[temporary]
    original = _dapexc_server._commands[name]

    def dispatch(**args):
        route = _dapexc_server.send_gdb_with_response(lambda: _DapExc.route(name, args))
        return (walk if route == "walk" else original)(**args)

    _dapexc_server._commands[name] = dispatch


# Wraps whatever is registered now (dap_step.py's stepIn included).
_dapexc_register("next", _dapexc_walk_next, False)
_dapexc_register("stepIn", _dapexc_walk_next, False)
_dapexc_register("stepOut", _dapexc_walk_step_out, True)
