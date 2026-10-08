"""stepIn chains (dap_step.py) that reach the unwinder, on unittester-formats.

Starts at library/cpp/yt/error/error-inl.h:621, just before a throw; stepIn
should give the throw stop within a second (dap_exception's fast path), then
the cleanups. `baseline` leaves dap_exception.py out, for comparison.

    MOUNT=~/a/<mount> python3 ~/.config/nvim/tests/dap_exception_live/chain.py [baseline]
"""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dap_client import Dap, FILES

ROOT = os.environ.get("MOUNT", "/home/dagorokhov/a/28130_11_ndebug")
BIN = ROOT + "/yt/yt/library/formats/unittests/unittester-formats"
SRC = ROOT + "/library/cpp/yt/error/error-inl.h"
FILTER = "--gtest_filter=Variants/TYsonSkiffConverterTestVariant.TestMalformedVariants/0"
files = FILES if "baseline" not in sys.argv else tuple(f for f in FILES if f != "dap_exception.py")
limit = 25
dap = Dap(ROOT, files)
try:
    stop = dap.launch(BIN, [FILTER], {SRC: [621]})
    t = stop["body"]["threadId"]
    print("  start:", dap.top(t)[0]["line"])
    seen_throw = False
    for i in range(limit):
        r = dap.step("stepIn", t, timeout=300)
        print("  stepIn %2d -> %s %-40s %-28s %6.2fs" % (i, r.get("reason"), r.get("where"), r.get("name", "")[:28], r.get("elapsed")))
        if "thread" not in r:
            break
        t = r["thread"]
        if r.get("where", "").startswith("skiff_yson_converter_ut.cpp:69"):
            break
finally:
    dap.close()
