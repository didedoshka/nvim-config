-- Tier 1: everything that needs no plugins.
--
-- Runs under `nvim --clean`, so lazy.nvim and every downloaded plugin are
-- absent. That is the point: this tier stays green on a fresh clone and pins
-- the parts of the config that are genuinely ours -- the colorscheme, the
-- gdb_bt_qf module, plugin/ features, spec shape, snippets and queries.
--
-- Deliberately never `:edit`s a real file: applying `dide` registers a
-- FileType autocmd that requires nvim-treesitter, which does not exist here.
-- Anything needing a real buffer with a filetype belongs in init_spec.lua.

local root = vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)))
vim.opt.rtp:prepend(root)

local h = dofile(root .. "/tests/harness.lua")
local test, ok, eq = h.test, h.ok, h.eq
h.quiet()

local function glob(pat)
    return vim.fn.glob(root .. "/" .. pat, false, true)
end

-- ---------------------------------------------------------------- modules load

test("every lua/plugins/*.lua spec loads", function()
    local specs = glob("lua/plugins/*.lua")
    ok(#specs > 0, "no plugin specs found")
    for _, file in ipairs(specs) do
        local name = vim.fn.fnamemodify(file, ":t:r")
        local loaded, spec = pcall(require, "plugins." .. name)
        ok(loaded, ("plugins.%s failed to load: %s"):format(name, spec))
        ok(type(spec) == "table", ("plugins.%s must return a table"):format(name))
    end
end)

test("gdb_bt_qf loads", function()
    ok(type(require("gdb_bt_qf")) == "table")
end)

test("lualine dide theme has the sections lualine reads", function()
    local theme = require("lualine.themes.dide")
    for _, section in ipairs({ "a", "b", "c" }) do
        ok(theme.normal[section], "normal." .. section .. " missing")
        ok(theme.normal[section].bg, "normal." .. section .. ".bg missing")
        ok(theme.normal[section].fg, "normal." .. section .. ".fg missing")
    end
end)

-- ---------------------------------------------------------- spec conventions
-- CLAUDE.md: specs always use `config = function()`,
-- never the declarative `keys`/`opts` fields.

test("plugin specs use config, never keys/opts", function()
    for _, file in ipairs(glob("lua/plugins/*.lua")) do
        local name = vim.fn.fnamemodify(file, ":t:r")
        local spec = require("plugins." .. name)
        ok(spec[1] or spec.dir, ("plugins.%s has no plugin source"):format(name))
        ok(spec.opts == nil, ("plugins.%s uses `opts`; use config = function()"):format(name))
        ok(spec.keys == nil, ("plugins.%s uses `keys`; use config = function()"):format(name))
        if spec.config ~= nil then
            ok(type(spec.config) == "function", ("plugins.%s: config must be a function"):format(name))
        end
    end
end)

-- -------------------------------------------------------------- gdb_bt_qf

-- `arc root` is the module's only external dependency. Stub that one shell-out
-- and the rest -- grouping, parsing, path rewriting, quickfix population --
-- runs for real. `vim.v.shell_error` is read-only, so zero it with a real
-- successful command before swapping vim.fn.system out.
local function with_fake_arc_root(root_path, fn)
    vim.fn.system("true")
    local real = vim.fn.system
    vim.fn.system = function(cmd)
        if type(cmd) == "string" and cmd:match("arc root") then
            return root_path .. "\n"
        end
        return real(cmd)
    end
    local finished, err = pcall(fn)
    vim.fn.system = real
    if not finished then
        error(err, 0)
    end
end

test("gdb_bt_qf.setup registers both commands", function()
    require("gdb_bt_qf").setup({})
    eq(vim.fn.exists(":GdbBtQf"), 2, ":GdbBtQf")
    eq(vim.fn.exists(":GdbBtQfSelection"), 2, ":GdbBtQfSelection")
end)

test("gdb_bt_qf config survives re-setup", function()
    local g = require("gdb_bt_qf")
    g.setup({ open_qf = false })
    eq(g.config.open_qf, false, "explicit value not stored")
    g.setup({})
    eq(g.config.open_qf, false, "empty re-setup clobbered the earlier value")
    g.setup({ open_qf = true })
    eq(g.config.open_qf, true, "value not overridable")
end)

test("gdb_bt_qf turns a backtrace into quickfix entries", function()
    local g = require("gdb_bt_qf")
    with_fake_arc_root("/fake/root", function()
        g.lines_to_qf({
            "#0  yt::Foo (x=1) at /-S/yt/yt/foo.cpp:123",
            -- gdb wraps long frames; the continuation must fold into frame #1
            "#1  0xabc in yt::Bar (this=0x0,",
            "        y=2) at /-S/contrib/bar.h:5",
            "#2  0xdef in main () at relative/path.cpp:7",
            -- no "at file:line" -- not a location, must be skipped
            "#3  0x123 in ?? ()",
        }, { open_qf = false })
    end)

    local qf = vim.fn.getqflist()
    eq(#qf, 3, "expected 3 locatable frames")

    eq(vim.fn.bufname(qf[1].bufnr), "/fake/root/yt/yt/foo.cpp", "/-S prefix must resolve to arc root")
    eq(qf[1].lnum, 123)
    eq(qf[1].nr, 0)
    eq(qf[1].text, "#0 yt::Foo (x=1)")

    eq(vim.fn.bufname(qf[2].bufnr), "/fake/root/contrib/bar.h")
    eq(qf[2].lnum, 5)
    eq(qf[2].text, "#1 0xabc in yt::Bar (this=0x0, y=2)", "wrapped frame not joined")

    -- a path with no leading slash is not arc-relative and stays untouched
    eq(vim.fn.bufname(qf[3].bufnr), "relative/path.cpp")
    eq(qf[3].lnum, 7)

    eq(vim.fn.getqflist({ title = true }).title, "GDB backtrace")
end)

-- ------------------------------------------------------------- plugin/ features

test("copyloc yanks path:line and path:line1-line2", function()
    vim.cmd.source(root .. "/plugin/copyloc.lua")
    eq(vim.fn.exists(":CopyLoc"), 2, ":CopyLoc not registered")

    -- set the name rather than :edit -- naming a buffer fires no FileType
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(buf, "/tmp/copyloc_spec.txt")
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "a", "b", "c" })

    vim.cmd("CopyLoc")
    eq(vim.fn.getreg("+"), "/tmp/copyloc_spec.txt:1", "single line")

    vim.cmd("1,3CopyLoc")
    eq(vim.fn.getreg("+"), "/tmp/copyloc_spec.txt:1-3", "range")
end)

