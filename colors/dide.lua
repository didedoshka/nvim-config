local colors = {
    white = '#FFFFFF',
    black = '#000000',

    -- This color is not part of `ayu` but matches the default style applied in VSCode.
    lsp_inlay_hint = '#969696',

    accent = '#000000',
    bg = '#FFFFFF',
    fg = '#000000',
    ui = '#8A9199',

    tag = '#000000',
    func = '#000000',
    entity = '#000000',
    string = '#000000',
    regexp = '#000000',
    markup = '#000000',
    keyword = '#000000',
    special = '#000000',
    comment = '#000000',
    constant = '#000000',
    operator = '#000000',
    error = '#000000',
    lsp_parameter = '#000000',

    line = '#E7EAED',
    panel_bg = '#F3F4F5',
    panel_shadow = '#D3D4D5',
    panel_border = '#F0F0F0',
    gutter_normal = '#CCCFD3',
    gutter_active = '#A0A6AC',
    -- selection_bg = '#D3E1F5',
    selection_inactive = '#FF0000',
    selection_border = '#E1E1E2',
    -- guide_active = '#D2D5D8',
    guide_normal = '#000000',

    vcs_added = '#6CBF43',
    vcs_modified = '#478ACC',
    vcs_removed = '#FF7383',

    vcs_added_bg = '#E0E7CD',
    vcs_removed_bg = '#F9EBE4',

    fg_idle = '#8A9199',
    warning = '#FA8D3E',
}


