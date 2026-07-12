-- :CopyLoc -- yank the cursor's absolute path:line to the + register, for
-- pasting into a terminal agent (claude) or anywhere a plain location is wanted.
-- A visual range yields path:line1-line2.

vim.api.nvim_create_user_command("CopyLoc", function(o)
    local fname = vim.api.nvim_buf_get_name(0)
    if fname == "" then
        vim.notify("no file in this buffer", vim.log.levels.WARN)
        return
    end
    local line1 = o.line1
    local line2 = o.line2
    local loc
    if line2 and line2 ~= line1 then
        loc = ("%s:%d-%d"):format(fname, line1, line2)
    else
        loc = ("%s:%d"):format(fname, line1)
    end
    vim.fn.setreg("+", loc)
    vim.notify(loc)
end, { range = true, desc = "copy absolute path:line to clipboard" })
