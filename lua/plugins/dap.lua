return
{
    "MironPascalCaseFan/debugmaster.nvim",
    dependencies = { "mfussenegger/nvim-dap", },
    config = function()
        local dm = require("debugmaster")
        local dap = require("dap")
        local brd = require("brd")

        local state = require("debugmaster.state")
        state.sidepanel.float = true
        -- state.sidepanel.direction = "below"

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

        vim.keymap.set({ "n", "v" }, "<leader>i", "<cmd>BrdConfig<cr>",
            { desc = "BrdConfig" })

        dap.adapters["codelldb"] = {
            type = "executable",
            command = "codelldb",
        }

        brd.dap_configurations["cpp"] = {
            name = "cpp",
            type = "codelldb",
            request = "launch",
            program = function()
                return coroutine.create(function(dap_run_co)
                    coroutine.resume(dap_run_co, brd.get_debug_executable())
                end)
            end,
            cwd = function()
                return coroutine.create(function(dap_run_co)
                    coroutine.resume(dap_run_co, brd.get_directory())
                end)
            end,
            stopOnEntry = false,
            stdio = { "../input.txt", nil, nil }
        }

        dap.configurations["cpp"] = { brd.dap_configurations["cpp"] }

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
