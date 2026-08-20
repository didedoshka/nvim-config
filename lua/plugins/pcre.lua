return {
    dir = vim.fn.expand("~/personal/pcre.nvim"),
    config = function()
        local pcre = require("pcre")
        pcre.setup({
            -- :s, :%s, :'<,'>s all run :S, swapped invisibly at <CR>; the
            -- price is a native (not pcre) 'inccommand' preview while typing
            substitute_abbrev = "enter",
        })
        -- vertical screens: the middle is low, so a search lands near the top
        -- of the window instead (zt honours 'scrolloff'). Only when the cursor
        -- actually moved -- a cancelled prompt or a failed search stays put --
        -- and never as an operator motion, where scrolling makes no sense.
        local function to_top(search)
            return function()
                local before = vim.api.nvim_win_get_cursor(0)
                search()
                if not vim.deep_equal(before, vim.api.nvim_win_get_cursor(0)) then
                    vim.cmd.normal({ "zt", bang = true })
                end
            end
        end
        local backward = function() pcre.search({ backward = true }) end
        -- the whole search story speaks one regex syntax, in every mode: the
        -- prompt extends a visual selection and serves as an operator motion
        vim.keymap.set({ "n", "x" }, "/", to_top(pcre.search), { desc = "pcre2 search (/)" })
        vim.keymap.set({ "n", "x" }, "?", to_top(backward), { desc = "pcre2 search backward (?)" })
        vim.keymap.set({ "n", "x" }, "n", to_top(pcre.next), { desc = "(n)ext match" })
        vim.keymap.set({ "n", "x" }, "N", to_top(pcre.prev), { desc = "previous match (N)" })
        vim.keymap.set("o", "/", pcre.search, { desc = "pcre2 search (/)" })
        vim.keymap.set("o", "?", backward, { desc = "pcre2 search backward (?)" })
        vim.keymap.set("o", "n", pcre.next, { desc = "(n)ext match" })
        vim.keymap.set("o", "N", pcre.prev, { desc = "previous match (N)" })
        vim.keymap.set({ "n", "x", "o" }, "gn", function() pcre.select_match() end,
            { desc = "select (n)ext match (gn)" })
        vim.keymap.set({ "n", "x", "o" }, "gN", function() pcre.select_match({ backward = true }) end,
            { desc = "select previous match (gN)" })
        -- * is \bword\b, not \<word\>; in visual mode it searches the selection
        vim.keymap.set("n", "*", pcre.search_cword, { desc = "pcre2 search word forward (*)" })
        vim.keymap.set("n", "#", function() pcre.search_cword({ backward = true }) end,
            { desc = "pcre2 search word backward (#)" })
        vim.keymap.set("n", "g*", function() pcre.search_cword({ exact = false }) end,
            { desc = "pcre2 search word forward, partial (g*)" })
        vim.keymap.set("n", "g#", function() pcre.search_cword({ backward = true, exact = false }) end,
            { desc = "pcre2 search word backward, partial (g#)" })
        vim.keymap.set("x", "*", function() pcre.search_selection() end,
            { desc = "pcre2 search selection forward (*)" })
        vim.keymap.set("x", "#", function() pcre.search_selection({ backward = true }) end,
            { desc = "pcre2 search selection backward (#)" })
        -- nvim's default <C-l> clears hlsearch via a <Cmd> mapping the plugin's
        -- :noh hook cannot observe (no Cmdline events fire) -- chain the clear in
        vim.keymap.set("n", "<C-l>", function()
            pcre.clear()
            vim.cmd.nohlsearch()
            vim.cmd.diffupdate()
            vim.cmd.normal({ vim.keycode("<C-l>"), bang = true })
        end, { desc = "clear search highlights and redraw (<C-l>)" })
    end,
}
