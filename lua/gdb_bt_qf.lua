local M = {}

M.config = {
    root = vim.fn.expand("~/arc"),
    open_qf = true,
}

local function normalize_path(path, root)
    -- GDB emits paths with a source-substitution prefix, e.g.:
    --   /-S/yt/yt/foo.cpp
    --   /-S/contrib/foo.h
    --
    -- Real path is:
    --   ~/arc/yt/yt/foo.cpp
    --   ~/arc/contrib/foo.h
    --
    -- Strip the leading "/-S" (or similar "/-X") substitution marker, then
    -- anchor the remaining absolute path under the configured source root.

    path = path:gsub("^/%-%w+", "")

    if path:sub(1, 1) == "/" then
        return root .. path
    end

    return path
end

local function parse_gdb_frame(text, opts)
    -- `text` is a single logical frame, with any wrapped continuation lines
    -- already joined into one string. Match:
    --   #0  func (...) at /path/file.cpp:123
    --   #1  0xabc in func (...) at /path/file.cpp:123
    --
    -- We intentionally do not parse the function signature deeply.
    -- We only care about:
    --   frame number
    --   file
    --   line
    --
    -- The location is always the trailing "at <file>:<line>". `<file>` never
    -- contains whitespace, so we anchor on the last such token.

    local frame, before = text:match("^#(%d+)%s+(.-)%s+at%s+%S+:%d+%s*$")
    local file, lnum = text:match("at%s+(%S+):(%d+)%s*$")

    if not frame or not file then
        return nil
    end

    local filename = normalize_path(file, opts.root)

    return {
        filename = filename,
        lnum = tonumber(lnum),
        col = 1,
        nr = tonumber(frame),
        text = ("#%s %s"):format(frame, (before:gsub("%s+", " "))),
        valid = 1,
    }
end

local function group_frames(lines)
    -- GDB wraps long frames across several physical lines. A new frame starts
    -- with "#<n>"; every following line that does not is a continuation and
    -- belongs to the current frame.

    local frames = {}
    local current = nil

    for _, line in ipairs(lines) do
        if line:match("^#%d+%s") or line:match("^#%d+$") then
            if current then
                table.insert(frames, current)
            end
            current = line
        elseif current then
            current = current .. " " .. line:gsub("^%s+", "")
        end
    end

    if current then
        table.insert(frames, current)
    end

    return frames
end

function M.lines_to_qf(lines, opts)
    opts = vim.tbl_deep_extend("force", M.config, opts or {})

    local items = {}

    for _, frame_text in ipairs(group_frames(lines)) do
        local item = parse_gdb_frame(frame_text, opts)
        if item then
            table.insert(items, item)
        end
    end

    vim.fn.setqflist({}, "r", {
        title = "GDB backtrace",
        items = items,
    })

    if opts.open_qf then
        vim.cmd("copen")
    end

    vim.notify(
        ("Loaded %d GDB frame(s) into quickfix"):format(#items),
        vim.log.levels.INFO
    )
end

function M.buffer_to_qf(opts)
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    M.lines_to_qf(lines, opts)
end

function M.selection_to_qf(opts)
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")

    local start_line = start_pos[2] - 1
    local end_line = end_pos[2]

    local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line, false)
    M.lines_to_qf(lines, opts)
end

function M.setup(opts)
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})

    vim.api.nvim_create_user_command("GdbBtQf", function()
        M.buffer_to_qf()
    end, {
        desc = "Parse current buffer as GDB backtrace into quickfix",
    })

    vim.api.nvim_create_user_command("GdbBtQfSelection", function()
        M.selection_to_qf()
    end, {
        range = true,
        desc = "Parse selected GDB backtrace into quickfix",
    })
end

return M