test("copyloc refuses a nameless buffer", function()
    vim.cmd.source(root .. "/plugin/copyloc.lua")
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(buf)
    vim.fn.setreg("+", "untouched")
    vim.cmd("CopyLoc")
    eq(vim.fn.getreg("+"), "untouched", "should not have yanked anything")
end)

test("quitguard arms its sentinel while a busy terminal exists", function()
    -- the block itself is nvim core (a modified buffer fails :qa with E37);
    -- the guard's own contract is the sentinel's modified flag on QuitPre
    vim.cmd.source(root .. "/plugin/quitguard.lua")

    local term = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(term)
    -- sh as the "shell", sleep as the thing running in it: busy means the
    -- shell has children, so a direct job would not arm the guard
    local job = vim.fn.jobstart({ "sh", "-c", "sleep 30" }, { term = true })
    ok(job > 0, "terminal job failed to start")
    local pid = vim.b[term].terminal_job_pid
    ok(vim.wait(2000, function()
        local alive, kids = pcall(vim.api.nvim_get_proc_children, pid)
        return alive and #kids > 0
    end), "shell never spawned its child")

    vim.api.nvim_exec_autocmds("QuitPre", {})
    local buf = vim.g.quitguard_sentinel
    ok(buf and vim.api.nvim_buf_is_valid(buf), "sentinel not created")
    eq(vim.bo[buf].modified, true, "sentinel not armed with a busy terminal")
    ok(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]:find("sleep", 1, true),
        "sentinel line does not name the running command")

    -- shell gone: QuitPre must disarm
    vim.fn.jobstop(job)
    vim.wait(1000, function()
        return not pcall(vim.api.nvim_get_proc, pid)
    end)
    vim.api.nvim_exec_autocmds("QuitPre", {})
    eq(vim.bo[buf].modified, false, "sentinel armed with the shell gone")

    vim.api.nvim_buf_delete(term, { force = true })
end)

