return {
    dir = vim.fn.expand("~/personal/pcre.nvim"),
    config = function()
        local pcre = require("pcre")
        pcre.setup({
            substitute_abbrev = true, -- :s, :%s, :'<,'>s all mean :S now
        })
        vim.keymap.set("n", "/", pcre.search, { desc = "pcre2 search (/)" })
        vim.keymap.set("n", "n", pcre.next, { desc = "(n)ext match" })
        vim.keymap.set("n", "N", pcre.prev, { desc = "previous match (N)" })
        -- the whole search story speaks one regex syntax: * is \bword\b, not \<word\>
        vim.keymap.set("n", "*", pcre.search_cword, { desc = "pcre2 search word forward (*)" })
        vim.keymap.set("n", "#", function() pcre.search_cword({ backward = true }) end,
            { desc = "pcre2 search word backward (#)" })
        vim.keymap.set("n", "g*", function() pcre.search_cword({ exact = false }) end,
            { desc = "pcre2 search word forward, partial (g*)" })
        vim.keymap.set("n", "g#", function() pcre.search_cword({ backward = true, exact = false }) end,
            { desc = "pcre2 search word backward, partial (g#)" })
    end,
}