--- Apply groups highlighting.
local function set_groups()
    local groups = {
        -- Base.
        Normal = { fg = colors.fg, bg = colors.bg },
        NormalFloat = { bg = colors.bg },
        FloatBorder = { fg = colors.comment },
        FloatTitle = { fg = colors.fg },
        ColorColumn = { bg = colors.line },
        Cursor = { fg = colors.bg, bg = colors.fg },
        CursorColumn = { bg = colors.line },
        CursorLine = { bg = colors.line },
        CursorLineNr = { fg = colors.accent, bg = colors.line },
        LineNr = { fg = colors.guide_normal },

        Directory = { fg = colors.func },
        ErrorMsg = { fg = colors.error },
        WinSeparator = { fg = colors.panel_border, bg = colors.bg },
        VertSplit = { link = 'WinSeparator' },
        Folded = { fg = colors.fg_idle, bg = colors.panel_bg },
        FoldColumn = { bg = colors.bg },
        SignColumn = { bg = colors.bg },

        MatchParen = { sp = colors.func, underline = true },
        ModeMsg = { fg = colors.string },
        MoreMsg = { fg = colors.string },
        NonText = { fg = colors.guide_normal },
        Pmenu = { fg = colors.fg, bg = colors.selection_inactive },
        PmenuSel = { fg = colors.fg, bg = colors.selection_inactive, reverse = true },
        Question = { fg = colors.string },
        Search = { fg = colors.bg, bg = colors.constant },
        CurSearch = { fg = colors.bg, bg = colors.special },
        IncSearch = { fg = colors.keyword, bg = colors.selection_inactive },
        SpecialKey = { fg = colors.selection_inactive },
        SpellCap = { sp = colors.tag, undercurl = true },
        SpellLocal = { sp = colors.keyword, undercurl = true },
        SpellBad = { sp = colors.error, undercurl = true },
        SpellRare = { sp = colors.regexp, undercurl = true },
        StatusLine = { fg = colors.fg, bg = colors.panel_bg },
        StatusLineNC = { fg = colors.fg_idle, bg = colors.panel_bg },
        WildMenu = { fg = colors.fg, bg = colors.markup },
        TabLine = { fg = colors.comment, bg = colors.panel_shadow },
        TabLineFill = { fg = colors.fg, bg = colors.panel_border },
        TabLineSel = { fg = colors.fg, bg = colors.bg },
        Title = { fg = colors.keyword },
        Visual = { bg = colors.selection_inactive },
        WarningMsg = { fg = colors.warning },

        Comment = { fg = colors.comment, italic = true },
        Constant = { fg = colors.constant },
        String = { fg = colors.string },
        Identifier = { fg = colors.entity },
        Function = { fg = colors.func },
        Statement = { fg = colors.keyword },
        Operator = { fg = colors.operator },
        Exception = { fg = colors.markup },
        PreProc = { fg = colors.accent },
        Type = { fg = colors.entity },
        Structure = { fg = colors.special },
        Special = { fg = colors.accent },
        Delimiter = { fg = colors.special },
        Underlined = { sp = colors.tag, underline = true },
        Ignore = { fg = colors.fg },
        Error = { fg = colors.white, bg = colors.error },
        Todo = { fg = colors.markup },
        qfLineNr = { fg = colors.keyword },
        qfError = { fg = colors.error },
        Conceal = { fg = colors.comment },
        CursorLineConceal = { fg = colors.guide_normal, bg = colors.line },

        Added = { fg = colors.vcs_added },
        Removed = { fg = colors.vcs_removed },
        Changed = { fg = colors.vcs_modified },
        DiffAdd = { bg = colors.vcs_added_bg },
        DiffAdded = { fg = colors.vcs_added },
        DiffDelete = { bg = colors.vcs_removed_bg },
        DiffRemoved = { fg = colors.vcs_removed },
        DiffText = { bg = colors.gutter_normal },
        DiffChange = { bg = colors.selection_inactive },

        -- LSP.
        DiagnosticError = { fg = colors.error },
        DiagnosticWarn = { fg = colors.keyword },
        DiagnosticInfo = { fg = colors.tag },
        DiagnosticHint = { fg = colors.regexp },

        DiagnosticUnderlineError = { sp = colors.error, undercurl = true },
        DiagnosticUnderlineWarn = { sp = colors.keyword, undercurl = true },
        DiagnosticUnderlineInfo = { sp = colors.tag, undercurl = true },
        DiagnosticUnderlineHint = { sp = colors.regexp, undercurl = true },

        -- Markdown.
        markdownCode = { fg = colors.special },

        -- TreeSitter.
        ['@property'] = { fg = colors.tag },
        ['@tag'] = { fg = colors.keyword },
        ['@tag.attribute'] = { fg = colors.entity },
        ['@tag.delimiter'] = { link = 'Delimiter' },
        ['@type.qualifier'] = { fg = colors.keyword },
        ['@variable'] = { fg = colors.fg },
        ['@variable.builtin'] = { fg = colors.func },
        ['@variable.member'] = { fg = colors.tag },
        ['@variable.parameter'] = { fg = colors.fg },
        ['@module'] = { fg = colors.func },
        ['@markup.heading'] = { fg = colors.keyword },
        ['@keyword.storage'] = { fg = colors.keyword },

        ['@lsp.type.namespace'] = { link = '@module' },
        ['@lsp.type.type'] = { link = '@type' },
        ['@lsp.type.class'] = { link = '@type' },
        ['@lsp.type.enum'] = { link = '@type' },
        ['@lsp.type.interface'] = { link = '@type' },
        ['@lsp.type.struct'] = { link = '@variable.member' },
        ['@lsp.type.parameter'] = { fg = colors.lsp_parameter },
        ['@lsp.type.field'] = { link = '@variable.member' },
        ['@lsp.type.variable'] = { link = '@variable' },
        ['@lsp.type.property'] = { link = '@property' },
        ['@lsp.type.enumMember'] = { link = '@constant' },
        ['@lsp.type.function'] = { link = '@function' },
        ['@lsp.type.method'] = { link = '@function.method' },
        ['@lsp.type.macro'] = { link = '@function.macro' },
        ['@lsp.type.decorator'] = { link = '@function' },
        ['@lsp.mod.constant'] = { link = '@constant' },

        -- TreesitterContext.
        TreesitterContext = { bg = colors.selection_inactive },

        -- Telescope.
        TelescopePromptBorder = { fg = colors.accent },

        -- Cmp.
        CmpGhostText = { fg = colors.comment },
        CmpItemAbbrMatch = { fg = colors.keyword },
        CmpItemAbbrMatchFuzzy = { fg = colors.func },
        CmpItemKindText = { fg = colors.string },
        CmpItemKindMethod = { fg = colors.keyword },
        CmpItemKindFunction = { fg = colors.func },
        CmpItemKindConstructor = { fg = colors.keyword },
        CmpItemKindField = { fg = colors.entity },
        CmpItemKindVariable = { fg = colors.tag },
        CmpItemKindClass = { fg = colors.entity },
        CmpItemKindInterface = { fg = colors.entity },
        CmpItemKindModule = { fg = colors.keyword },
        CmpItemKindProperty = { fg = colors.keyword },
        CmpItemKindUnit = { fg = colors.constant },
        CmpItemKindValue = { fg = colors.constant },
        CmpItemKindEnum = { fg = colors.entity },
        CmpItemKindKeyword = { fg = colors.keyword },
        CmpItemKindSnippet = { fg = colors.regexp },
        CmpItemKindColor = { fg = colors.special },
        CmpItemKindFile = { fg = colors.special },
        CmpItemKindReference = { fg = colors.special },
        CmpItemKindFolder = { fg = colors.special },
        CmpItemKindEnumMember = { fg = colors.constant },
        CmpItemKindConstant = { fg = colors.constant },
        CmpItemKindStruct = { fg = colors.entity },
        CmpItemKindEvent = { fg = colors.tag },
        CmpItemKindOperator = { fg = colors.operator },
        CmpItemKindTypeParameter = { fg = colors.tag },
        CmpItemMenu = { fg = colors.comment },

        -- Word under cursor.
        CursorWord = { bg = colors.selection_inactive },
        CursorWord0 = { bg = colors.selection_inactive },
        CursorWord1 = { bg = colors.selection_inactive },


        -- WhichKey.
        WhichKeyFloat = { bg = colors.bg },

        -- Leap.
        LeapMatch = { fg = colors.regexp, underline = true },
        LeapLabelPrimary = { fg = colors.bg, bg = colors.regexp },
        LeapLabelSecondary = { fg = colors.bg, bg = colors.entity },
        LeapLabelSelected = { fg = colors.bg, bg = colors.tag },

        -- LSP Inlay Hints.
        LspInlayHint = { fg = colors.lsp_inlay_hint },

        -- LSP Signature.
        LspSignatureActiveParameter = { italic = true },

        -- Dap.
        NvimDapVirtualText = { fg = colors.regexp },

        -- DAP UI.
        DapUIScope = { fg = colors.func },
        DapUIType = { fg = colors.entity },
        DapUIDecoration = { fg = colors.tag },
        DapUIThread = { fg = colors.string },
        DapUIStoppedThread = { fg = colors.special },
        DapUISource = { fg = colors.regexp },
        DapUILineNumber = { fg = colors.constant },
        DapUIFloatBorder = { fg = colors.panel_border },
        DapUIWatchesEmpty = { fg = colors.warning },
        DapUIWatchesValue = { fg = colors.string },
        DapUIWatchesError = { fg = colors.error },
        DapUIBreakpointsPath = { fg = colors.regexp },
        DapUIBreakpointsInfo = { fg = colors.constant },
        DapUIBreakpointsCurrentLine = { fg = colors.constant, bold = true },
    }

    for group, parameters in pairs(groups) do
        vim.api.nvim_set_hl(0, group, parameters)
    end
