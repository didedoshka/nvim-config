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

        dap.adapters["codelldb"] = {
            type = "executable",
            command = "codelldb",
        }

        -- brd used to answer "which binary" from a .brd.lua target; until its
        -- replacement lands, ask.
        dap.configurations["cpp"] = {
            {
                name = "cpp",
                type = "codelldb",
                request = "launch",
                program = function()
                    return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
                end,
                cwd = '${workspaceFolder}',
                stopOnEntry = false,
            },
        }
    end
}
