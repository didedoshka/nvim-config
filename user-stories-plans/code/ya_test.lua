-- PROPOSED new file: plugin/ya_test.lua  (story 02)
--
-- After `ya make -A --pytest-args=...`, jump straight to a test's stdout/logs
-- instead of cd-ing down a very long test-results path.
--
--   :YaTestOut   fuzzy-open files under the nearest test-results/**/testing_out_stuff
--   :YaTestGrep  live-grep within that same dir (e.g. http-proxy-log.debug.log)
--
-- NOTE ON THE ~/arc RULE: never rg/scan the arcadia VFS source tree. This module
-- only ever points fzf-lua at a single `testing_out_stuff` directory, which is
-- materialized local build output (small, bounded) -- not the VFS source tree.

local M = {}

-- nearest ancestor dir that has a `test-results` child
local function results_root()
    local start = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
    if start == "" then start = vim.fn.getcwd() end
    return vim.fs.find("test-results", { path = start, upward = true, type = "directory" })[1]
end

-- testing_out_stuff dirs (one per test type) under test-results/
local function out_dirs(tr)
    local dirs = {}
    for name, t in vim.fs.dir(tr) do
        if t == "directory" then
            local candidate = tr .. "/" .. name .. "/testing_out_stuff"
            if vim.fn.isdirectory(candidate) == 1 then
                dirs[#dirs + 1] = candidate
            end
        end
    end
    return dirs
end

local function pick_out_dir(cb)
    local tr = results_root()
    if not tr then
        vim.notify("no test-results dir found upward", vim.log.levels.WARN)
        return
    end
    local dirs = out_dirs(tr)
    if #dirs == 0 then
        vim.notify("no testing_out_stuff under " .. tr, vim.log.levels.WARN)
        return
    end
    if #dirs == 1 then
        cb(dirs[1])
        return
    end
    vim.ui.select(dirs, { prompt = "test output dir: " }, function(c) if c then cb(c) end end)
end

vim.api.nvim_create_user_command("YaTestOut", function()
    pick_out_dir(function(d) require("fzf-lua").files({ cwd = d }) end)
end, { desc = "browse ya test output (stdout/logs)" })

vim.api.nvim_create_user_command("YaTestGrep", function()
    pick_out_dir(function(d) require("fzf-lua").live_grep_native({ cwd = d }) end)
end, { desc = "grep ya test logs" })

return M
