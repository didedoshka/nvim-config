return
{
    "preservim/nerdtree",
    config = function()
        vim.keymap.set("n", "<leader>w",
            function()
                local path_with_file_name = vim.api.nvim_buf_get_name(0)
                local path = path_with_file_name:match(".*/")
                vim.cmd("edit " .. path)
                vim.cmd("5")
            end,
            { desc = "(w)orking file tree" }
        )

        -- tree for project directory. <leader> project
        vim.keymap.set("n", "<leader>p",
            function()
                vim.cmd("edit .")
                vim.cmd("5")
            end,
            { desc = "(p)roject tree" }
        )
    end
}
