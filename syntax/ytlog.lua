-- YTsaurus server log highlighting. Each line is tab-separated:
--   <timestamp>\t<level>\t<category>\t<message>\t<thread>\t<trace-id>
-- The metadata (timestamp / thread / trace-id) is dimmed and the level drives
-- the colour, reusing the Diagnostic* groups so it tracks the colourscheme.
if vim.b.current_syntax then
    return
end

local cmd = vim.cmd

-- Parse the line as a chain anchored at its start and threaded field to field
-- with `nextgroup ... skipwhite` (the tab between fields counts as whitespace).
-- This keeps every item either ^-anchored (tried once per line) or `contained`
-- (tried only at the handoff point), so the engine never rescans the line. The
-- previous version leaned on variable-width lookbehinds (\@<=), which Vim retries
-- at every column; on YT's very long message field that is quadratic and made
-- scrolling crawl.

-- level letter -> display name + severity bucket. The bucket routes the category
-- and message fields to their tinted variant, so only warnings/errors stand out.
local levels = {
    { "T", "Trace", "Plain" },
    { "D", "Debug", "Plain" },
    { "I", "Info",  "Plain" },
    { "W", "Warn",  "Warn"  },
    { "E", "Error", "Err"   },
    { "F", "Fatal", "Err"   },
    { "A", "Alert", "Err"   },
}

local level_groups = {}
for _, lv in ipairs(levels) do
    level_groups[#level_groups + 1] = "ytlogLevel" .. lv[2]
end

-- field 1: timestamp, the only line-anchored item; it kicks off the chain
cmd(("syntax match ytlogTime /\\v^\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2},\\d+/ nextgroup=%s skipwhite")
    :format(table.concat(level_groups, ",")))

-- field 2: the single level char routes to its severity's category
for _, lv in ipairs(levels) do
    cmd(("syntax match ytlogLevel%s /%s/ contained nextgroup=ytlogCat%s skipwhite")
        :format(lv[2], lv[1], lv[3]))
end

-- fields 3 & 4: category then message, one pair per severity bucket
for _, sev in ipairs({ "Plain", "Warn", "Err" }) do
    cmd(("syntax match ytlogCat%s /[^\\t]\\+/ contained nextgroup=ytlogMsg%s skipwhite"):format(sev, sev))
    cmd(("syntax match ytlogMsg%s /[^\\t]\\+/ contained nextgroup=ytlogThread skipwhite"):format(sev))
end

-- fields 5 & 6: thread then the 16-hex trace id at end of line
cmd([[syntax match ytlogThread /[^\t]\+/ contained nextgroup=ytlogTrace skipwhite]])
cmd([[syntax match ytlogTrace  /[0-9a-f]\+\s*$/ contained]])

-- lines are self-contained, so never scan back further than one line to redraw
cmd([[syntax sync minlines=1 maxlines=1]])

cmd([[
    highlight default link ytlogMsgWarn  DiagnosticWarn
    highlight default link ytlogMsgErr   DiagnosticError

    highlight default link ytlogTime     Comment
    highlight default link ytlogThread   Comment
    highlight default link ytlogTrace    Comment

    highlight default link ytlogCatPlain Operator
    highlight default link ytlogCatWarn  Operator
    highlight default link ytlogCatErr   Operator

    highlight default link ytlogLevelTrace Comment
    highlight default link ytlogLevelDebug NonText
    highlight default link ytlogLevelInfo  DiagnosticInfo
    highlight default link ytlogLevelWarn  DiagnosticWarn
    highlight default link ytlogLevelError DiagnosticError
    highlight default link ytlogLevelFatal Error
    highlight default link ytlogLevelAlert Error
]])

vim.b.current_syntax = "ytlog"