test("quitguard arms its sentinel while a litre task runs, and only then", function()
    vim.cmd.source(root .. "/plugin/quitguard.lua")
    package.loaded["litre.runner"] = {
        running_tasks = function()
            return { { id = "build" } }
        end,
    }

    vim.api.nvim_exec_autocmds("QuitPre", {})
    local buf = vim.g.quitguard_sentinel
    ok(buf and vim.api.nvim_buf_is_valid(buf), "sentinel not created")
    eq(vim.bo[buf].modified, true, "sentinel not armed with a task running")
    ok(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]:find("litre build", 1, true),
        "sentinel line does not name the running task")

    -- the flag self-clears right after the quit attempt it blocked
    ok(vim.wait(1000, function()
        return not vim.bo[buf].modified
    end), "sentinel stayed modified after the quit attempt")

    -- no running tasks: QuitPre must leave the sentinel unmodified
    package.loaded["litre.runner"] = {
        running_tasks = function()
            return {}
        end,
    }
    vim.api.nvim_exec_autocmds("QuitPre", {})
    eq(vim.bo[buf].modified, false, "sentinel armed with nothing running")

    package.loaded["litre.runner"] = nil
end)

test("keymaps_to_buffer maps <leader>y", function()
    vim.g.mapleader = " "
    vim.cmd.source(root .. "/plugin/keymaps_to_buffer.lua")
    ok(vim.fn.maparg(" y", "n") ~= "", "<leader>y not mapped")
end)

-- ------------------------------------------------------------- colorscheme

test("dide colorscheme applies", function()
    vim.cmd.colorscheme("dide")
    eq(vim.g.colors_name, "dide")
end)

test("dide sets the documented light background", function()
    vim.cmd.colorscheme("dide")
    local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
    eq(normal.bg, tonumber("FFFFFF", 16), "Normal bg should be the #FFFFFF from the colors table")
    eq(normal.fg, tonumber("2d2d2d", 16), "Normal fg should be the #2d2d2d from the colors table")
end)

test("dide defines a contiguous semantic highlighting palette", function()
    vim.cmd.colorscheme("dide")
    local count = 0
    for i = 1, 64 do
        local hl = vim.api.nvim_get_hl(0, { name = "SemanticHighlightingColor" .. i })
        if not hl or not next(hl) then
            break
        end
        ok(hl.fg, ("SemanticHighlightingColor%d has no fg"):format(i))
        count = i
    end
    ok(count > 1, "semantic highlighting palette is missing (rainbow-delimiters reads these)")
    -- init.lua's rainbow-delimiters spec references group 11 by name
    ok(count >= 11, ("only %d semantic groups; rainbow-delimiters uses up to 11"):format(count))
end)

test("dide can be re-applied", function()
    vim.cmd.colorscheme("dide")
    vim.cmd.colorscheme("dide")
    eq(vim.g.colors_name, "dide")
end)

-- --------------------------------------------------------- queries & snippets

test("queries parse against their grammar", function()
    for _, file in ipairs(glob("queries/*/*.scm")) do
        local lang = vim.fn.fnamemodify(file, ":h:t")
        if vim.treesitter.language.add(lang) then
            local text = table.concat(vim.fn.readfile(file), "\n")
            local parsed, err = pcall(vim.treesitter.query.parse, lang, text)
            ok(parsed, ("%s is not a valid %s query: %s"):format(file, lang, err))
        end
    end
end)

test("snippet files are lists of {prefix, body}", function()
    local files = glob("snippets/*.lua")
    ok(#files > 0, "no snippet files found")
    for _, file in ipairs(files) do
        local loaded, snippets = pcall(dofile, file)
        ok(loaded, ("%s failed to load: %s"):format(file, snippets))
        ok(type(snippets) == "table" and #snippets > 0, file .. " should return a non-empty list")
        for i, snip in ipairs(snippets) do
            ok(type(snip.prefix) == "string", ("%s[%d] has no string prefix"):format(file, i))
            ok(type(snip.body) == "string", ("%s[%d] has no string body"):format(file, i))
        end
    end
end)

test("russian-yasherty keymap loads", function()
    vim.opt.keymap = "russian-yasherty"
    eq(vim.o.keymap, "russian-yasherty")
    vim.opt.keymap = ""
end)

h.finish("core")
