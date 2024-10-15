return
{
    "kdheepak/lazygit.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
    },

    config = function()
        vim.keymap.set("n", "<leader>c",
            function()
                vim.cmd("LazyGit")
            end,
            { desc = "open (c)ommit window (lazygit)" })
    end

}
