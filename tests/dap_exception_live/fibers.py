"""Exception stepping across YT fibers.

Needs the fixture built in $MOUNT: copy fixture/ to
$MOUNT/junk/dagorokhov/gdb_exception_fibers and `ya make` it there. `baseline`
leaves dap_exception.py out, for comparison.

    MOUNT=~/a/<mount> python3 ~/.config/nvim/tests/dap_exception_live/fibers.py [baseline]
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dap_client import Dap, FILES  # noqa: E402

ROOT = os.environ.get("MOUNT", "/home/dagorokhov/a/28130_11_ndebug")
DIR = ROOT + "/junk/dagorokhov/gdb_exception_fibers"
BIN = DIR + "/unittester-gdb-exception-fibers"
SRC = DIR + "/fibers_ut.cpp"
F1_NEXT, F2_NEXT, F5_NEXT, F3_NEXT, F4_NEXT, END = 34, 43, 65, 80, 86, 92

files = FILES if "baseline" not in sys.argv else tuple(f for f in FILES if f != "dap_exception.py")


def show(label, r):
    if "thread" not in r:
        print("  %-22s -> %s" % (label, r))
        return
    print("  %-22s -> %-9s thread %s  %-22s %-40s %5.2fs" % (
        label, r["reason"], r["thread"], r["where"], r["name"][:40], r["elapsed"]))


def walk(dap, thread, until_line, limit=10):
    for i in range(limit):
        r = dap.step("next", thread)
        show("  next", r)
        if "thread" not in r:
            return None
        thread = r["thread"]
        if r["where"].endswith(":%d" % until_line):
            break
    return thread


dap = Dap(ROOT, files)
try:
    stop = dap.launch(BIN, [], {SRC: [F1_NEXT, F2_NEXT, F5_NEXT, F3_NEXT, F4_NEXT, END]})
    t = stop["body"]["threadId"]
    print("  start at", dap.top(t)[0]["line"], "thread", t)

    print("F1: next over WaitFor, the sibling fiber throws and catches (expect 35)")
    r = dap.step("next", t); show("next", r); t = r.get("thread", t)

    r = dap.step("continue", t); show("continue", r); t = r.get("thread", t)
    print("F2: next over WaitFor, the sibling's exception escapes it (expect 44)")
    r = dap.step("next", t); show("next", r); t = r.get("thread", t)

    r = dap.step("continue", t); show("continue", r); t = r.get("thread", t)
    print("F3: next over Yield-then-throw (expect exception at 19, then catch at 82)")
    t = walk(dap, t, 82)

    r = dap.step("continue", t); show("continue", r); t = r.get("thread", t)
    print("F4: next over SwitchTo-then-throw (expect exception at 19 on the other thread, then 88)")
    t = walk(dap, t, 88)

    r = dap.step("continue", t); show("continue", r); t = r.get("thread", t)
    print("F5: next over SwitchTo alone (gdb itself; expect 66)")
    try:
        r = dap.step("next", t, timeout=60); show("next", r)
    except Exception:
        print("  next                   -> no stop within 60 s")
        r = dap.request("pause", {"threadId": t}); r = dap.wait_stop(len(dap.seen) - 1, 30)
        print("  pause                  ->", r.get("body", {}).get("reason"))
finally:
    dap.close()
    errors = [l for l in dap.stderr if "rror" in l or "xception" in l]
    if errors:
        print("gdb stderr:", *errors[:10], sep="\n  ")
