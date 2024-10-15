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
if vim.g.vscode then
    vim.keymap.set('n', 'K', function()
        require('vscode').call('editor.action.showHover')
    end)

    vim.keymap.set('n', 'gd', function()
        require('vscode').call('editor.action.revealDefinition')
    end)

    vim.keymap.set('n', 'gi', function()
        require('vscode').call('editor.action.goToImplementation')
    end)

    vim.keymap.set('n', 'gr', function()
        require('vscode').call('editor.action.goToReferences')
    end)

    vim.keymap.set('n', 'gD', function()
        require('vscode').call('editor.action.revealDeclaration')
    end)

    vim.keymap.set('n', '[x', function()
        require('vscode').call('merge-conflict.previous')
    end)

    vim.keymap.set('n', ']x', function()
        require('vscode').call('merge-conflict.next')
    end)

    table_of_plugins = {
        -- flit
        require("plugins.flit"),
    }
else
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
        pattern = { "*.py", "*.cpp", "*.h" },
        command = "silent update"
    })
    table_of_plugins = {
        -- colorscheme
        require("plugins.ayu"),
        -- require("plugins.catppuccin"),

        {
            "Yggdroot/indentLine"
        },

        -- flit
        require("plugins.flit"),

        -- telescope
        require("plugins.telescope"),

        -- filetree
        require("plugins.nerdtree"),

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

        { "ray-x/lsp_signature.nvim" },
    }
end

-- setting plugins
require("lazy").setup(
    table_of_plugins
)
