return
{
	"preservim/nerdtree",
	config = function()
		-- ".*/"
		vim.keymap.set("n", "<leader>e", 
		function() 
			local path_with_file_name = vim.api.nvim_buf_get_name(0)
			local path = path_with_file_name:match(".*/")
			-- print(path)
			vim.cmd("edit " .. path)
			vim.cmd("5")
		end
		) 
	end	
}
