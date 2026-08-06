return {
    dir = vim.fn.expand("~/personal/no-tmux.nvim"),
    config = function()
        require("nv").setup()
    end,
}
