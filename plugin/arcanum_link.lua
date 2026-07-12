-- arcanum links, both directions
--
--   * commit-pinned permalinks (?rev=<hash>) so shared links survive on non-trunk branches
--   * visual-range links (#L10-L20)
--   * a plain "trunk" (moving) variant kept as :ArcanumLinkTrunk
--   * :ArcanumOpen  -- reverse direction: an a.yandex-team.ru URL -> local buffer + line
--
-- Style: small, explicit, one arc call per fact, no popups (uses vim.notify).

local M = {}

-- Run a command in `dir`; return trimmed stdout, or nil on failure.
local function run(cmd, dir)
    local res = vim.system(cmd, { cwd = dir, text = true }):wait()
    if res.code ~= 0 or not res.stdout or res.stdout == "" then
        return nil
    end
    return vim.trim(res.stdout)
end

-- Gather the arc facts for the current buffer's file.
local function arc_context()
    local fname = vim.api.nvim_buf_get_name(0)
    if fname == "" then
        vim.notify("no file in this buffer", vim.log.levels.WARN)
        return nil
    end
    local dir = vim.fs.dirname(fname)

    local root = run({ "arc", "root" }, dir)
    if not root then
        vim.notify("not inside an arc repository", vim.log.levels.WARN)
        return nil
    end

    local info_json = run({ "arc", "info", "--json" }, dir)
    if not info_json then
        vim.notify("arc info failed", vim.log.levels.WARN)
        return nil
    end
    local info = vim.json.decode(info_json)

    -- fname == root .. "/" .. relpath ; strip root and the separating slash.
    local relpath = fname:sub(#root + 2)

    return {
        root = root,
        repository = info.repository, -- "arcadia"
        hash = info.hash,             -- current base commit (40-hex)
        relpath = relpath,
        dir = dir,
    }
end

-- Best-effort: does this file differ from its committed state? If so the pinned
-- line number may not line up with what the recipient sees. Never fatal.
-- `arc diff --name-only` prints repo-root-relative paths of all changed files;
-- we just check membership (avoids pathspec-vs-cwd relativity issues).
local function is_dirty(ctx)
    local out = run({ "arc", "diff", "--name-only" }, ctx.dir)
    if not out then return false end
    for line in (out .. "\n"):gmatch("([^\n]*)\n") do
        if vim.trim(line) == ctx.relpath then return true end
    end
    return false
end

local function copy(url)
    vim.fn.setreg("+", url)
    vim.notify(url)
end

local function fragment(line1, line2)
    if line2 and line2 ~= line1 then
        return ("#L%d-L%d"):format(line1, line2)
    end
    return ("#L%d"):format(line1)
end

-- https://a.yandex-team.ru/<repo>/<path>[?rev=<hash>]#L<a>[-L<b>]
local function build(ctx, line1, line2, pin)
    local url = "https://a.yandex-team.ru/" .. ctx.repository .. "/" .. ctx.relpath
    if pin then
        url = url .. "?rev=" .. ctx.hash
    end
    return url .. fragment(line1, line2)
end

local function link(opts, pin)
    local ctx = arc_context()
    if not ctx then return end
    local line1 = opts.line1 or vim.api.nvim_win_get_cursor(0)[1]
    local line2 = opts.line2 or line1
    if pin and is_dirty(ctx) then
        vim.notify(
            "warning: file has uncommitted changes; line may not match rev " .. ctx.hash:sub(1, 12),
            vim.log.levels.WARN
        )
    end
    copy(build(ctx, line1, line2, pin))
end

vim.api.nvim_create_user_command("ArcanumLink", function(o) link(o, true) end,
    { range = true, desc = "commit-pinned a.yandex-team.ru permalink -> clipboard" })

vim.api.nvim_create_user_command("ArcanumLinkTrunk", function(o) link(o, false) end,
    { range = true, desc = "trunk (moving) a.yandex-team.ru link -> clipboard" })

-- Reverse direction: paste an arcadia URL, land on the line in the editor.
local function open_url(url)
    url = vim.trim(url or vim.fn.getreg("+"))
    -- path lives between "/arcadia/" and the first ? or # ; also handles cs.yandex-team.ru
    local path = url:match("/arcadia/([^?#]+)")
    if not path then
        vim.notify("could not parse an arcadia path from: " .. url, vim.log.levels.WARN)
        return
    end
    -- find the arc checkout root; fall back to ~/a/hot if not inside one
    local root = run({ "arc", "root" }, vim.fn.getcwd()) or vim.fn.expand("~/a/hot")
    vim.cmd.edit(vim.fn.fnameescape(root .. "/" .. path))

    local line = url:match("#L(%d+)")
    if line then
        vim.api.nvim_win_set_cursor(0, { tonumber(line), 0 })
        vim.cmd("normal! zz")
    end

    local rev = url:match("[?&]rev=([0-9a-f]+)")
    if rev then
        vim.notify("link was pinned to rev " .. rev:sub(1, 12) .. " (opened current working copy)",
            vim.log.levels.INFO)
    end
end

vim.api.nvim_create_user_command("ArcanumOpen", function(o)
    open_url(o.args ~= "" and o.args or nil)
end, { nargs = "?", desc = "open an arcadia URL (arg or clipboard) in the editor" })

return M
