-- Sweep sockets that dead nvims left in $XDG_RUNTIME_DIR: the default
-- nvim.<pid>.<n> servers and fzf-lua.<time>.<pid>.<n>. A clean exit unlinks
-- them; a killed or crashed nvim does not, and the runtime dir lives until
-- logout, which on this box is months. Runs once per startup.

local dir = vim.env.XDG_RUNTIME_DIR
if not dir then
    return
end

for name, type in vim.fs.dir(dir) do
    local pid = name:match("^nvim%.(%d+)%.%d+$") or name:match("^fzf%-lua%.%d+%.(%d+)%.%d+$")
    -- only ESRCH means dead; a reused pid just keeps its socket until next time
    if pid and type == "socket" then
        local _, _, errname = vim.uv.kill(tonumber(pid) --[[@as integer]], 0)
        if errname == "ESRCH" then
            os.remove(vim.fs.joinpath(dir, name))
        end
    end
end