end

--- Set the colorscheme.
vim.api.nvim_command('hi clear')
if vim.fn.exists('syntax_on') then
    vim.api.nvim_command('syntax reset')
end

vim.o.termguicolors = true
vim.g.colors_name = 'dide'

set_groups()

local function oklab_to_linear_srgb(color)
    local l_ = color.L + 0.3963377774 * color.a + 0.2158037573 * color.b
    local m_ = color.L - 0.1055613458 * color.a - 0.0638541728 * color.b
    local s_ = color.L - 0.0894841775 * color.a - 1.2914855480 * color.b

    local l = l_ * l_ * l_
    local m = m_ * m_ * m_
    local s = s_ * s_ * s_

    return {
        r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
        g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
        b = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
    }
end

local function linear_srgb_to_srgb(x)
    if x >= 0.0031308 then
        return (1.055) * x ^ (1.0 / 2.4) - 0.055
    else
        return 12.92 * x
    end
end

local function oklab_to_srgb(color)
    local linear_srgb = oklab_to_linear_srgb(color)
    return {
        r = linear_srgb_to_srgb(linear_srgb.r),
        g = linear_srgb_to_srgb(linear_srgb.g),
        b = linear_srgb_to_srgb(linear_srgb.b),
    }
end

local function linear_srgb_to_oklab(color)
    local l = 0.4122214708 * color.r + 0.5363325363 * color.g + 0.0514459929 * color.b
    local m = 0.2119034982 * color.r + 0.6806995451 * color.g + 0.1073969566 * color.b
    local s = 0.0883024619 * color.r + 0.2817188376 * color.g + 0.6299787005 * color.b

    local l_ = l ^ (1 / 3)
    local m_ = m ^ (1 / 3)
    local s_ = s ^ (1 / 3)

    return {
        L = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
        a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
        b = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_,
    }
