-- Bookmarks on `s`: files pinned to single chars, then the open buffers,
-- through fzf-pin's picker. Pins are per-project (cwd) and survive restarts;
-- a free char pins the current file, ctrl-x unpins a pin or deletes a buffer.
return {
    dir = vim.fn.expand("~/personal/fzf-pin.nvim"),
    dependencies = { "ibhagwan/fzf-lua" },
    config = function()
        -- one store file per project (cwd, / encoded as % like nv's sockets):
        -- each per-project server only ever touches its own pins
        local function ns()
            return "bookmarks/" .. vim.fn.getcwd():gsub("/", "%%")
        end

        local function pins()
            return require("fzf-pin.store").load(ns())
        end

        local function save(project)
            require("fzf-pin.store").save(ns(), project)
        end

        local function list()
            local items, pinned = {}, {}
            local project = pins()
            local chars = vim.tbl_keys(project)
            table.sort(chars)
            for _, c in ipairs(chars) do
                pinned[project[c]] = true
                table.insert(items, {
                    label = vim.fn.fnamemodify(project[c], ":~:."),
                    char = c,
                    data = project[c],
                })
            end
            for _, b in ipairs(vim.api.nvim_list_bufs()) do
                local name = vim.api.nvim_buf_get_name(b)
                if vim.bo[b].buflisted and name ~= "" and not pinned[name] then
                    table.insert(items, {
                        label = vim.fn.fnamemodify(name, ":~:."),
                        data = name,
                        buf = b,
                    })
                end
            end
            return items
        end

        local source = {
            prompt = "buffers> ",
            list = list,
            activate = function(item)
                vim.cmd.edit(vim.fn.fnameescape(item.data))
            end,
            pin = function(char)
                local name = vim.api.nvim_buf_get_name(0)
                if name == "" then
                    vim.notify("pins: current buffer has no file", vim.log.levels.WARN)
                    return
                end
                local project = pins()
                for c, path in pairs(project) do
                    if path == name then
                        vim.notify("pins: already on " .. c .. " (ctrl-x it to move)",
                            vim.log.levels.WARN)
                        return
                    end
                end
                project[char] = name
                save(project)
                vim.notify(("pinned %s to %s"):format(vim.fn.fnamemodify(name, ":~:."), char))
            end,
            unpin = function(item)
                if item.char then
                    local project = pins()
                    project[item.char] = nil
                    save(project)
                else
                    -- unpinned entries are plain open buffers: ctrl-x closes,
                    -- same as fzf-lua's buffers picker
                    vim.api.nvim_buf_delete(item.buf, {})
                end
                return true
            end,
        }

        vim.keymap.set("n", "s", function()
            require("fzf-pin").pick(source)
        end, { desc = "pinned files + buffers" })
    end,
}
