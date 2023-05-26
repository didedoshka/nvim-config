return {
	"nvim-lualine/lualine.nvim",
	config = function()
		require('lualine').setup({
			options = {
        theme = 'ayu',
        icons_enabled = false,
        globalstatus = true,
        component_separators = '|',
        section_separators = '',
			},
			sections = {
				lualine_a = {'mode'},
				lualine_b = {'branch', 'diff', 'diagnostics'},
				lualine_c = {'filename'},
				lualine_x = {},
				lualine_y = {'encoding'},
				lualine_z = {}
			},
		})
	end,
	dependencies = {
		"nvim-tree/nvim-web-devicons"
	}
}
