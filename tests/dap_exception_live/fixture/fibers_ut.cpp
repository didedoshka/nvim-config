// Fixture for ~/.config/nvim/gdb/dap_exception.py: exceptions and YT fibers.

#include <yt/yt/core/test_framework/framework.h>

#include <yt/yt/core/actions/bind.h>
#include <yt/yt/core/actions/future.h>
#include <yt/yt/core/concurrency/action_queue.h>
#include <yt/yt/core/concurrency/scheduler_api.h>

namespace NYT {
namespace {

using namespace NConcurrency;

////////////////////////////////////////////////////////////////////////////////

[[gnu::noinline]] void Throw(const char* message)
{
    THROW_ERROR_EXCEPTION("%v", message); // THROW_SITE
}

[[gnu::noinline]] void ThrowAndCatch()
{
    try {
        Throw("caught inside the sibling");
    } catch (const std::exception&) {
    }
}

//! F1: a sibling fiber on the same thread throws and catches while we wait.
[[gnu::noinline]] void WaitForSiblingThatCatches()
{
    auto sibling = BIND(&ThrowAndCatch).AsyncVia(GetCurrentInvoker()).Run();
    WaitFor(sibling).ThrowOnError(); // F1_NEXT
    int afterF1 = 1; // F1_AFTER
    Y_UNUSED(afterF1);
}

//! F2: a sibling fiber throws and does not catch: the error lands in its future.
[[gnu::noinline]] void WaitForSiblingThatFails()
{
    auto sibling = BIND([] { Throw("escapes the sibling"); }).AsyncVia(GetCurrentInvoker()).Run();
    auto result = WaitFor(sibling); // F2_NEXT
    int afterF2 = result.IsOK(); // F2_AFTER
    Y_UNUSED(afterF2);
}

//! F3: the stepped fiber yields, then throws.
[[gnu::noinline]] void YieldThenThrow()
{
    Yield();
    Throw("after yield");
}

//! F4: the stepped fiber moves to another thread, then throws.
[[gnu::noinline]] void SwitchThenThrow(IInvokerPtr other)
{
    SwitchTo(std::move(other));
    Throw("after switch");
}

//! F5: no exception, the fiber just moves to another thread.
[[gnu::noinline]] void SwitchOnly(IInvokerPtr other)
{
    SwitchTo(std::move(other)); // F5_NEXT
    int afterF5 = 1; // F5_AFTER
    Y_UNUSED(afterF5);
}

TEST(TGdbExceptionFibers, Scenarios)
{
    auto first = New<TActionQueue>("First");
    auto second = New<TActionQueue>("Second");
    // Not inside BIND(...): clang gives code in a macro invocation the line of
    // the invocation, so breakpoints in the body would slide past it.
    auto body = [&] {
        WaitForSiblingThatCatches();
        WaitForSiblingThatFails();
        try {
            YieldThenThrow(); // F3_NEXT
        } catch (const std::exception&) {
            int caughtF3 = 1; // F3_CATCH
            Y_UNUSED(caughtF3);
        }
        try {
            SwitchThenThrow(second->GetInvoker()); // F4_NEXT
        } catch (const std::exception&) {
            int caughtF4 = 1; // F4_CATCH
            Y_UNUSED(caughtF4);
        }
        SwitchOnly(first->GetInvoker());
        int end = 1; // END
        Y_UNUSED(end);
    };
    BIND(body)
        .AsyncVia(first->GetInvoker())
        .Run()
        .BlockingGet()
        .ThrowOnError();
}

////////////////////////////////////////////////////////////////////////////////

} // namespace
} // namespace NYT
