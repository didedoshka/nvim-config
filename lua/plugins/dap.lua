return
{
    "miroshQa/debugmaster.nvim",
    dependencies = { "mfussenegger/nvim-dap", },
    config = function()
        local dm = require("debugmaster")
        local dap = require("dap")
        local brd = require("brd")

        local state = require("debugmaster.state")
        state.sidepanel.float = true

        dm.plugins.ui_auto_toggle.enabled = false
        dm.plugins.last_config_rerunner.enabled = false

        brd.setup({ debugmaster = true })

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

        -- vim.print(require("debugmaster.state"))

        vim.keymap.set("n", "<bs><bs>", dm.mode.toggle)
        vim.keymap.set("n", "<Esc>", dm.mode.disable)

        vim.keymap.set("n", "<bs>u", function()
            state.sidepanel:toggle()
        end)

        vim.keymap.set("n", "<bs>J", brd.build)
        vim.keymap.set("n", "<bs>X", brd.run)
        vim.keymap.set("n", "<bs>P", brd.debug)
        vim.keymap.set("n", "<bs>x", brd.build_and_run)
        vim.keymap.set("n", "<bs>p", brd.build_and_debug)
        vim.keymap.set("n", "<bs>s", brd.choose_target)
        vim.keymap.set("n", "<bs>C", brd.term.open_terminal)

        -- vim.keymap.set({ "n", "v" }, "<leader>u", "<cmd>BrdConfig<cr>")

        dap.adapters["codelldb"] = {
            type = "executable",
            command = "/Users/didedoshka/.vscode/extensions/vadimcn.vscode-lldb-1.11.5/adapter/codelldb",
        }

        brd.dap_configurations["cpp"] = {
            name = "cpp",
            type = "codelldb",
            request = "launch",
            program = brd.get_debug_executable,
            cwd = brd.get_dir,
            stopOnEntry = false,
        }

        -- dap.configurations["cpp"] = {
        --     {
        --         name = "cpp",
        --         type = "codelldb",
        --         request = "launch",
        --         program = function()
        --             return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        --         end,
        --         cwd = '${workspaceFolder}',
        --         stopOnEntry = false,
        --     },
        -- }
    end
}
