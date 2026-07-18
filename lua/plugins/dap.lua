return
{
    -- fork of MironPascalCaseFan/debugmaster.nvim, local checkout
    dir = vim.fn.expand("~/personal/debugmaster.nvim"),
    dependencies = { "mfussenegger/nvim-dap", },
    config = function()
        local dm = require("debugmaster")
        local dap = require("dap")

        -- Must precede the debugmaster.state require below: loading state
        -- builds the help panel, which resolves the scheme and freezes it.
        dm.cfg.keymaps = "gdb"

        local state = require("debugmaster.state")
        state.sidepanel.float = true
        -- state.sidepanel.direction = "below"

        dm.plugins.ui_auto_toggle.enabled = false
        dm.plugins.last_config_rerunner.enabled = false

        vim.keymap.set("n", "<bs><bs>", dm.mode.toggle, { desc = "toggle (d)ebug mode" })
        vim.keymap.set("n", "<Esc>", dm.mode.disable, { desc = "leave debug mode" })
        -- <bs>{key} fires one debug command without entering the mode.
        dm.keys.oneshot("<bs>")

        vim.fn.sign_define('DapBreakpoint',
            { text = '', texthl = 'DapBreakpoint', linehl = 'DapBreakpointLine', numhl = 'DapBreakpoint' })
        vim.fn.sign_define('DapBreakpointCondition',
            { text = 'ﳁ', texthl = 'DapBreakpoint', linehl = 'DapBreakpointLine', numhl = 'DapBreakpoint' })
        vim.fn.sign_define('DapBreakpointRejected',
            { text = '', texthl = 'DapBreakpoint', linehl = 'DapBreakpointLine', numhl = 'DapBreakpoint' })
        vim.fn.sign_define('DapLogPoint',
            { text = '', texthl = 'DapLogPoint', linehl = 'DapLogPoint', numhl = 'DapLogPoint' })
        vim.fn.sign_define('DapStopped',
            { text = '󰁔', texthl = 'DapStopped', linehl = 'DapStoppedLine', numhl = 'DapStopped' })

        -- gdb >= 14 speaks DAP itself, so no separate adapter binary is needed.
        -- `ya gdb` cannot be that gdb: its patched 17.1 build segfaults as soon
        -- as a DAP session runs the inferior (measured with a plain launch, no
        -- core, arcadia printers disabled -- so it is the build, not the
        -- python). The system gdb works, and ya gdb's pretty-printers are plain
        -- python that loads into it, so drive the former and source the latter.
        local printers = nil -- false once resolved and absent

        local function arc_printers()
            local out = vim.fn.system({ "ya", "gdb", "--print-path" })
            if vim.v.shell_error ~= 0 then
                return false
            end
            -- <tool>/bin/gdb -> <tool>/share/gdb/python/arc/__init__.py
            local py = vim.fn.fnamemodify(vim.trim(out), ":h:h") .. "/share/gdb/python/arc/__init__.py"
            return vim.uv.fs_stat(py) and py or false
        end

        dap.adapters["gdb"] = function(callback, _)
            if printers == nil then
                printers = arc_printers()
            end
            -- ~/.config/gdb/gdbinit turns per-command timing on, which under
            -- DAP becomes a flood of output events in the console.
            local args = { "-q", "-ex", "maint set per-command time off" }
            if printers then
                vim.list_extend(args, { "-ex", "source " .. printers })
            end
            -- Upstream DAP attach takes only pid/target; this adds `core`.
            vim.list_extend(args, { "-ex", "source " .. vim.fn.stdpath("config") .. "/gdb/dap_core.py" })
            vim.list_extend(args, { "--interpreter=dap" })
            callback({ type = "executable", command = "gdb", args = args })
        end

        local function ask(label, default, kind)
            return function()
                return vim.fn.input(label, default or "", kind)
            end
        end

        -- brd used to answer "which binary" from a .brd.lua target; until its
        -- replacement lands, ask.
        dap.configurations["cpp"] = {
            {
                name = "gdb: launch binary",
                type = "gdb",
                request = "launch",
                program = ask("Binary: ", vim.fn.getcwd() .. "/", "file"),
                cwd = "${workspaceFolder}",
            },
            {
                name = "gdb: open core",
                type = "gdb",
                request = "attach",
                program = ask("Binary: ", vim.fn.getcwd() .. "/", "file"),
                core = ask("Core: ", vim.fn.getcwd() .. "/", "file"),
            },
            {
                name = "gdb: attach pid",
                type = "gdb",
                request = "attach",
                pid = function()
                    return tonumber(vim.fn.input("PID: "))
                end,
            },
        }
        dap.configurations["c"] = dap.configurations["cpp"]
    end
}
