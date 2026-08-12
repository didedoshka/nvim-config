return {
    dir = vim.fn.expand("~/personal/litre.nvim"),
    dependencies = { "mfussenegger/nvim-dap" },
    config = function()
        require("litre").setup({
            -- machine side of the `debug("cpp", ...)` primitive: the gdb
            -- adapter and its arc quirks live in plugins/dap.lua; .litre.lua
            -- files supply only program/args/cwd
            dap_templates = {
                cpp = {
                    type = "gdb",
                    request = "launch",
                },
            },
        })

        -- x is the litre layer (the layer-key inventory in notes/ideas.md):
        -- opens the fzf-pin picker; x<key> runs a map()ped task, xv params,
        -- xc config, xo last output, xr re-run, xi search; ctrl-c in a
        -- litre:// buffer kills its task
        vim.keymap.set("n", "x", function()
            require("litre").layer()
        end, { desc = "litre" })
    end,
}
