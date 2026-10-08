"""Exception stepping on the original repro, unittester-formats.

Needs yt/yt/library/formats/unittests built in $MOUNT (an arc mount, default
28130_11_ndebug). Prints where each DAP request stops; the scenario titles say
what to expect. Arguments pick scenarios: next, stepout, stepin.

    MOUNT=~/a/<mount> python3 ~/.config/nvim/tests/dap_exception_live/formats.py
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dap_client import Dap  # noqa: E402

ROOT = os.environ.get("MOUNT", "/home/dagorokhov/a/28130_11_ndebug")
BIN = ROOT + "/yt/yt/library/formats/unittests/unittester-formats"
UT = ROOT + "/yt/yt/library/formats/unittests/skiff_yson_converter_ut.cpp"
FILTER = "--gtest_filter=Variants/TYsonSkiffConverterTestVariant.TestMalformedVariants/0"


def scenario(title, commands):
    print("=== " + title)
    dap = Dap(ROOT)
    try:
        stop = dap.launch(BIN, [FILTER], {UT: [65]})
        thread = stop["body"]["threadId"]
        print("  start:", dap.top(thread)[0]["line"])
        for command in commands:
            r = dap.step(command, thread)
            print("  %-8s -> %s" % (command, r))
            if "thread" in r:
                thread = r["thread"]
            else:
                break
    finally:
        dap.close()


which = sys.argv[1:] or ["next", "stepout", "stepin"]
if "next" in which:
    scenario("next through the whole unwinding", ["next"] * 9)
if "stepout" in which:
    scenario("stepOut from the throw goes to the catch", ["next", "stepOut", "next"])
if "stepin" in which:
    scenario("stepIn chain: into the functor, then on", ["stepIn"] * 8)