end

local function srgb_to_linear_srgb(x)
    if x >= 0.04045 then
        return ((x + 0.055) / (1 + 0.055)) ^ 2.4
    else
        return x / 12.92
    end
end

local function srgb_to_oklab(color)
    local linear_srgb = {
        r = srgb_to_linear_srgb(color.r),
        g = srgb_to_linear_srgb(color.g),
        b = srgb_to_linear_srgb(color.b),
    }
    return linear_srgb_to_oklab(linear_srgb)
end

local function string_to_srgb(color)
    local result = {}

    result.r = tonumber(string.sub(color, 2, 3), 16) / 255
    result.g = tonumber(string.sub(color, 4, 5), 16) / 255
    result.b = tonumber(string.sub(color, 6, 7), 16) / 255

    return result
end


local function srgb_to_string(color)
    print(color.r)
    print(color.g)
    print(color.b)
    return string.format("#%x\n%x\n%x\n", color.r * 255, color.g * 255, color.b * 255)
end

local function check()
    color = "#ffce00"
    rgb1 = string_to_srgb(color)
    vim.print(rgb1)
    oklab = srgb_to_oklab(rgb1)
    vim.print(oklab)
    rgb2 = oklab_to_srgb(oklab)
    vim.print(rgb2)
end

-- check()

local semantic_highlighting_colors = {"#ff0000", "#00ff00", "#0000ff"}

local function get_color_number(token, buf)
    local line = vim.api.nvim_buf_get_lines(buf, token.line, token.line + 1, true)[1]
    local varname = string.sub(line, token.start_col + 1, token.end_col)
    local p = 259
    local mod = 1000000009
    local hash = 0
    for i = 1, string.len(varname) do
        hash = ((hash * p) % mod + string.byte(varname, i)) % mod
    end
    return hash % #semantic_highlighting_colors
end

local considered_variable = {
    "variable", "type", "property", "type.builtin" }

