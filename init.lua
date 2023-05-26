-- Created by didedoshka May 24, 11:28 PM


-- require("check")

-- setting leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- setting indentation
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2

-- setting number
vim.opt.number = true
vim.opt.relativenumber = true

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
		-- {
		-- 	"nvim-tree/nvim-tree.lua",
		-- 	config = function()
		-- 		require("nvim-tree").setup()
		-- 	end
		-- },

		-- statusline
		require("plugins.lualine")
	}
	

)


