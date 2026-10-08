GTEST(unittester-gdb-exception-fibers)

INCLUDE(${ARCADIA_ROOT}/yt/ya_cpp.make.inc)

SRCS(
    fibers_ut.cpp
)

PEERDIR(
    yt/yt/core
    yt/yt/core/test_framework
)

SIZE(SMALL)

END()
