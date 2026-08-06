-- Records which keys, mappings and commands actually get used, so keymap
-- decisions come from data instead of memory. Opt-in, and easy to revoke:
--
--   mkdir -p ~/.local/share/nvim/keylog     start recording
--   :KeyReport                              read the tally
--   rm -rf ~/.local/share/nvim/keylog       stop recording, destroy the data
--
-- It never records prose: insert-mode keys are dropped without being looked
-- at, and commands are counted by name with their arguments discarded.

local dir = vim.fn.stdpath("data") .. "/keylog"
if vim.fn.isdirectory(dir) == 0 then
    return
end

-- One file per session: several nvim instances record concurrently, and
-- separate files mean they never clobber each other's counts.
local session = ("%s/%d-%d.json"):format(dir, os.time(), vim.fn.getpid())

-- Flat "<bucket> <name>" keys keep merging in :KeyReport a one-liner.
local counts = {}
local since_flush = 0

local function flush()
    vim.fn.writefile({ vim.json.encode(counts) }, session)
    since_flush = 0
end

local function bump(key)
    counts[key] = (counts[key] or 0) + 1
    since_flush = since_flush + 1
    if since_flush >= 50 then
        flush()
    end
end

-- mode() is far more specific than maparg()'s modes: collapse the variants we
-- care about (operator-pending "no"/"nov"/..., visual "v"/"V"/CTRL-V) and
-- return nil for the modes we deliberately don't record.
local function maparg_mode(m)
    if m:sub(1, 2) == "no" then
        return "o"
    elseif m:sub(1, 1) == "n" then
        return "n" -- also "niI" etc: a single normal command via i_CTRL-O
    elseif m:sub(1, 1) == "v" or m:sub(1, 1) == "V" or m:sub(1, 1) == "\22" then
        return "v"
    end
    return nil
end

-- `typed` is the keys as struck, before mappings expand; `key` is after. Two
-- consequences this relies on:
--   * a whole mapping arrives as ONE event whose `typed` is its lhs, so
--     <Space>ff is counted as <Space>ff and not as <Space>, f, f;
--   * keys the rhs *produced* arrive with an empty `typed`, so ignoring those
--     leaves exactly one event per real keypress.
-- mode() here is the mode the key is about to be handled in, which is what we
-- want: the `i` of `ihello` reports normal, its `hello` reports insert.
--
-- on_key drops a callback that errors, which would end recording silently for
-- the rest of the session -- hence the pcall.
vim.on_key(function(_, typed)
    if typed == "" then
        return
    end
    pcall(function()
        local mode = maparg_mode(vim.fn.mode(1))
        if mode == nil then
            return
        end
        local keys = vim.fn.keytrans(typed)
        -- A mapping and a bare keypress are indistinguishable by shape alone
        -- (single-key mappings exist), so ask.
        local bucket = vim.fn.maparg(keys, mode) ~= "" and "map" or "key"
        bump(("%s %s %s"):format(bucket, mode, keys))
    end)
end)

-- Commands run from a mapping's rhs never touch the cmdline, so this counts
-- exactly what was typed at the ":" prompt -- which is the set worth binding.
vim.api.nvim_create_autocmd("CmdlineLeave", {
    desc = "keylog: count ex commands",
    callback = function()
        if vim.fn.getcmdtype() ~= ":" or vim.v.event.abort then
            return
        end
        local line = vim.fn.getcmdline()
        -- Strip a leading range/count so ":42d" and ":%s" find their command.
        local name = line:match("^%s*[%%$%d,;'<>+%-.%s]*(%a[%w_]*)")
        if name == nil then
            return
        end
        -- Resolve abbreviations, so :w and :write are one entry. Returns ""
        -- for anything that isn't a real command (typos, :Foo from a plugin
        -- that has not loaded yet).
        local full = vim.fn.fullcommand(name)
        if full == "" then
            return
        end
        local kind = vim.api.nvim_get_commands({ builtin = false })[full] and "usercmd" or "excmd"
        bump(("%s %s"):format(kind, full))
    end,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
    desc = "keylog: save counts",
    callback = flush,
})

local function report()
    local totals = {}
    for _, file in ipairs(vim.fn.glob(dir .. "/*.json", false, true)) do
        local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(file)))
        if ok then
            for key, n in pairs(data) do
                totals[key] = (totals[key] or 0) + n
            end
        end
    end
    for key, n in pairs(counts) do -- this session has not flushed yet
        totals[key] = (totals[key] or 0) + n
    end

    -- desc is only knowable for mappings that exist right now, in this session.
    local descs = {}
    for _, mode in ipairs({ "n", "o", "v" }) do
        for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do
            if m.desc then
                descs[mode .. " " .. vim.fn.keytrans(vim.keycode(m.lhs))] = m.desc
            end
        end
    end

    local sections = {
        { "key n", "normal-mode keys -- what debug mode would have to claim" },
        { "key o", "operator-pending keys -- motions used as an operator's argument" },
        { "key v", "visual-mode keys" },
        { "map n", "normal-mode mappings" },
        { "map o", "operator-pending mappings" },
        { "map v", "visual-mode mappings" },
        { "usercmd", "user-defined commands -- candidates for a keymap" },
        { "excmd", "built-in ex commands" },
    }

    local lines = {}
    for _, section in ipairs(sections) do
        local prefix, title = section[1], section[2]
        local rows = {}
        for key, n in pairs(totals) do
            local name = key:match("^" .. prefix .. " (.*)$")
            if name then
                table.insert(rows, { name = name, n = n, key = key })
            end
        end
        if #rows > 0 then
            table.sort(rows, function(a, b)
                return a.n > b.n
            end)
            table.insert(lines, "")
            table.insert(lines, ("== %s (%d distinct)"):format(title, #rows))
            for _, row in ipairs(rows) do
                local desc = descs[row.key:match("^map (.*)$") or ""]
                table.insert(lines, ("%6d  %-14s %s"):format(row.n, row.name, desc or ""))
            end
        end
    end
    if #lines == 0 then
        lines = { "no data recorded yet" }
    end

    -- show it in the current window; <C-^> goes back to what was there
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].modifiable = false
    vim.api.nvim_win_set_buf(0, buf)
end

vim.api.nvim_create_user_command("KeyReport", report, { desc = "show recorded key/command usage" })
