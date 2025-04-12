return
{
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    config = function()
        local dap = require('dap')
        dap.adapters.codelldb = {
            type = "executable",
            command = "/Users/didedoshka/.vscode/extensions/vadimcn.vscode-lldb-1.11.2/adapter/codelldb",     -- or if not in $PATH: "/absolute/path/to/codelldb"

            -- On windows you may have to uncomment this:
            -- detached = false,
        }
        dap.configurations.cpp = {
            {
                name = "Launch file",
                type = "codelldb",
                request = "launch",
                program = function()
                    return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
                end,
                cwd = '${workspaceFolder}',
                stopOnEntry = false,
            },
        }
        require("dapui").setup()
    end,
}
