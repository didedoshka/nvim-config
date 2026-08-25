#!/usr/bin/env bash
# Semi-live check of gdb/mcp.py: a real nvim (this config) in a tmux pane runs a
# DAP session on a small C++ program, and an MCP client talks to the gdb behind
# it. Asserts both directions: what the client reads matches the program, and
# a `next` sent over MCP moves nvim's frame. Needs gdb >= 14, clang++, tmux, and
# the venv from gdb/mcp-venv.sh. Not part of run.sh (~15s, real processes).
#
#   tests/mcp_live.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV="$HOME/.local/share/gdb-mcp/venv"
SESSION="nvim-mcp-test-$$"
# Unix socket paths cap at ~107 chars, so not under a deep tmp dir.
SOCK="$HOME/.cache/nvim-mcp-test-$$.sock"
TMP="$(mktemp -d)"
STATUS=0

cleanup() {
    tmux kill-session -t "$SESSION" 2>/dev/null
    rm -rf "$TMP" "$SOCK"
}
trap cleanup EXIT

fail() {
    STATUS=1
    printf '  FAIL  %s\n' "$1"
}

for tool in gdb clang++ tmux; do
    command -v "$tool" >/dev/null || { echo "mcp_live: SKIPPED ($tool not on PATH)"; exit 0; }
done
[[ -x "$VENV/bin/python" ]] || { echo "mcp_live: SKIPPED (no venv; run gdb/mcp-venv.sh)"; exit 0; }

# --- program under test ------------------------------------------------------
cat > "$TMP/main.cpp" <<'CPP'
#include <vector>

long total(const std::vector<long>& values) {
    long sum = 0;
    for (long v : values) {
        sum += v;          // line 6: breakpoint
    }
    return sum;
}

int main() {
    std::vector<long> values = {100, 250, -30};
    return total(values) == 320 ? 0 : 1;
}
CPP
clang++ -g -O0 -o "$TMP/main" "$TMP/main.cpp" || { fail "clang++"; exit 1; }

# --- nvim in a pty, driven over RPC ----------------------------------------
# env -u NVIM: from a terminal inside nvim, flatten.nvim would hand this
# instance to the host and the socket would never appear.
tmux new-session -d -s "$SESSION" -x 120 -y 40 \
    "cd '$TMP' && env -u NVIM -u NVIM_LISTEN_ADDRESS nvim --listen '$SOCK' main.cpp"
for _ in $(seq 1 50); do [[ -S "$SOCK" ]] && break; sleep 0.2; done
[[ -S "$SOCK" ]] || { fail "nvim socket never appeared"; exit 1; }

expr() { nvim --server "$SOCK" --remote-expr "luaeval(\"$1\")"; }

expr "vim.api.nvim_win_set_cursor(0, {6, 0}) and '' or require('dap').set_breakpoint() or 'bp'" >/dev/null
expr "require('dap').run({ name = 'mcp_live', type = 'gdb', request = 'launch', program = '$TMP/main', cwd = '$TMP' }) or 'run'" >/dev/null

# Wait for the stop at the breakpoint; the arc printers in gdbinit make the
# adapter slow to initialise.
line=""
for _ in $(seq 1 100); do
    line="$(expr "(function() local s = require('dap').session(); return s and s.current_frame and tostring(s.current_frame.line) or '' end)()")"
    [[ "$line" == "6" ]] && break
    sleep 0.2
done
[[ "$line" == "6" ]] || fail "nvim-dap did not stop at line 6 (got '$line')"

# --- the MCP side ------------------------------------------------------------
cat > "$TMP/client.py" <<'PY'
import asyncio, sys
from fastmcp import Client

async def main():
    async with Client("http://127.0.0.1:3333/sse") as c:
        for cmd in sys.argv[1:]:
            r = await c.call_tool("gdb-command", {"command": cmd})
            print(r.content[0].text.rstrip())
            print("--")

try:
    asyncio.run(main())
except Exception as ex:  # one line, not fastmcp's 40-frame traceback
    sys.exit("client: %s: %s" % (type(ex).__name__, str(ex).strip().splitlines()[-1]))
PY
if out="$("$VENV/bin/python" "$TMP/client.py" "bt 1" "p values" 2>&1)"; then
    grep -q "total (values=" <<<"$out" || fail "bt over MCP does not show total(): $out"
    grep -q "100, 250, -30" <<<"$out" || fail "p values over MCP: $out"
else
    fail "MCP client: $out"
fi

# Two nexts: `sum += v` -> loop header -> `sum += v` again, sum == 100.
if out="$("$VENV/bin/python" "$TMP/client.py" "next" "next" "p sum" 2>&1)"; then
    grep -q '= 100$' <<<"$out" || fail "p sum after two nexts: $out"
else
    fail "MCP next: $out"
fi
sleep 0.5
line="$(expr "tostring(require('dap').session().current_frame.line)")"
[[ "$line" == "6" ]] || fail "nvim frame after MCP nexts: expected 6, got '$line'"
tmux capture-pane -pt "$SESSION" | grep -q '→ *6 ' || fail "DapStopped sign is not on line 6 in the pane"

# The busy-port branch: a second gdb must decline, not crash.
out="$(gdb -q -batch -ex 'maint set per-command time off' -ex "source $ROOT/gdb/mcp.py" 2>&1 | grep '^\[mcp\]')"
[[ "$out" == *"busy"* ]] || fail "second gdb on the same port: $out"

# Tear down through gdb, then check nvim-dap noticed.
"$VENV/bin/python" "$TMP/client.py" "delete" "continue" >/dev/null 2>&1
for _ in $(seq 1 25); do
    [[ "$(expr "tostring(require('dap').session())")" == "nil" ]] && break
    sleep 0.2
done
[[ "$(expr "tostring(require('dap').session())")" == "nil" ]] || fail "session still alive after continue to exit"

if [[ $STATUS -eq 0 ]]; then echo "mcp_live: passed"; fi
exit $STATUS
