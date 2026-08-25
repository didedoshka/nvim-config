return
{
    'stevearc/oil.nvim',
    -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
    config = function ()
        require("oil").setup()
        vim.keymap.set("n", "<leader>w", "<cmd>Oil<cr>",
            { desc = "(w)orking file tree" }
        )
    end
}
