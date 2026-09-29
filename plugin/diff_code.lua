-- #diff-code! for queries/diff/injections.scm: the code in a diff buffer (:ArcDiff, :ArcPrDiff,
-- `git diff | nvim -`) is injected in its file's language, so treesitter and didecolors colour
-- it like the file itself. The diff parser can't say which file a line belongs to: without a
-- `diff --git` line (arc diff has none) its tree is flat, so the +++ headers are read off the
-- buffer instead.

-- the last buffer read: its changedtick, and the filetype of every line (nil before a header)
local last = {}

local function filetypes(buf)
    local tick = vim.api.nvim_buf_get_changedtick(buf)
    if last.buf ~= buf or last.tick ~= tick then
        local fts, ft, old = {}, nil, nil
        for i, l in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
            local minus = l:match("^%-%-%- ([^\t]+)")
            local plus = l:match("^%+%+%+ ([^\t]+)")
            if minus then
                old = minus
            elseif plus then
                -- a deleted file is named by its --- line alone
                local file = plus == "/dev/null" and old or plus
                -- the first parse runs inside the diff's own FileType autocmd, where match()
                -- gives up on the extensions it sniffs the content of (.sh): did_filetype()
                -- guards them. The bare extension still names most of their languages
                ft = vim.filetype.match({ filename = file }) or file:match("%.(%w+)$")
            end
            fts[i] = ft
        end
        last = { buf = buf, tick = tick, fts = fts }
    end
    return last.fts
end

vim.treesitter.query.add_directive("diff-code!", function(match, _, source, pred, metadata)
    -- a diff parsed from a string has no buffer to read the headers from
    if type(source) ~= "number" then
        return
    end
    local id = pred[2]
    local row = match[id][1]:start()
    metadata["injection.language"] = filetypes(source)[row + 1]
    -- the line without its +/-/space column, and with its newline: without it the lines of a
    -- side run together and a // comment swallows the rest of the side
    metadata[id] = metadata[id] or {}
    metadata[id].range = { row, 1, row + 1, 0 }
end, { force = true }) -- :Reload sources this file again
