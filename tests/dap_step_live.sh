#!/usr/bin/env bash
# Semi-live check of gdb/dap_step.py: a real nvim (this config) in a tmux pane
# runs a DAP session on a small libc++ program whose callbacks are reached
# only through skipped code -- a std::function, std::sort's comparator (libc++
# is skipped by the gdbinit globs and `-rfu ^std::`) and a template under
# contrib/libs/. Asserts where each stepIn lands as nvim-dap sees it, that each
# stepIn yields exactly one stopped event, and that `pause` ends a long chain
# inside the library. Needs gdb >= 14, clang++ with libc++, tmux. Not part of
# run.sh (~10s, real processes).
#
#   tests/dap_step_live.sh

set -uo pipefail

SESSION="nvim-dap-step-test-$$"
# Unix socket paths cap at ~107 chars, so not under a deep tmp dir.
SOCK="$HOME/.cache/nvim-dap-step-test-$$.sock"
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
    command -v "$tool" >/dev/null || { echo "dap_step_live: SKIPPED ($tool not on PATH)"; exit 0; }
done

# --- program under test ------------------------------------------------------
mkdir -p "$TMP/contrib/libs/fakelib"
cat > "$TMP/contrib/libs/fakelib/lib.h" <<'CPP'
#pragma once

template <class F>
int ApplyTwice(F f, int x)
{
    int a = f(x);
    int b = f(a);
    return b;
}

inline long SpinLong(long n)
{
    long acc = 0;
    for (long i = 0; i < n; ++i) {
        acc += i % 7;
    }
    return acc;
}
CPP
cat > "$TMP/main.cpp" <<'CPP'
#include <contrib/libs/fakelib/lib.h>

#include <algorithm>
#include <functional>
#include <memory>
#include <vector>

struct TFoo
{
    int Value = 3;
    int Get()
    {
        return Value * 2;       // line 13
    }
};

int Twice(int x)
{
    return x * 2;               // line 19
}

int main()
{
    std::function<int(int)> fn = [] (int x) {
        return x + 1;           // line 25
    };
    int r = fn(41);             // line 27: breakpoint
    r += ApplyTwice(Twice, r);
    std::vector<int> v = {3, 1, 2};
    std::sort(v.begin(), v.end(), [] (int a, int b) {
        return a < b;           // line 31
    });
    auto foo = std::make_unique<TFoo>();
    r += foo->Get();            // line 34: breakpoint
    r += SpinLong(100000000);   // line 35
    return r == 0;
}
CPP
clang++ -stdlib=libc++ -g -O0 -I"$TMP" -o "$TMP/main" "$TMP/main.cpp" || { fail "clang++"; exit 1; }

# --- nvim in a pty, driven over RPC ----------------------------------------
# env -u NVIM: from a terminal inside nvim, flatten.nvim would hand this
# instance to the host and the socket would never appear.
tmux new-session -d -s "$SESSION" -x 120 -y 40 \
    "cd '$TMP' && env -u NVIM -u NVIM_LISTEN_ADDRESS nvim --listen '$SOCK' main.cpp"
for _ in $(seq 1 50); do [[ -S "$SOCK" ]] && break; sleep 0.2; done
[[ -S "$SOCK" ]] || { fail "nvim socket never appeared"; exit 1; }

expr() { nvim --server "$SOCK" --remote-expr "luaeval(\"$1\")"; }

# T.top is the newest frame of the last stackTrace nvim-dap fetched, T.traces
# counts those fetches: a step is over once T.traces moves.
cat > "$TMP/drive.lua" <<'LUA'
local dap = require("dap")
T = { stops = 0, continued = 0, traces = 0, reason = "" }
dap.listeners.after.event_stopped["dap_step_live"] = function(_, body)
    T.stops = T.stops + 1
    T.reason = body.reason
end
dap.listeners.after.event_continued["dap_step_live"] = function()
    T.continued = T.continued + 1
end
dap.listeners.after.stackTrace["dap_step_live"] = function(_, err, body)
    if not err and body.stackFrames[1] then
        T.top = body.stackFrames[1]
        T.traces = T.traces + 1
    end
end
function T.where()
    return T.top and string.format("%s:%d", T.top.name, T.top.line) or ""
end
LUA
nvim --server "$SOCK" --remote-expr "execute('luafile $TMP/drive.lua')" >/dev/null

