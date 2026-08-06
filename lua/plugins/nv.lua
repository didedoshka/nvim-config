return {
    dir = vim.fn.expand("~/personal/nv.nvim"),
    config = function()
        require("nv").setup()
    end,
}
