-- Created by didedoshka on May 24

-- function to print a table
function dump(to_dump)
    if type(to_dump) == 'table' then
        local s = '{ '
        for key, value in pairs(to_dump) do
            if type(key) ~= 'number' then key = '"' .. key .. '"' end
            s = s .. '[' .. key .. '] = ' .. dump(value) .. ','
        end
        return s .. '} '
    else
        return tostring(to_dump)
    end
end

-- set leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "
-- set indentation
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- set number
vim.opt.number = true
vim.opt.relativenumber = true

-- sync clipboard between vim and os
vim.opt.clipboard = "unnamedplus"

-- set wrap and max text width
vim.opt.wrap = false
vim.opt.colorcolumn = "120"

vim.opt.undofile = true

-- set extensions
vim.filetype.add({ extension = { ["keymap"] = "cpp" } })

-- set russian
vim.opt.keymap = "russian-yasherty"
vim.opt.iminsert = 0
vim.keymap.set('i', '<C-l>', '<C-^>', { remap = true })

-- set listchars
vim.opt.list = true
vim.opt.listchars = { tab = '>\\', eol = '¬', trail = '·' }

-- installing lazy
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

local table_of_plugins = {}
-- autocommand for wrapping in typst file
vim.api.nvim_create_autocmd("BufEnter", {
    callback = function(args)
        local bufnr = args.buf
        if vim.bo[bufnr].filetype == "typst" then
            vim.opt.wrap = true
        else
            vim.opt.wrap = false
        end
    end
})

-- autocommand for opening typst file
vim.api.nvim_create_autocmd("FileType", {
    callback = function(args)
        if args['match'] == 'typst' then
            vim.opt.iminsert = 1
            vim.keymap.set('i', '$', '$<C-l>', { remap = true, buffer = args.buf })
        end
    end
})

vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
    pattern = { "*.py", "*.cpp", "*.h", "*.c", "*.S", "*.txt", "*.lua", "*.typ" },
    command = "silent update"
})

-- working with buffers
vim.keymap.set("n", "<leader>q", "<cmd>bp<bar>sp<bar>bn<bar>bd<cr>", { desc = "close buffer" })
vim.keymap.set("n", "<Tab>", "<cmd>bnext<cr>", { desc = "next buffer" })
vim.keymap.set("n", "<S-Tab>", "<cmd>bprevious<cr>", { desc = "previous buffer" })

-- running lua
vim.keymap.set("n", "<bs>l", ":.lua<cr>", { desc = "execute current (l)ua code" })
vim.keymap.set("v", "<bs>l", ":lua<cr>", { desc = "execute current (l)ua code" })

require("keymaps_to_buffer")

-- setting plugins
require("lazy").setup(
    {
        -- colorscheme
        require("plugins.ayu"),
        -- require("plugins.catppuccin"),

        {
            "Yggdroot/indentLine",
            config = function()
                vim.g.indentLine_char = '|'
            end
        },

        -- flit
        require("plugins.flit"),

        -- telescope
        require("plugins.telescope"),

        -- file explorer
        require("plugins.oil"),

        -- cmp
        require("plugins.cmp"),

        -- treesitter
        require("plugins.treesitter"),

        -- lspconfig
        require("plugins.lspconfig"),

        {
            "jose-elias-alvarez/null-ls.nvim",
            config = function()
                require("null-ls").setup({
                    sources = require("null-ls").builtins.formatting.autopep8.with({
                        extra_args = { "-a", "-a", "--max-line-length", "119" }
                    })
                })
            end,
            dependencies = { "nvim-lua/plenary.nvim" }
        },
        -- comment
        require("plugins.comment"),

        -- lazygit
        require("plugins.lazygit"),

        { "mbbill/undotree" },

        {
            "folke/which-key.nvim",
            lazy = false,
            opts = {
                delay = 2000,
                icons = {
                    mappings = false,
                },
            },
            keys = {
                {
                    "<leader>?",
                    function()
                        require("which-key").show({ global = false })
                    end,
                    desc = "buffer-local mappings",
                },
            },
        },

        {
            "mfussenegger/nvim-dap",
            config = function()
                local dap = require('dap')
                dap.adapters.codelldb = {
                    type = "executable",
                    command = "/Users/didedoshka/.vscode/extensions/vadimcn.vscode-lldb-1.11.2/adapter/codelldb", -- or if not in $PATH: "/absolute/path/to/codelldb"

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
            end,
        },
        {
            "rcarriga/nvim-dap-ui",
            dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
            config = function()
                require("dapui").setup()
            end,
        },
    }
)
