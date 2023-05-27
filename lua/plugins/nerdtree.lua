return
{
  "preservim/nerdtree",
  config = function()
    -- ".*/"
    vim.keymap.set("n", "<leader>te",
      function()
        local path_with_file_name = vim.api.nvim_buf_get_name(0)
        local path = path_with_file_name:match(".*/")
        vim.cmd("edit " .. path)
        vim.cmd("5")
      end
    )
    vim.keymap.set("n", "<leader>tp",
      function()
        vim.cmd("edit .")
        vim.cmd("5")
      end
    )
  end
}
