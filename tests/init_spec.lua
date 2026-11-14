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
    for _, key in ipairs({ "s", "S" }) do
        for _, mode in ipairs({ "n", "v" }) do
            local lhs = vim.api.nvim_replace_termcodes(key, true, false, true)
            ok(vim.fn.maparg(lhs, mode) ~= "", ("%s not bound in %s mode"):format(key, mode))
        end
    end
end)

test("<C-l> switches russian in its buffer only, a new buffer starts latin", function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    -- headless, `-- INSERT --` goes to stderr, which run.sh counts as a failure
    local showmode = vim.o.showmode
    vim.o.showmode = false
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("i<C-l><Esc>", true, false, true), "xt", false)
    vim.o.showmode = showmode
    eq(vim.bo[buf].iminsert, 1, "<C-l> did not switch the buffer to russian")
    eq(vim.go.iminsert, 0, "<C-l> leaked russian into the global 'iminsert'")
    local fresh = vim.api.nvim_create_buf(false, true)
    eq(vim.bo[fresh].iminsert, 0, "a new buffer started in russian")
    vim.api.nvim_buf_delete(fresh, { force = true })
    vim.api.nvim_buf_delete(buf, { force = true })
end)

test("TermOpen numbers real terminals but not fzf's picker", function()
    local function open_term(filetype)
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_current_buf(buf)
        vim.bo[buf].filetype = filetype
        -- like fzf-lua's float (style = "minimal"): numbers off before the job starts
        vim.wo.number, vim.wo.relativenumber = false, false
        vim.api.nvim_open_term(buf, {})
        return vim.wo.number
    end
    eq(open_term(""), true, "a plain terminal should get line numbers")
    eq(open_term("fzf"), false, "fzf's terminal should keep its minimal style")
end)

test("fzf keeps a query history per picker and <leader>l resumes", function()
    local lhs = vim.api.nvim_replace_termcodes("<leader>l", true, false, true)
    ok(vim.fn.maparg(lhs, "n") ~= "", "<leader>l (resume last picker) not bound")
    -- the g:fzf_history_dir shim gives each picker its own file, named by its
    -- resume key; a plugin update dropping the shim would silently lose this
    local opts = require("fzf-lua.config").normalize_opts({}, "files")
    local hist = opts and opts.fzf_opts and opts.fzf_opts["--history"]
    ok(type(hist) == "string" and hist:match("/fzf%-history/files$"),
        "files picker --history is " .. vim.inspect(hist))
end)

test("range-taking keymaps are also bound in visual mode", function()
    for _, key in ipairs({ "<leader>y", "<leader>al" }) do
        local lhs = vim.api.nvim_replace_termcodes(key, true, false, true)
        local rhs = vim.fn.maparg(lhs, "x")
        ok(rhs ~= "", key .. " not bound in visual mode")
        -- `:` (not <cmd>) so the '<,'> range reaches the command
        ok(rhs:sub(1, 1) == ":", key .. " visual map must start with `:` to pass the range")
    end
end)

-- ------------------------------------------------------------------ commands

test("custom commands are registered", function()
    eq(vim.fn.exists(":GdbBtQf"), 2, ":GdbBtQf (lua/gdb_bt_qf.lua)")
    eq(vim.fn.exists(":GdbBtQfSelection"), 2, ":GdbBtQfSelection (lua/gdb_bt_qf.lua)")
    eq(vim.fn.exists(":CopyLoc"), 2, ":CopyLoc (plugin/copyloc.lua)")
    eq(vim.fn.exists(":Liter"), 2, ":Liter (plugins/liter.lua)")
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

-- ---------------------------------------------------------------- formatting

test("C++ formatting invokes ya with filename and range arguments", function()
    local generator
    for _, source in ipairs(require("null-ls.sources").get_all()) do
        if source.name == "clang_format" then generator = source.generator end
    end
    ok(generator, "C++ formatter is not registered")
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "int x;", "int  y;" })
    local loop = require("null-ls.loop")
    local spawn = loop.spawn
    local calls = {}
    loop.spawn = function(command, args, opts)
        table.insert(calls, { command = command, args = args, input = opts.input })
        opts.handler(nil, "int x;\nint y;\n")
    end
    local passed, err = pcall(function()
        local methods = require("null-ls.methods").internal
        for _, method in ipairs({ methods.FORMATTING, methods.RANGE_FORMATTING }) do
            local result
            generator.fn({
                bufnr = buf,
                bufname = "/tmp/format.cpp",
                method = method,
                range = { row = 2, col = 1, end_row = 2, end_col = 8 },
            }, function(edits) result = edits end)
            eq(result, { { text = "int x;\nint y;\n" } })
        end
        eq(calls, {
            {
                command = "ya",
                args = { "tool", "ads-clang-format", "-assume-filename", "/tmp/format.cpp" },
                input = "int x;\nint  y;\n",
            },
            {
                command = "ya",
                args = { "tool", "ads-clang-format", "-assume-filename", "/tmp/format.cpp", "--offset", "7", "--length", "7" },
                input = "int x;\nint  y;\n",
            },
        })
    end)
    loop.spawn = spawn
    vim.api.nvim_buf_delete(buf, { force = true })
    if not passed then error(err, 0) end
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

-- ------------------------------------------------------------------ pickers

