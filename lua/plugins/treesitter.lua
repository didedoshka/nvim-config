return
{
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
        vim.api.nvim_create_autocmd('FileType', {
            callback = function(args)
                pcall(vim.treesitter.start)
                -- vim.bo[args.buf].indentexpr = 'v:lua.require"nvim-treesitter".indentexpr()'
            end,
        })
    end
}
