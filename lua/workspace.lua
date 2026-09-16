-- .workspace -- the directories <leader>o / <leader>g search and the base the
-- `s` menu shows paths against: a VS Code multi-root workspace for an arc
-- checkout, where nvim runs at the root but the work lives in yt/yt, yt/cpp,
-- library/cpp and a playground, and a search over the whole tree is useless.
--
-- One directory per line, relative to the file (absolute and ~ also work);
-- blank lines and # comments are skipped. Found like .litre.lua, walking up
-- from the cwd, so a server started in a subdirectory sees the same file.
local M = {}

-- Nearest .workspace at or above the cwd as { root = dir, dirs = { ... } },
-- nil when there is none. Read fresh on every call: an edit takes effect at
-- the next picker, and the walk is a handful of stats.
function M.find()
    local dir = vim.fs.normalize(vim.fn.getcwd())
    while true do
        local file = vim.fs.joinpath(dir, ".workspace")
        if vim.uv.fs_stat(file) then
            local dirs = {}
            for _, line in ipairs(vim.fn.readfile(file)) do
                line = vim.trim(line)
                if line ~= "" and line:sub(1, 1) ~= "#" then
                    table.insert(dirs, line)
                end
            end
            return { root = dir, dirs = dirs }
        end
        local parent = vim.fs.dirname(dir)
        if parent == dir then
            return nil
        end
        dir = parent
    end
end

-- A path as the workspace shows it: relative to ws.root when under it, else
-- cwd-relative with ~ for home (what the `s` menu always showed). ws may be
-- nil; callers find() once and label many paths with it.
function M.relative(ws, path)
    if ws and path:sub(1, #ws.root + 1) == ws.root .. "/" then
        return path:sub(#ws.root + 2)
    end
    return vim.fn.fnamemodify(path, ":~:.")
end

return M
