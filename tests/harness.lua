-- Minimal assertion harness. No framework, no dependencies: `test()` runs a
-- function, catches the error, and remembers whether it failed; `finish()`
-- prints a summary and exits non-zero if anything did.

local M = { failed = 0, passed = 0 }

-- The config notifies freely (`:CopyLoc`, gdb_bt_qf, ...). Tests assert on the
-- result rather than the message, so drop them and keep the output pass/fail.
-- Keep vim.notify's real arity here: lua_ls infers the type of a field from
-- every assignment it sees, so a bare `function() end` teaches the whole
-- workspace that vim.notify takes no arguments and flags every real call.
function M.quiet()
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.notify = function(_msg, _level, _opts) end
end

function M.test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        M.passed = M.passed + 1
    else
        M.failed = M.failed + 1
        io.stderr:write(("  FAIL  %s\n         %s\n"):format(name, tostring(err)))
    end
end

function M.ok(value, msg)
    if not value then
        error(msg or ("expected a truthy value, got " .. vim.inspect(value)), 2)
    end
end

function M.eq(got, want, msg)
    if not vim.deep_equal(got, want) then
        error(("%sexpected %s, got %s"):format(
            msg and (msg .. ": ") or "", vim.inspect(want), vim.inspect(got)), 2)
    end
end

-- Absolute path to the config root, derived from this file's own location so
-- the suite runs from any cwd.
function M.root()
    local this = debug.getinfo(1, "S").source:sub(2)
    return vim.fs.dirname(vim.fs.dirname(this))
end

function M.finish(label)
    local total = M.passed + M.failed
    if M.failed > 0 then
        io.stderr:write(("%s: %d/%d passed, %d FAILED\n"):format(label, M.passed, total, M.failed))
        os.exit(1)
    end
    -- io.stdout, not print(): under --headless, print() writes to stderr, and
    -- run.sh treats anything on stderr as a failure (init.lua errors do not
    -- change nvim's exit code, so stderr is the only signal for those).
    io.stdout:write(("%s: %d/%d passed\n"):format(label, M.passed, total))
    os.exit(0)
end

return M
