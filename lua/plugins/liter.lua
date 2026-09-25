return {
    dir = vim.fn.expand("~/personal/liter.nvim"),
    dependencies = { "mfussenegger/nvim-dap" },
    config = function()
        require("liter").setup({
            -- machine side of the `debug("cpp", ...)` primitive: the gdb
            -- adapter and its arc quirks live in plugins/dap.lua; .liter.lua
            -- files supply only program/args/cwd
            dap_templates = {
                cpp = {
                    type = "gdb",
                    request = "launch",
                },
            },
        })

        -- x is the liter layer (the layer-key inventory in notes/ideas.md):
        -- opens the fzf-pin picker; x<key> runs a map()ped task, xV params,
        -- xC config, xO last output, xR re-run, xi search; ctrl-c in a
        -- liter:// buffer kills its task
        vim.keymap.set("n", "x", function()
            require("liter").layer()
        end, { desc = "liter" })
    end,
}
