return {
    "numtostr/comment.nvim",
    config = function()
        -- require("comment").setup()
        require("Comment").setup()

        vim.keymap.set("n", "<leader>/",
            function()
                require("Comment.api").toggle.linewise.current()
            end,
            { desc = "toggle comment" }
        )

        vim.keymap.set("x", "<leader>/",
            "<ESC><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>",
            { desc = "toggle visual block comment" }
        )
    end,
}
