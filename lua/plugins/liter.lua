return {
    "didedoshka/liter.nvim",
    dev = true,
    dependencies = { "mfussenegger/nvim-dap" },
    config = function()
        require("liter").setup({
            -- machine side of the `debug("gdb" or "lldb", ...)` primitive: the
            -- adapters (gdb with its arc quirks) live in plugins/dap.lua;
            -- .liter.lua files pick one and supply only program/args/cwd
            dap_templates = {
                gdb = {
                    type = "gdb",
                    request = "launch",
                },
                lldb = {
                    type = "lldb",
                    request = "launch",
                },
            },
        })

        -- x is the liter layer (the layer-key inventory in notes/ideas.md):
        -- opens the fzf-pin picker over tasks and params; x<key> activates a
        -- pinned one (a free key pins the highlighted entry), xC config,
        -- xO last output, xR re-run, xi search; ctrl-c in a liter:// buffer
        -- kills its task
        vim.keymap.set("n", "x", function()
            require("liter").layer()
        end, { desc = "liter" })
    end,
}
