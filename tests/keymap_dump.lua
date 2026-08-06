-- What is this key already bound to? The headless twin of <leader>y.
--
--   nvim --headless -u init.lua -l tests/keymap_dump.lua            # everything
--   nvim --headless -u init.lua -l tests/keymap_dump.lua '<leader>g'
--   nvim --headless -u init.lua -l tests/keymap_dump.lua 'g' n      # normal mode only
--
-- Buffer-local maps are marked `buf`. To get the LspAttach ones (lspconfig.lua)
-- to exist at all, this attaches a stub language server to a scratch buffer --
-- a real client, so `client.server_capabilities` gates open and the whole
-- handler runs. The stub advertises inlayHint and documentSymbol because
-- several keymaps hang off exactly those two capabilities.
--
-- Still missing, and not fixable from here: maps that only exist inside a layer
-- mode (litre, debug mode), and clangd's own on_attach, which needs clangd.

local prefix = arg[1] or ""
local modes = arg[2] and { arg[2] } or { "n", "i", "v", "x", "s", "o", "t", "c" }

-- <leader> is not a termcode, so expand it before nvim_replace_termcodes.
prefix = prefix:gsub("<[lL]eader>", vim.g.mapleader or "\\")
prefix = vim.api.nvim_replace_termcodes(prefix, true, true, true)

-- A language server that speaks just enough to attach. `cmd` as a function
-- keeps it in-process: no executable, no stdio, nothing to clean up.
local function stub(_)
    local closing = false
    return {
        request = function(method, _, handler)
            if method == "initialize" then
                handler(nil, { capabilities = {
                    inlayHintProvider = true,
                    documentSymbolProvider = true,
                } })
            else
                handler(nil, nil)
            end
            return true, 1
        end,
        notify = function() return true end,
        is_closing = function() return closing end,
        terminate = function() closing = true end,
    }
end

local lsp_buf = vim.api.nvim_create_buf(false, true)
vim.lsp.start({ name = "keymap_dump", cmd = stub }, { bufnr = lsp_buf })
if not vim.wait(2000, function() return #vim.lsp.get_clients({ bufnr = lsp_buf }) > 0 end) then
    print("-- warning: stub LSP never attached; buffer-local maps are missing")
end

local function where(map)
    local info = map.sid and vim.fn.getscriptinfo({ sid = map.sid })[1]
    if not info then return "" end
    return ("%s:%d"):format(vim.fn.fnamemodify(info.name, ":~"), map.lnum or 0)
end

local rows = {}
local function collect(maps, mode, scope)
    for _, map in ipairs(maps) do
        if vim.startswith(map.lhs, prefix) then
            table.insert(rows, {
                mode = mode,
                scope = scope,
                lhs = vim.fn.keytrans(map.lhs),
                what = map.desc or (map.rhs ~= "" and map.rhs) or "<lua>",
                at = where(map),
            })
        end
    end
end

for _, mode in ipairs(modes) do
    collect(vim.api.nvim_get_keymap(mode), mode, "")
    collect(vim.api.nvim_buf_get_keymap(lsp_buf, mode), mode, "buf")
end

table.sort(rows, function(a, b)
    if a.lhs == b.lhs then return a.mode < b.mode end
    return a.lhs < b.lhs
end)

for _, row in ipairs(rows) do
    print(("%-2s %-3s %-22s %-44s %s"):format(row.mode, row.scope, row.lhs, row.what, row.at))
end
print(("-- %d mapping(s)"):format(#rows))
