"""Teach gdb's DAP server to open a core dump.

Upstream `attach` accepts only `pid` or `target`, so a coredump session is
impossible over DAP. This re-registers `attach` with an extra `core` key.

gdb >= 16 defers launch/attach until configurationDone via
_LaunchOrAttachDeferredRequest; gdb 15 runs it inline. Support both.
"""

from typing import Optional

import gdb
import gdb.dap.events as events
from gdb.dap.events import expect_process, expect_stop
from gdb.dap.server import _commands, request, send_event
from gdb.dap.startup import DAPException, exec_and_log

try:
    from gdb.dap.launch import _LaunchOrAttachDeferredRequest, file_command

    _DEFERRED = True
except ImportError:  # gdb 15 and older
    _LaunchOrAttachDeferredRequest = None
    _DEFERRED = False

    def file_command(program):
        exec_and_log("file " + program)


del _commands["attach"]


def _do_attach(program, pid, target, core):
    if program is not None:
        file_command(program)
    if core is not None:
        cmd = "core-file " + core
    elif pid is not None:
        cmd = "attach " + str(pid)
    elif target is not None:
        cmd = "target remote " + target
    else:
        raise DAPException("attach requires 'pid', 'target' or 'core'")
    expect_process("attach")
    expect_stop("attach")
    exec_and_log(cmd)

    if core is not None:
        # Loading a core creates a thread (flipping events.inferior_running to
        # True) but never emits a stop, so every later request would answer
        # "notStopped". Settle the state by hand and announce the stop.
        events.inferior_running = False
        thread = gdb.selected_thread()
        send_event(
            "stopped",
            {
                "reason": "exception",
                "description": "core dump",
                "threadId": thread.global_num if thread else 1,
                "allThreadsStopped": True,
            },
        )
    return None


if _DEFERRED:
    from gdb.dap.server import send_gdb_with_response
    from gdb.dap.startup import in_gdb_thread

    @request("attach", on_dap_thread=True)
    def attach(
        *,
        program: Optional[str] = None,
        pid: Optional[int] = None,
        target: Optional[str] = None,
        core: Optional[str] = None,
        **args,
    ):
        @in_gdb_thread
        def go():
            return _do_attach(program, pid, target, core)

        return _LaunchOrAttachDeferredRequest(lambda: send_gdb_with_response(go))

else:

    @request("attach")
    def attach(
        *,
        program: Optional[str] = None,
        pid: Optional[int] = None,
        target: Optional[str] = None,
        core: Optional[str] = None,
        **args,
    ):
        return _do_attach(program, pid, target, core)
