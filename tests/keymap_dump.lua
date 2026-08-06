-- What is this key already bound to? The headless twin of <leader>y.
--
--   nvim --headless -u init.lua -l tests/keymap_dump.lua            # everything
--   nvim --headless -u init.lua -l tests/keymap_dump.lua '<leader>g'
--   nvim --headless -u init.lua -l tests/keymap_dump.lua 'g' n      # normal mode only
--
-- Only global maps exist at this point: the buffer-local ones (LspAttach in
-- lua/plugins/lspconfig.lua, the layer modes) register on events that never
-- fire here, so they are not listed and cannot be.

local prefix = arg[1] or ""
local modes = arg[2] and { arg[2] } or { "n", "i", "v", "x", "s", "o", "t", "c" }

-- <leader> is not a termcode, so expand it before nvim_replace_termcodes.
prefix = prefix:gsub("<[lL]eader>", vim.g.mapleader or "\\")
prefix = vim.api.nvim_replace_termcodes(prefix, true, true, true)

local function where(map)
    local info = map.sid and vim.fn.getscriptinfo({ sid = map.sid })[1]
    if not info then return "" end
    return ("%s:%d"):format(vim.fn.fnamemodify(info.name, ":~"), map.lnum or 0)
end

local rows = {}
for _, mode in ipairs(modes) do
    for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
        if vim.startswith(map.lhs, prefix) then
            table.insert(rows, {
                mode = mode,
                lhs = vim.fn.keytrans(map.lhs),
                what = map.desc or (map.rhs ~= "" and map.rhs) or "<lua>",
                at = where(map),
            })
        end
    end
end

table.sort(rows, function(a, b)
    if a.lhs == b.lhs then return a.mode < b.mode end
    return a.lhs < b.lhs
end)

for _, row in ipairs(rows) do
    print(("%-2s %-22s %-44s %s"):format(row.mode, row.lhs, row.what, row.at))
end
print(("-- %d mapping(s)"):format(#rows))