test("ui.select finishes its callback on acceptance and cancellation", function()
    local core = require("fzf-lua.core")
    local exec = core.fzf_exec
    local opts
    core.fzf_exec = function(_, o) opts = o end
    local passed, err = pcall(function()
        for _, choice in ipairs({ "two", false }) do
            local called, result = false, nil
            vim.ui.select({ "one", "two" }, { prompt = "target:" }, function(value)
                called, result = true, value
            end)
            for _, key in ipairs({ "enter", "esc" }) do
                local action = opts.actions[key]
                ok(not (type(action) == "table" and action.exec_silent),
                    key .. " hides the picker instead of completing it")
            end
            opts.__CTX = { mode = "n" }
            opts.fn_selected(choice and { "enter", "2. two" } or nil, opts)
            ok(vim.wait(1000, function() return called end), "selection callback never ran")
            eq(result, choice or nil)
        end
    end)
    core.fzf_exec = exec
    if not passed then error(err, 0) end
end)

test("file and grep mappings respect a local .ignore over inherited exclusions", function()
    local dir = vim.fn.tempname()
    vim.fn.mkdir(dir .. "/project/src/nested", "p")
    vim.fn.mkdir(dir .. "/project/other", "p")
    vim.fn.writefile({ "*" }, dir .. "/.ignore")
    vim.fn.writefile({ "*", "!/src/", "!/src/**" }, dir .. "/project/.ignore")
    vim.fn.writefile({ "needle" }, dir .. "/project/src/nested/allowed.txt")
    vim.fn.writefile({ "needle" }, dir .. "/project/other/blocked.txt")
    local before = vim.fn.getcwd()
    local fzf = require("fzf-lua")
    local files, grep, register = fzf.files, fzf.live_grep, fzf.register_ui_select
    local captured = {}
    fzf.files = function(opts) captured.files = opts end
    fzf.live_grep = function(opts) captured.grep = opts end
    fzf.register_ui_select = function() end
    local passed, err = pcall(function()
        vim.cmd.cd(dir .. "/project")
        require("plugins.fzf").config()
        vim.fn.maparg(" o", "n", false, true).callback()
        vim.fn.maparg(" g", "n", false, true).callback()
        local config = require("fzf-lua.config")
        local file_opts = config.normalize_opts(captured.files, "files")
        local grep_opts = config.normalize_opts(captured.grep, "grep")
        local commands = {
            require("fzf-lua.providers.files").get_files_cmd(file_opts),
            require("fzf-lua.make_entry").get_grep_cmd(grep_opts, "needle", false),
        }
        for _, cmd in ipairs(commands) do
            local result = vim.system({ vim.o.shell, "-c", cmd }, { text = true }):wait()
            eq(result.code, 0, result.stderr)
            ok(result.stdout:find("src/nested/allowed.txt", 1, true), "allowed file missing: " .. cmd)
            ok(not result.stdout:find("blocked.txt", 1, true), "excluded file returned: " .. cmd)
        end
    end)
    fzf.files, fzf.live_grep = files, grep
    require("plugins.fzf").config()
    fzf.register_ui_select = register
    vim.cmd.cd(before)
    vim.fn.delete(dir, "rf")
    if not passed then error(err, 0) end
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

-- ---------------------------------------------------------------- bookmarks

test("s pins the highlighted file, never a terminal", function()
    -- the fzf-pin source behind s, caught from the mapping without a picker.
    -- The :Reload test re-sourced init.lua, whose habit map for s shadows
    -- the picker's from then on, so the spec's own config maps it again
    require("plugins.fzf-pin").config()
    local fzfpin = require("fzf-pin")
    local pick, source = fzfpin.pick, {} ---@type function, table
    fzfpin.pick = function(s)
        source = s
    end
    vim.fn.maparg("s", "n", false, true).callback()
    fzfpin.pick = pick
    eq(source.pin("a", nil), "nothing highlighted to pin")
    eq(source.pin("a", { char = "e", data = "/x" }), "already on e (ctrl-x it to move)")
    local term = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_call(term, function()
        vim.fn.jobstart({ "sh" }, { term = true })
    end)
    eq(source.pin("a", { buf = term, data = vim.api.nvim_buf_get_name(term) }),
        "a terminal is not pinnable")
    vim.api.nvim_buf_delete(term, { force = true })
    -- pins are stored per cwd, so this one lands in a scratch cwd's file,
    -- removed afterwards: the real state dir keeps nothing
    local dir = vim.fn.tempname()
    vim.fn.mkdir(dir, "p")
    dir = assert(vim.uv.fs_realpath(dir))
    local before = vim.fn.getcwd()
    vim.cmd.cd(dir)
    local file = vim.fs.joinpath(dir, "main.c")
    local ns = "bookmarks/" .. dir:gsub("/", "%%")
    eq(source.pin("a", { buf = vim.fn.bufadd(file), data = file }), "pinned main.c to a")
    eq(require("fzf-pin.store").load(ns), { a = file })
    os.remove(vim.fs.joinpath(vim.fn.stdpath("state"), "fzf-pin", ns .. ".json"))
    vim.cmd("bwipeout! " .. vim.fn.fnameescape(file))
    vim.cmd.cd(before)
    vim.fn.delete(dir, "rf")
end)

h.finish("init")
