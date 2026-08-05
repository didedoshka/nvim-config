-- Apply init.lua edits to the running server without :Restart. Re-sourcing is
-- safe because init.lua's autocmds live in the "init" augroup (cleared on
-- re-create) and lazy.setup cannot run twice -- it is shimmed to a no-op for
-- the duration. What this cannot do: apply changes to plugin specs under
-- lua/plugins/ (their config functions already ran -- that is :Restart
-- territory), or remove things: a deleted keymap stays mapped until restart.
vim.api.nvim_create_user_command("Reload", function()
    -- gdb_bt_qf is the one config module init.lua require()s; drop it from the
    -- cache so edits to it load too
    package.loaded["gdb_bt_qf"] = nil
    local lazy = require("lazy")
    local setup = lazy.setup
    ---@diagnostic disable-next-line: duplicate-set-field
    lazy.setup = function() end
    -- not $MYVIMRC: it is unset under -u init.lua, which is how tests run
    local config = vim.fn.stdpath("config") --[[@as string]]
    local ok, err = pcall(dofile, vim.fs.joinpath(config, "init.lua"))
    lazy.setup = setup
    if not ok then
        vim.notify("Reload: " .. tostring(err), vim.log.levels.ERROR)
        return
    end
    -- this config's plugin/ features are written to re-source cleanly
    -- (commands replace themselves, augroups clear); this file included
    for _, file in ipairs(vim.fn.glob(config .. "/plugin/*.lua", false, true)) do
        dofile(file)
    end
    vim.notify("reloaded init.lua and plugin/")
end, {})
