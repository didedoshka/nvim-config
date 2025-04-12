return
{
    'stevearc/oil.nvim',
    opts = {},
    -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
    lazy = false,
    config = function ()
        require("oil").setup()
        vim.keymap.set("n", "<leader>w", "<cmd>Oil<cr>",
            { desc = "(w)orking file tree" }
        )

        -- tree for project directory. <leader> project
        vim.keymap.set("n", "<leader>p", "<cmd>Oil " .. vim.fn.getcwd() .. "<cr>",
            { desc = "(p)roject tree" }
        )
    end
}
