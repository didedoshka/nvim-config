return
{
    "kdheepak/lazygit.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
    },

    config = function()
        vim.keymap.set("n", "<leader>lg",
            function()
                vim.cmd("LazyGit")
            end)
    end

}
