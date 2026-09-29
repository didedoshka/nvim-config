"""Let DAP `stepIn` reach user code through skipped library code.

gdb steps over a skipped function together with everything it calls, so with
the skips in ~/.config/gdb/gdbinit (libc++, contrib/libs, util/) `step` on
`converter(&cursor, &writer)` never stops in the functor a std::function
wraps -- nor in a sort comparator, a THashMap hash, anything library code
calls back. `skip` has no "step through" mode. So this re-registers `stepIn`:
with the skips disabled it steps line by line until it stops outside skipped
code, then reports that one stop. The way back works the same: stepping off
the end of a callback walks through the library to the next user line (or
the next callback).

Measured facts this relies on (gdb 17.2, DAP interpreter):
- `gdb.execute("step")` blocks until the stop, so the chain is a plain loop.
- A DAP `pause` still gets through during it: gdb runs posted events from the
  nested event loop of a synchronous command, so `interrupt -a` stops the
  running step (reported as SIGINT, i.e. `pause`). A pause that lands
  between two steps interrupts nothing, which is why the loop also checks
  `events._expected_pause`.

The skip list stays in gdbinit: `info skip` is parsed at every stepIn and
matched the way gdb's skip.c does (glob components against the tail of
`symtab.fullname()`, regexes against the function's print name). Frames
without debug info count as skipped.

Library code that loops for long is stepped line by line, not run at full
speed; progressStart/Update/End events report it (dap.status()), and `pause`
ends the chain wherever it is. See
~/a/notes/gdb-dap-step-into-callbacks-through-skipped-code.md.
"""

import fnmatch
import os
import re
import time

import gdb
import gdb.dap.events as events
from gdb.dap.events import exec_and_expect_stop
from gdb.dap.next import _handle_thread_step
from gdb.dap.server import _commands, request, send_event
from gdb.dap.startup import in_gdb_thread, log

# Private names of gdb's DAP module; a gdb upgrade may rename them. Fail here,
# at load, with upstream stepIn still registered, rather than mid-step.
for _name in ("_on_stop", "_suppress_cont", "_expected_stop_reason", "_expected_pause"):
    if not hasattr(events, _name):
        raise ImportError("dap_step.py: gdb.dap.events.%s is gone, stepIn left as upstream" % _name)

# Wait this long before announcing progress: most chains (std::function,
# a comparator) take a dozen steps and should not flash a message.
PROGRESS_DELAY = 0.5
PROGRESS_PERIOD = 0.5

# Num Enb Glob File RE Function; File and Function read `<none>` when unset.
_INFO_SKIP_ROW = re.compile(r"^(\d+)\s+([yn])\s+([yn])\s+(\S+)\s+([yn])\s+(.+?)\s*$")


def _glob_match(pattern, path):
    # fnmatch with FNM_FILE_NAME: `*` never crosses `/`, so match component by
    # component (Python's fnmatch alone would let `*` span directories).
    p, s = pattern.split("/"), path.split("/")
    return len(p) == len(s) and all(fnmatch.fnmatchcase(n, g) for g, n in zip(p, s))


def _glob_tail_match(pattern, path):
    # compare_glob_filenames_for_search: a relative pattern of N components
    # matches the last N components of the path.
    p, s = pattern.split("/"), path.split("/")
    if len(p) > len(s) or (pattern.startswith("/") and len(p) != len(s)):
        return False
    return _glob_match(pattern, "/".join(s[len(s) - len(p):]))


def _tail_match(name, path):
    # compare_filenames_for_search: equal, or a suffix starting at a `/`.
    return path == name or (not name.startswith("/") and path.endswith("/" + name))


class _Skip:
    def __init__(self, number, glob, file, regex, function):
        self.number = number
        self.glob = glob
        self.file = None if file == "<none>" else file
        self.function = None if function == "<none>" else function
        self.regex = re.compile(function) if regex and self.function else None

    def _file_matches(self, symtab):
        match, tail = (_glob_match, _glob_tail_match) if self.glob else (_tail_match, _tail_match)
        return match(self.file, symtab.filename) or tail(self.file, symtab.fullname())

    def _function_matches(self, name):
        if self.regex:
            return self.regex.search(name) is not None
        # strcmp_iw: whitespace-insensitive, and `foo` also matches `foo(int)`.
        want, have = re.sub(r"\s", "", self.function), re.sub(r"\s", "", name)
        return have == want or have.startswith(want + "(")

    def matches(self, name, symtab):
        by_file = self.file is not None and symtab is not None and self._file_matches(symtab)
        by_function = self.function is not None and self._function_matches(name)
        if self.file is not None and self.function is not None:
            return by_file and by_function
        return by_file or by_function


