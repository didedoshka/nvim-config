local colors = {
    bg           = '#FFFFFF',
    fg           = '#2d2d2d',
    -- gray         = "#e5e5e5",
    gray         = "#f3f3f3",
}
return {
    normal = {
        a = { bg = colors.fg, fg = colors.bg, gui = 'bold' },
        b = { bg = colors.gray, fg = colors.fg },
        c = { bg = colors.gray, fg = colors.fg }
        -- a = { bg = colors.fg, fg = colors.bg, gui = 'bold' },
        -- b = { bg = colors.bg, fg = colors.fg },
        -- c = { bg = colors.bg, fg = colors.fg }
    },
}
