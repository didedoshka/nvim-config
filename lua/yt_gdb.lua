local M = {}

-- Driven over RPC by yt's gdb_helpers.attach_gdb(nvim=True). The test process
-- has frozen itself on a barrier file and handed us its pid; attach, let
-- nvim-dap install the breakpoints already set in the editor, then release the
-- barrier so the test runs into them.
--
-- configurationDone is the release point: Session:event_initialized sends the
-- breakpoints and only then issues configurationDone, so by the time its
-- response lands every breakpoint is in place.
function M.attach(pid, barrier)
    local dap = require("dap")

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
        -- Attaching left the process stopped; the test only proceeds once it runs.
        dap.continue()
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