for line in 27 34; do
    expr "vim.api.nvim_win_set_cursor(0, {$line, 0}) and '' or require('dap').set_breakpoint() or 'bp'" >/dev/null
done
expr "require('dap').run({ name = 'dap_step_live', type = 'gdb', request = 'launch', program = '$TMP/main', cwd = '$TMP' }) or 'run'" >/dev/null

# The arc printers in gdbinit make the adapter slow to initialise.
wait_traces() {
    local want=$1 got=""
    for _ in $(seq 1 150); do
        got="$(expr "T.traces")"
        [[ "$got" -ge "$want" ]] && return 0
        sleep 0.2
    done
    return 1
}
wait_traces 1 || { fail "nvim-dap never stopped at the first breakpoint"; exit 1; }
[[ "$(expr "T.where()")" == "main:27" ]] || fail "first stop: expected main:27, got '$(expr "T.where()")'"

# step <expected frame> <what>: one stepIn, then the frame nvim-dap shows.
# An empty expected frame accepts any.
step() {
    local traces stops
    traces="$(expr "T.traces")"
    stops="$(expr "T.stops")"
    expr "require('dap').step_into() or 'step'" >/dev/null
    if ! wait_traces $((traces + 1)); then
        fail "$2: no stop after stepIn"
        return
    fi
    sleep 0.3  # a second stopped event, if any, would land by now
    local where
    where="$(expr "T.where()")"
    [[ -z "$1" || "$where" == "$1" ]] || fail "$2: expected $1, got $where"
    [[ "$(expr "T.stops")" -eq $((stops + 1)) ]] || fail "$2: $(( $(expr "T.stops") - stops )) stopped events, expected 1"
}

step "main::\$_0::operator():25" "into the lambda a std::function wraps"
step "main:28"                   "off the lambda, through std::function, back to main"
step "Twice:19"                  "into a callback of a contrib/libs template"
step "Twice:19"                  "back through the template into its second callback"
step "main:29"                   "off the last callback, back to main"
step "main:30"                   "through a vector's constructor: no callback, next line"
step "main::\$_1::operator():31" "into std::sort's comparator"
# How often std::sort compares three elements is libc++'s business; every
# stepIn must land either in the comparator again or back in main.
calls=1
for _ in $(seq 1 10); do
    [[ "$(expr "T.where()")" == "main::\$_1::operator():31" ]] || break
    step "" "off comparator call $calls"
    calls=$((calls + 1))
done
[[ "$(expr "T.where()")" == "main:33" ]] || fail "off the last comparator call: expected main:33, got $(expr "T.where()")"
[[ $calls -ge 3 ]] || fail "std::sort: stopped in the comparator $((calls - 1)) times, expected >= 2"
[[ "$(expr "T.continued")" -eq 0 ]] || fail "stepIn leaked $(expr "T.continued") continued events"

# ptr->Foo(): the skipped operator-> returns before Get() is called; plain
# gdb already stepped into Get(), this must not change that.
traces="$(expr "T.traces")"
expr "require('dap').continue() or 'c'" >/dev/null
wait_traces $((traces + 1)) || fail "continue to line 34"
step "TFoo::Get:13" "foo->Get() still steps into Get()"
step "main:35"      "off Get(), back to main"

# A long chain (SpinLong steps line by line) must stop where pause finds it.
traces="$(expr "T.traces")"
expr "require('dap').step_into() or 'step'" >/dev/null
sleep 1.5
expr "require('dap').pause(1) or 'pause'" >/dev/null
if wait_traces $((traces + 1)); then
    [[ "$(expr "T.top.name")" == "SpinLong" ]] || fail "pause during a chain: expected SpinLong, got $(expr "T.where()")"
    [[ "$(expr "T.reason")" == "pause" ]] || fail "pause during a chain: reason '$(expr "T.reason")'"
else
    fail "pause during a chain: no stop"
fi
sleep 0.3
tmux capture-pane -pt "$SESSION" | grep -q 'contrib/libs/fakelib/lib.h' || fail "nvim did not jump to lib.h after the pause"

expr "require('dap').terminate() or 'kill'" >/dev/null
for _ in $(seq 1 25); do
    [[ "$(expr "tostring(require('dap').session())")" == "nil" ]] && break
    sleep 0.2
done
[[ "$(expr "tostring(require('dap').session())")" == "nil" ]] || fail "session still alive after terminate"

if [[ $STATUS -eq 0 ]]; then echo "dap_step_live: passed"; fi
exit $STATUS
