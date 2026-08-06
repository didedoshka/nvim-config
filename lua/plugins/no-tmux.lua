return {
    dir = vim.fn.expand("~/personal/no-tmux.nvim"),
    config = function()
        require("nv").setup()

        -- <CR> is the server layer (the layer-key inventory in notes/ideas.md):
        -- pinned chars hop, a free char pins the current server, i searches
        vim.keymap.set("n", "<CR>", function()
            if vim.fn.exists(":FzfConnect") == 2 then
                vim.cmd.FzfConnect()
            end
        end, { desc = "server picker" })

        -- the global <CR> shadows the builtin jump/execute in quickfix and
        -- the cmdline-window; restore it buffer-locally there
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "qf",
            callback = function(a)
                vim.keymap.set("n", "<CR>", "<CR>", { buffer = a.buf })
            end,
        })
        vim.api.nvim_create_autocmd("CmdwinEnter", {
            callback = function()
                vim.keymap.set("n", "<CR>", "<CR>", { buffer = true })
            end,
        })
    end,
}
