return {
  "numtostr/comment.nvim",
  config = function()
    -- require("comment").setup()
    require("Comment").setup()

    vim.keymap.set("n", "<leader>/",
      function()
        require("Comment.api").toggle.linewise.current()
      end
    )
    vim.keymap.set("x", "<leader>/",
      "<ESC><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>"

    -- don't know why the code above works, while the one above fails. above's copyed from NvChad

    -- function()
    --   require('Comment.api').toggle.linewise(vim.fn.visualmode())
    -- end
    )
  end,
}
