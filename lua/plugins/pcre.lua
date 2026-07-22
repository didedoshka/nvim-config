return {
    dir = vim.fn.expand("~/personal/pcre.nvim"),
    config = function()
        local ps = require("pcre")
        ps.setup({
            substitute_abbrev = true, -- :s, :%s, :'<,'>s all mean :S now
        })
        vim.keymap.set("n", "/", ps.search, { desc = "pcre2 search (/)" })
        vim.keymap.set("n", "n", ps.next, { desc = "(n)ext match" })
        vim.keymap.set("n", "N", ps.prev, { desc = "previous match (N)" })
        -- vim.keymap.set("n", "<leader>p", ps.toggle, { desc = "toggle (p)cre" })
        -- * and # stay native, but the pcre highlights they replace have to go
        -- at once -- n/N only notice the handover the next time they run
        for _, key in ipairs({ "*", "#", "g*", "g#" }) do
            vim.keymap.set("n", key, function()
                ps.clear()
                return key
            end, { expr = true, desc = "native search for word under cursor" })
        end
    end,
}
