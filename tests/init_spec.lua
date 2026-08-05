-- Tier 2: the real init.lua, loaded with the real plugins.
--
-- Run as `nvim --headless -u init.lua -l tests/init_spec.lua`, so by the time
-- this file runs the config has fully started: lazy has loaded, `dide` is
-- applied and every autocmd and keymap is live. This tier asserts the config's
-- actual contract rather than the shape of its source.
--
-- Note: nvim exits 0 even when init.lua throws -- the error only reaches
-- stderr. tests/run.sh is what turns that into a failure; do not rely on the
-- exit code of this file alone to prove init.lua is clean.

local h = dofile(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)) .. "/harness.lua")
local test, ok, eq = h.test, h.ok, h.eq
h.quiet()

-- ------------------------------------------------------------------- options

test("leader and localleader are <space>", function()
    eq(vim.g.mapleader, " ")
    eq(vim.g.maplocalleader, " ")
end)

test("indentation is 4 spaces, expandtab", function()
    eq(vim.o.tabstop, 4)
    eq(vim.o.shiftwidth, 4)
    eq(vim.o.expandtab, true)
end)

test("documented core options are set", function()
    eq(vim.o.number, true)
    eq(vim.o.relativenumber, true)
    eq(vim.o.undofile, true)
    eq(vim.o.wrap, false, "the config sets nowrap")
    eq(vim.o.list, true)
end)

-- ----------------------------------------------------------------- filetypes

test("custom filetype rules match", function()
    eq(vim.filetype.match({ filename = "foo.keymap" }), "cpp")
    eq(vim.filetype.match({ filename = "widget.cpp.inc" }), "cpp")
    eq(vim.filetype.match({ filename = "widget.h.inc" }), "cpp")
end)

-- --------------------------------------------------------------- colorscheme

test("dide is the active colorscheme", function()
    eq(vim.g.colors_name, "dide")
end)

-- ------------------------------------------------------------------- keymaps

test("habit-breaker keys are bound", function()
    for _, key in ipairs({ "s", "S", "<C-o>" }) do
        for _, mode in ipairs({ "n", "v" }) do
            -- s/S are bound in both modes; <C-o> is normal-mode only
            if not (key == "<C-o>" and mode == "v") then
                local lhs = vim.api.nvim_replace_termcodes(key, true, false, true)
                ok(vim.fn.maparg(lhs, mode) ~= "", ("%s not bound in %s mode"):format(key, mode))
            end
        end
    end
end)

test("jump and window keys are remapped", function()
    local function mapped(key)
        return vim.fn.maparg(vim.api.nvim_replace_termcodes(key, true, false, true), "n") ~= ""
    end
    ok(mapped("<C-j>"), "<C-j> (jump forward) not mapped")
    ok(mapped("<C-k>"), "<C-k> (jump back) not mapped")
    ok(mapped("<Tab>"), "<Tab> (window prefix) not mapped")
end)

-- ------------------------------------------------------------------ commands

test("custom commands are registered", function()
    eq(vim.fn.exists(":GdbBtQf"), 2, ":GdbBtQf (lua/gdb_bt_qf.lua)")
    eq(vim.fn.exists(":GdbBtQfSelection"), 2, ":GdbBtQfSelection (lua/gdb_bt_qf.lua)")
    eq(vim.fn.exists(":CopyLoc"), 2, ":CopyLoc (plugin/copyloc.lua)")
    eq(vim.fn.exists(":Litre"), 2, ":Litre (plugins/litre.lua)")
    -- guarded by native :restart/:connect, both present in this build
    eq(vim.fn.exists(":Restart"), 2, ":Restart (plugin/server.lua)")
    eq(vim.fn.exists(":Connect"), 2, ":Connect (plugin/server.lua)")
    eq(vim.fn.exists(":Reload"), 2, ":Reload (plugin/reload.lua)")
end)

test(":Reload re-sources init.lua without duplicating its autocmds", function()
    -- perturb an option init.lua sets: it coming back proves the re-source
    -- actually ran rather than failing quietly
    vim.o.tabstop = 8
    vim.cmd("Reload")
    eq(vim.o.tabstop, 4, ":Reload did not re-apply init.lua")
    vim.cmd("Reload")
    local autosave = vim.api.nvim_get_autocmds({ group = "init", event = "TextChanged" })
    eq(#autosave, 1, "autosave autocmd duplicated by :Reload")
    eq(vim.g.colors_name, "dide")
    eq(vim.fn.exists(":GdbBtQf"), 2, "gdb_bt_qf did not survive the cache drop")
end)

-- --------------------------------------------------------------------- lazy

test("lazy loaded the plugin list with no broken specs", function()
    local plugins = require("lazy").plugins()
    ok(#plugins > 0, "lazy has no plugins")
    for _, plugin in ipairs(plugins) do
        ok(not (plugin._ and plugin._.error), ("plugin %s failed: %s"):format(
            plugin.name, plugin._ and vim.inspect(plugin._.error)))
    end
end)

test("every require(\"plugins.*\") in the list reached lazy", function()
    local names = {}
    for _, plugin in ipairs(require("lazy").plugins()) do
        names[plugin.name] = true
    end
    -- one representative per lua/plugins/*.lua file, to catch a spec that was
    -- written but never wired into init.lua's setup{} list
    for _, name in ipairs({ "oil.nvim", "nvim-cmp", "nvim-treesitter", "nvim-lspconfig",
        "comment.nvim", "lazygit.nvim", "flit.nvim", "fzf-lua", "lualine.nvim", "nvim-dap" }) do
        ok(names[name], name .. " is not in lazy's plugin list")
    end
end)

-- ------------------------------------------------------- autosave, end to end

test("autosave writes the buffer on InsertLeave", function()
    local tmp = vim.fn.tempname() .. ".txt"
    vim.fn.writefile({ "original" }, tmp)
    vim.cmd.edit(tmp)

    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "changed by test" })
    ok(vim.bo.modified, "buffer should be modified before the autocmd runs")

    vim.api.nvim_exec_autocmds("InsertLeave", {})

    eq(vim.bo.modified, false, "autosave did not write the buffer")
    eq(vim.fn.readfile(tmp), { "changed by test" }, "file on disk was not updated")
    vim.cmd("bwipeout!")
    os.remove(tmp)
end)

test("autosave writes the buffer on TextChanged", function()
    local tmp = vim.fn.tempname() .. ".txt"
    vim.fn.writefile({ "original" }, tmp)
    vim.cmd.edit(tmp)

    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "via TextChanged" })
    vim.api.nvim_exec_autocmds("TextChanged", {})

    eq(vim.fn.readfile(tmp), { "via TextChanged" }, "file on disk was not updated")
    vim.cmd("bwipeout!")
    os.remove(tmp)
end)

test("autosave leaves scratch buffers alone", function()
    -- the guard is buftype == "" and expand("%") ~= "" and filetype ~= ""
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "scratch" })
    local wrote = pcall(vim.api.nvim_exec_autocmds, "TextChanged", {})
    ok(wrote, "autosave errored on a nameless scratch buffer")
    vim.cmd("bwipeout!")
end)

h.finish("init")
