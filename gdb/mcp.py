"""Expose this gdb to Claude Code over MCP while nvim-dap drives it.

Sourced by the adapter in lua/plugins/dap.lua, so every DAP session serves
one tool, `gdb-command`, on 127.0.0.1:3333 (SSE). Claude Code reaches it via
`claude mcp add --transport sse gdb http://127.0.0.1:3333/sse`. Commands run
through gdb.post_event, i.e. on gdb's main thread, interleaved with the DAP
requests -- a `next` issued from here produces the same stop event nvim-dap
listens for, so the editor follows (measured: sign and frame line move).

Derived from jtang613/gdb-mcp (MIT), with its fastmcp 1.x fallbacks dropped
and the FastMCP 2.x constructor. fastmcp lives in its own venv, gdb's python
being the system one (PEP 668): gdb/mcp-venv.sh builds it.

One fixed port means one session at a time: a second gdb finds the port busy
and just says so -- the first session keeps serving.
"""

import os
import socket
import sys
import threading

import gdb

HOST, PORT = "127.0.0.1", 3333
VENV = os.path.expanduser("~/.local/share/gdb-mcp/venv")
SITE = os.path.join(
    VENV, "lib", "python%d.%d" % sys.version_info[:2], "site-packages")


def run_gdb_command(command: str) -> str:
    """Run one gdb CLI command on gdb's main thread, return its output."""
    done = threading.Event()
    result = {}

    def on_main_thread():
        try:
            result["out"] = gdb.execute(command, to_string=True)
        except Exception as ex:  # any gdb error reads better than a stack
            result["out"] = "ERROR: %s: %s" % (type(ex).__name__, ex)
        done.set()

    gdb.post_event(on_main_thread)
    done.wait()
    return result["out"]


def serve():
    try:
        import fastmcp
    except ImportError as ex:
        gdb.write("[mcp] fastmcp missing (%s); run gdb/mcp-venv.sh\n" % ex)
        return
    with socket.socket() as probe:
        if probe.connect_ex((HOST, PORT)) == 0:
            gdb.write("[mcp] %s:%d busy, another session serves\n" % (HOST, PORT))
            return
    app = fastmcp.FastMCP(name="gdb")
    app.tool(name="gdb-command",
             description="Run one gdb CLI command in the live session")(run_gdb_command)

    def thread():
        app.run(transport="sse", host=HOST, port=PORT,
                show_banner=False, log_level="warning")

    threading.Thread(target=thread, name="gdb-mcp", daemon=True).start()
    gdb.write("[mcp] serving on %s:%d\n" % (HOST, PORT))


if os.path.isdir(SITE):
    sys.path.insert(0, SITE)
serve()
