local M = {}

-- Driven over RPC by yt's gdb_helpers.attach_gdb, wired in through
-- $YT_GDB_ATTACH_COMMAND. The test process has frozen itself on a barrier file
-- and handed us its pid; attach, let nvim-dap install the breakpoints already
-- set in the editor, then release the barrier so the test runs into them.
--
-- Two hooks, because the barrier and the inferior come free at different points.
--
-- The barrier goes at configurationDone: Session:event_initialized sends the
-- breakpoints and only then issues configurationDone, so by the time its
-- response lands every breakpoint is in place.
--
-- The inferior goes one round-trip after its stop event -- gdb froze it to
-- attach and nothing else will ever resume it, but the stop event itself is too
-- early to act on. nvim-dap answers `stopped` with an async `threads` request
-- and records stopped_thread_id only once that returns, so from the stop
-- listener dap.continue() sees nothing stopped and offers its "Session active,
-- but not stopped at breakpoint" menu -- while requesting the continue directly
-- instead lets that bookkeeping land *after* the process is already running,
-- leaving a thread nvim-dap believes is stopped forever. The cost of that is
-- silent and awful: the real breakpoint hits on a different thread, nvim-dap
-- reads it as a second thread stopping while the first still is, and
-- auto_continue_if_many_stopped resumes straight past it.
--
-- `after.threads` is the settled point: stopped_thread_id is set by then, so
-- dap.continue() both works and clears the state on its way out.
function M.attach(pid, barrier)
    local dap = require("dap")

    dap.listeners.after.threads["yt_gdb"] = function(session)
        -- Threads get listed while running too; the attach stop is the one that
        -- leaves a stopped thread behind it. One-shot -- every later stop is a
        -- breakpoint the user means to sit on.
        if not session.stopped_thread_id then
            return
        end
        dap.listeners.after.threads["yt_gdb"] = nil
        dap.continue()
    end

    dap.listeners.after.configurationDone["yt_gdb"] = function()
        dap.listeners.after.configurationDone["yt_gdb"] = nil
        if barrier and barrier ~= "" then
            local f, err = io.open(barrier, "w")
            if not f then
                vim.notify("yt_gdb: cannot touch barrier: " .. tostring(err), vim.log.levels.ERROR)
                return
            end
            f:close()
        end
    end

    dap.run({
        name = "yt: attach test",
        type = "gdb",
        request = "attach",
        pid = pid,
    })
    return 0
end

return M
