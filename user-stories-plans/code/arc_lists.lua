-- PROPOSED new file: plugin/arc_lists.lua  (story 06 + story 03c)
--
-- A durable "lists" workflow built on the quickfix list. The quickfix list is the
-- one navigable, persistent, stack-backed list Neovim already ships; these commands
-- just feed it from the sources you actually use.
--
--   :ArcChangedFiles [rev]   changed files (working copy, or vs <rev>) -> quickfix
--   :Qf                      parse buffer / :'<,'> range as file:line[:col[:text]] -> quickfix
--   :QfSave <name>           save the current quickfix list to disk
--   :QfLoad <name>           load a saved quickfix list
--   :QfLists                 pick a saved list (vim.ui.select -> fzf-lua)
--
-- Pairs with the quickfix-stack keymaps proposed in 05-quickfix-persistence.md.

local M = {}

local function run(cmd, dir)
    local res = vim.system(cmd, { cwd = dir, text = true }):wait()
    if res.code ~= 0 then
        vim.notify(table.concat(cmd, " ") .. " failed: " .. (res.stderr or ""), vim.log.levels.WARN)
        return nil
    end
    return res.stdout or ""
end

-- changed files -> quickfix (each file at line 1)
local function arc_changed_files(rev)
    local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
    if dir == "" then dir = vim.fn.getcwd() end

    local cmd = { "arc", "diff", "--name-only" }
    if rev and rev ~= "" then cmd[#cmd + 1] = rev end
    local out = run(cmd, dir)
    if not out then return end

    local root = vim.trim(run({ "arc", "root" }, dir) or "")
    local items = {}
    for line in out:gmatch("[^\n]+") do
        local path = vim.trim(line)
        if path ~= "" then
            items[#items + 1] = { filename = root .. "/" .. path, lnum = 1, col = 1, text = path }
        end
    end

    vim.fn.setqflist({}, " ", { title = "arc changed" .. (rev ~= "" and (" vs " .. rev) or ""), items = items })
    vim.cmd("copen")
    vim.notify(("%d changed file(s)"):format(#items))
end

vim.api.nvim_create_user_command("ArcChangedFiles", function(o) arc_changed_files(o.args) end,
    { nargs = "?", desc = "arc changed files -> quickfix" })

-- parse arbitrary text (whole buffer, or a visual range) into quickfix via errorformat.
-- accepts grep-style "path:line:col:text", "path:line:text", and bare "path:line".
local function to_qf(line1, line2)
    local lines
    if line1 and line2 then
        lines = vim.api.nvim_buf_get_lines(0, line1 - 1, line2, false)
    else
        lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    end
    local efm = "%f:%l:%c:%m,%f:%l:%m,%f:%l"
    vim.fn.setqflist({}, " ", { title = "parsed", lines = lines, efm = efm })
    vim.cmd("copen")
end

vim.api.nvim_create_user_command("Qf", function(o)
    if o.range == 2 then to_qf(o.line1, o.line2) else to_qf(nil, nil) end
end, { range = true, desc = "parse buffer/range into quickfix" })

-- persistence -------------------------------------------------------------
local store = vim.fn.stdpath("data") .. "/qflists"

local function save(name)
    if name == "" then vim.notify("usage: :QfSave <name>", vim.log.levels.WARN) return end
    vim.fn.mkdir(store, "p")
    local qf = vim.fn.getqflist({ items = 1, title = 1 })
    local path = store .. "/" .. name .. ".json"
    local fd = assert(io.open(path, "w"))
    fd:write(vim.json.encode(qf))
    fd:close()
    vim.notify("saved quickfix list -> " .. path)
end

local function load(name)
    local path = store .. "/" .. name .. ".json"
    local fd = io.open(path, "r")
    if not fd then vim.notify("no saved list: " .. name, vim.log.levels.WARN) return end
    local qf = vim.json.decode(fd:read("*a"))
    fd:close()
    vim.fn.setqflist({}, " ", { title = qf.title or name, items = qf.items or {} })
    vim.cmd("copen")
end

local function saved_names()
    if vim.fn.isdirectory(store) == 0 then return {} end
    local names = {}
    for name, t in vim.fs.dir(store) do
        if t == "file" and name:match("%.json$") then
            names[#names + 1] = name:gsub("%.json$", "")
        end
    end
    return names
end

vim.api.nvim_create_user_command("QfSave", function(o) save(o.args) end, { nargs = 1 })
vim.api.nvim_create_user_command("QfLoad", function(o) load(o.args) end,
    { nargs = 1, complete = function() return saved_names() end })
vim.api.nvim_create_user_command("QfLists", function()
    vim.ui.select(saved_names(), { prompt = "load list: " }, function(c) if c then load(c) end end)
end, {})

return M