local function start_semantic_highlighting()
    vim.api.nvim_set_hl(0, 'VarName0', { fg = '#cca650' })
    vim.api.nvim_set_hl(0, 'VarName1', { fg = '#50a6fe' })
    vim.api.nvim_set_hl(0, 'VarName2', { fg = '#ffa6fe' })
    vim.api.nvim_set_hl(0, 'VarName3', { fg = '#ffc66b' })
    vim.api.nvim_set_hl(0, 'VarName4', { fg = '#c600ff' })
    vim.api.nvim_set_hl(0, 'VarName5', { fg = '#aaffaa' })
    vim.api.nvim_set_hl(0, 'VarName6', { fg = '#bbbbbb' })
    vim.api.nvim_set_hl(0, 'VarName7', { fg = '#00ff44' })
    vim.api.nvim_set_hl(0, 'VarName8', { fg = '#009900' })
    vim.api.nvim_set_hl(0, 'VarName9', { fg = '#995500' })
    vim.api.nvim_set_hl(0, 'VarName10', { fg = '#3355aa' })
    vim.api.nvim_set_hl(0, 'VarName11', { fg = '#009977' })
    vim.api.nvim_set_hl(0, 'VarName12', { fg = '#bbbb00' })
    vim.api.nvim_set_hl(0, 'VarName13', { fg = '#66ffff' })
    vim.api.nvim_set_hl(0, 'VarName14', { fg = '#ff9999' })
    vim.api.nvim_set_hl(0, 'VarName15', { fg = '#ffff66' })
    vim.api.nvim_create_autocmd("LspTokenUpdate", {
        callback = function(args)
            local token = args.data.token
            local buf = args.buf
            local client_id = args.data.client_id
            if vim.tbl_contains(considered_variable, token.type) then
                vim.lsp.semantic_tokens.highlight_token(
                    token, buf, client_id,
                    "VarName" .. get_color_number(token, buf)
                )
            end
        end
    })
end

local parsers = {}
local ns = vim.api.nvim_create_namespace('SemanticHighlighting')
local queries = {}
local supported_languages = { "lua", "c", "cpp", "python" }

local function colorize(bufnr, lang, start_row, end_row)
    parsers[bufnr]:parse(
        { start_row, end_row },
        function(err, trees)
            vim.schedule(function()
                vim.api.nvim_buf_clear_namespace(bufnr, ns, start_row, end_row)
                local tree = trees[1]
                for pattern, match, metadata in queries[lang]:iter_matches(tree:root(), 0, start_row, end_row) do
                    for id, nodes in pairs(match) do
                        local name = queries[lang].captures[id]
                        if vim.tbl_contains(considered_variable, name) then
                            for _, node in ipairs(nodes) do
                                local node_start_row, node_start_col, node_end_row, node_end_col = node:range()
                                local variable = vim.api.nvim_buf_get_text(bufnr, node_start_row, node_start_col, node_end_row, node_end_col, {})
                                vim.api.nvim_buf_set_extmark(bufnr, ns, node_start_row, node_start_col,
                                    { end_row = node_end_row, end_col = node_end_col, hl_group = "String", priority = 200, strict = false })
                            end
                        end
                    end
                end
            end)
        end
    )
end

local function start_treesitter_semantic_highlighting(bufnr, lang)
    for i, color in ipairs(semantic_highlighting_colors) do
        vim.api.nvim_set_hl(0, 'SemanticHighlightingColor' .. i, { fg = color })
    end

    parsers[bufnr] = vim.treesitter.get_parser(bufnr, lang)
    queries[lang] = vim.treesitter.query.get(parsers[bufnr]:lang(), "highlights")

    colorize(bufnr, lang, 0, -1)

    parsers[bufnr]:register_cbs({
        on_bytes = function(buffer_id, changed_tick, start_row, start_col, byte_offset, old_end_row, old_end_col,
                            old_end_byte, new_end_row, new_end_col, new_end_byte)
            colorize(bufnr, lang, start_row, start_row + new_end_row + 1)
        end
    })
end

local sh_augroup = vim.api.nvim_create_augroup("SemanticHighlighting", {})
vim.api.nvim_create_autocmd('FileType', {
    group = sh_augroup,
    callback = function(args)
        local lang = vim.treesitter.language.get_lang(args.match)
        if not vim.tbl_contains(supported_languages, lang) then
            return
        end
        local bufnr = args.buf

        print("Starting semantic highlighting for ", lang, " in buffer ", bufnr)

        start_treesitter_semantic_highlighting(bufnr, lang)
    end
})
--
-- vim.keymap.set("n", "<bs><bs>", treesitter_try)
-- vim.hl.range(0, vim.api.nvim_create_namespace(''), "String", { 467, 0 }, { 467, 5 }, { priority = 200 })
