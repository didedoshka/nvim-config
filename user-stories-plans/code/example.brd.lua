-- EXAMPLE .brd.lua showing the proposed `commands` + `vars` extension (story 01).
-- Drop this at the root of a project (e.g. ~/arc/<project>/.brd.lua).
-- Existing build/run/debug targets are unchanged; `commands` and `vars` are new,
-- reserved top-level keys that brd skips when listing debug/run targets.

return {
    -- ── existing target schema (unchanged) ───────────────────────────────
    my_binary = {
        dir = "some/build/dir",
        build = "ya make -j16",
        run = "./my_binary",
        debug = { configuration = "cpp", executable = "my_binary" },
    },

    -- ── new: selectable variables / flags (the "выбор переменных" idea) ───
    -- picked once via vim.ui.select, cached, reused by any command below.
    vars = {
        release = { "releases/yt/stable/26.1", "releases/yt/stable/26.2" },
        target  = { "-A", "-L", "-tA" },
    },

    -- ── new: ad-hoc project commands, run in the brd terminal (waited) ────
    -- value is a string, a list (chained with && and waited), or a function
    -- returning either. `v` is the resolved vars table.
    commands = {
        ["ya make (choose flag)"] = function(v)
            return "ya make " .. v.target .. " -F ..."
        end,

        ["ya make -A pytest"] = 'ya make -A --pytest-args="-rP -vv --log-level=ERROR"',

        ["checkout hot cache"] = "arc checkout app/build-cache/hot",

        ["checkout release"] = function(v)
            return "arc checkout " .. v.release
        end,

        -- the "merge to release" no-brain chain: three waited commands, stop on
        -- failure. cherry-pick / submit stay interactive in the real terminal.
        ["merge to release"] = function(v)
            local commit = vim.fn.input("commit to cherry-pick: ")
            local name   = vim.fn.input("PR name: ")
            return {
                "arc checkout " .. v.release,
                "arc cherry-pick " .. commit,
                'arc submit -m "[26.1] ' .. name .. '"',
            }
        end,
    },
}
