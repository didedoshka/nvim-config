-- Created by didedoshka May 24, 11:28 PM


-- require("check")

-- setting leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- setting indentation
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

-- setting number
vim.opt.number = true
vim.opt.relativenumber = true

-- command line only visible in command mode
-- vim.opt.cmdheight = 0

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

-- setting plugins
require("lazy").setup(
  -- table of plugins
  {
    -- colorscheme
    require("plugins.ayu"),

    -- filetree
    require("plugins.nerdtree"),

    -- statusline
    -- require("plugins.lualine")

    -- lspconfig
    require("plugins.lspconfig"),

    -- treesitter
    require("plugins.treesitter"),

    -- telescope
    require("plugins.telescope"),

    -- flit
    require("plugins.flit"),

    -- coq (autocompletion)
    require("plugins.coq")
  }

)