@in_gdb_thread
def _enabled_skips():
    skips = []
    for line in gdb.execute("info skip", to_string=True).splitlines():
        if line.startswith("Num") or line.startswith("Not skipping"):
            continue
        m = _INFO_SKIP_ROW.match(line)
        if m is None:
            raise gdb.GdbError("dap_step.py: cannot parse `info skip` row: %r" % line)
        number, enabled, glob, file, regex, function = m.groups()
        if enabled == "y":
            skips.append(_Skip(int(number), glob == "y", file, regex == "y", function))
    return skips


@in_gdb_thread
def _in_skipped_code(frame, skips):
    function = frame.function()
    if function is None:
        return True
    symtab = function.symtab or frame.find_sal().symtab
    return any(s.matches(function.print_name, symtab) for s in skips)


# While a chain runs, stops land here instead of in the DAP client.
_chain_active = False
_swallowed = None


@in_gdb_thread
def _on_stop(event):
    global _swallowed
    if _chain_active:
        _swallowed = event
    else:
        events._on_stop(event)


gdb.events.stop.disconnect(events._on_stop)
gdb.events.stop.connect(_on_stop)


def _reason(event):
    return getattr(event, "details", {}).get("reason")


def _where(frame):
    sal = frame.find_sal()
    if sal.symtab is None:
        return frame.name() or "??"
    return "%s:%d" % (os.path.basename(sal.symtab.filename), sal.line)


@in_gdb_thread
def _step_through(skips):
    global _chain_active, _swallowed
    numbers = " ".join(str(s.number) for s in skips)
    started = time.monotonic()
    announced = None  # time of the last progress event, None before the first
    steps = 0
    report = None
    _chain_active = True
    events._expected_pause = False
    gdb.execute("skip disable " + numbers, to_string=True)
    try:
        while True:
            _swallowed = None
            events._suppress_cont = True
            try:
                gdb.execute("step", from_tty=True, to_string=True)
            except gdb.error as e:
                log("dap_step: step failed: %s" % e)
                break
            if _swallowed is None:
                # No stop: the process exited (upstream already said so), or
                # the step never resumed it and the last stop still holds.
                if not gdb.selected_inferior().threads():
                    report = None
                break
            report = _swallowed
            steps += 1
            if events._expected_pause or _reason(report) != "end-stepping-range":
                break
            frame = gdb.newest_frame()
            if not _in_skipped_code(frame, skips):
                break
            now = time.monotonic()
            if announced is None and now - started >= PROGRESS_DELAY:
                send_event("progressStart", {
                    "progressId": "dap_step",
                    "title": "stepIn",
                    "message": "through library code, %d steps, at %s" % (steps, _where(frame)),
                })
                announced = now
            elif announced is not None and now - announced >= PROGRESS_PERIOD:
                send_event("progressUpdate", {
                    "progressId": "dap_step",
                    "message": "through library code, %d steps, at %s" % (steps, _where(frame)),
                })
                announced = now
    finally:
        _chain_active = False
        log("dap_step: %d steps in %.2fs" % (steps, time.monotonic() - started))
        gdb.execute("skip enable " + numbers, to_string=True)
        if announced is not None:
            send_event("progressEnd", {
                "progressId": "dap_step",
                "message": "stepIn: %d steps through library code" % steps,
            })
        if report is not None:
            if events._expected_pause and _reason(report) == "end-stepping-range":
                # The interrupt found the inferior between two steps.
                events._expected_stop_reason = "pause"
            events._on_stop(report)


del _commands["stepIn"]


@request("stepIn", response=False)
def step_in(*, threadId: int, singleThread: bool = False, granularity: str = "statement", **args):
    _handle_thread_step(threadId, singleThread)
    if granularity == "instruction":
        exec_and_expect_stop("stepi")
        return
    try:
        skips = _enabled_skips()
    except gdb.GdbError as e:
        send_event("output", {"category": "console", "output": "%s; plain step\n" % e})
        skips = []
    # Already inside library code (a pause, a breakpoint there): nothing to
    # step through, the user asked to be there.
    if not skips or _in_skipped_code(gdb.newest_frame(), skips):
        exec_and_expect_stop("step")
        return
    _step_through(skips)
