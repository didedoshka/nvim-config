return
{
    -- fork of MironPascalCaseFan/debugmaster.nvim; dev=true picks the
    -- ~/personal checkout when present, github clone otherwise
    "didedoshka/debugmaster.nvim",
    dev = true,
    dependencies = { "mfussenegger/nvim-dap", },
    config = function()
        local dm = require("debugmaster")
        local dap = require("dap")

        -- Must precede the debugmaster.state require below: loading state
        -- builds the help panel, which resolves the scheme and freezes it.
        dm.cfg.keymaps = "gdb"

        local state = require("debugmaster.state")
        state.sidepanel.direction = "below"

        dm.plugins.ui_auto_toggle.enabled = false

        -- No <bs>{key} one-shots: any mapping under <bs> would make a lone <bs>
        -- wait out timeoutlen before toggling. Sticky mode instead -- cheaper
        -- for a stepping run, one extra <Esc> for a drive-by command.
        vim.keymap.set("n", "<bs>", dm.mode.toggle, { desc = "toggle (d)ebug mode" })
        vim.keymap.set("n", "<Esc>", dm.mode.disable, { desc = "leave debug mode" })

        vim.fn.sign_define('DapBreakpoint',
            { text = '●', texthl = 'DapBreakpoint', linehl = 'DapBreakpointLine', numhl = 'DapBreakpoint' })
        vim.fn.sign_define('DapBreakpointCondition',
            { text = '◆', texthl = 'DapBreakpoint', linehl = 'DapBreakpointLine', numhl = 'DapBreakpoint' })
        vim.fn.sign_define('DapBreakpointRejected',
            { text = '○', texthl = 'DapBreakpoint', linehl = 'DapBreakpointLine', numhl = 'DapBreakpoint' })
        vim.fn.sign_define('DapLogPoint',
            { text = '≡', texthl = 'DapLogPoint', linehl = 'DapLogPoint', numhl = 'DapLogPoint' })
        vim.fn.sign_define('DapStopped',
            { text = '→', texthl = 'DapStopped', linehl = 'DapStoppedLine', numhl = 'DapStopped' })

        -- gdb >= 14 speaks DAP itself, so no separate adapter binary is needed.
        -- `ya gdb` cannot be that gdb: its patched 17.1 build segfaults as soon
        -- as a DAP session runs the inferior (measured with a plain launch, no
        -- core, arcadia printers disabled -- so it is the build, not the
        -- python). The system gdb works, and ya gdb's pretty-printers are plain
        -- python that loads into it, so drive the former and source the latter.
        local printers = nil -- false once resolved and absent

        local function arc_printers()
            local out = vim.fn.system({ "ya", "gdb", "--print-path" })
            if vim.v.shell_error ~= 0 then
                return false
            end
            -- <tool>/bin/gdb -> <tool>/share/gdb/python/arc/__init__.py
            local py = vim.fn.fnamemodify(vim.trim(out), ":h:h") .. "/share/gdb/python/arc/__init__.py"
            return vim.uv.fs_stat(py) and py or false
        end

        dap.adapters["gdb"] = function(callback, _)
            if printers == nil then
                printers = arc_printers()
            end
            -- ~/.config/gdb/gdbinit turns per-command timing on, which under
            -- DAP becomes a flood of output events in the console.
            local args = { "-q", "-ex", "maint set per-command time off" }
            if printers then
                vim.list_extend(args, { "-ex", "source " .. printers })
            end
            -- Upstream DAP attach takes only pid/target; this adds `core`.
            vim.list_extend(args, { "-ex", "source " .. vim.fn.stdpath("config") .. "/gdb/dap_core.py" })
            -- Uninitialised locals would otherwise hang the variables request.
            vim.list_extend(args, { "-ex", "source " .. vim.fn.stdpath("config") .. "/gdb/dap_guard.py" })
            vim.list_extend(args, { "--interpreter=dap" })
            -- Sourcing the arc printers blows dap's default 4s initialize
            -- budget, which triggers a scary "adapter didn't respond" warning.
            callback({
                type = "executable",
                command = "gdb",
                args = args,
                options = { initialize_timeout_sec = 60 },
            })
        end

        -- vim.ui.input, not vim.fn.input, so replacing vim.ui.input later
        -- replaces these prompts too. The stock implementation calls back
        -- synchronously, a buffer-backed one will not -- hence the status
        -- check: resuming a coroutine that never yielded is an error.
        local function input(label, default, kind)
            local co = coroutine.running()
            local value, returned = nil, false
            vim.ui.input({ prompt = label, default = default, completion = kind }, function(v)
                value, returned = v, true
                if coroutine.status(co) == "suspended" then
                    coroutine.resume(co, v)
                end
            end)
            if returned then
                return value
            end
            return coroutine.yield()
        end

        local function ask(label, default, kind)
            return function()
                return input(label, default, kind) or ""
            end
        end

        -- No shell runs between here and the inferior, so quotes in the input
        -- would reach argv literally -- strip them instead of honouring them.
        local function ask_args()
            local args = {}
            for word in (input("Args: ") or ""):gmatch("%S+") do
                table.insert(args, (word:gsub('["\']', "")))
            end
            return args
        end

        -- `--gtest_list_tests` prints suites at column 0 ending in a dot and
        -- their tests indented under them; both may carry a trailing
        -- `# comment` (type/value parameters).
        local function gtest_list(binary)
            local out = vim.fn.system({ binary, "--gtest_list_tests" })
            if vim.v.shell_error ~= 0 then
                vim.notify(out, vim.log.levels.ERROR)
                return {}
            end
            local tests, suite = {}, nil
            for line in vim.gsplit(out, "\n") do
                local name = vim.trim(line:gsub("#.*", ""))
                if name ~= "" then
                    if line:match("^%S") then
                        suite = name
                    elseif suite then
                        table.insert(tests, suite .. name)
                    end
                end
            end
            return tests
        end

        -- Resolved inside dap's coroutine, so fzf's callback can resume it.
        local function gtest_pick(tests)
            local co = coroutine.running()
            require("fzf-lua").fzf_exec(tests, {
                prompt = "gtest_filter> ",
                fzf_opts = { ["--multi"] = true },
                actions = {
                    default = function(selected)
                        coroutine.resume(co, selected)
                    end,
                },
            })
            return coroutine.yield()
        end

        -- The project path is litre: debug("cpp", ...) in a .litre.lua names the
        -- template registered in plugins/litre.lua. These configs are the
        -- fallback for projects without one -- they ask.
        dap.configurations["cpp"] = {
            {
                name = "gdb: launch binary",
                type = "gdb",
                request = "launch",
                program = ask("Binary: ", vim.fn.getcwd() .. "/", "file"),
                args = ask_args,
                cwd = "${workspaceFolder}",
            },
            -- A callable config: dap calls it, in a coroutine, before resolving
            -- anything else, so the picker can be fed by the binary just asked
            -- for. Plain function fields could not -- dap expands them through
            -- vim.tbl_map, in no defined order.
            setmetatable({
                name = "gdb: launch gtest",
                type = "gdb",
                request = "launch",
            }, {
                __call = function(self)
                    local binary = input("Binary: ", vim.fn.getcwd() .. "/", "file")
                    local tests = binary and #binary > 0 and gtest_list(binary) or {}
                    local selected = #tests > 0 and gtest_pick(tests) or nil
                    if not selected or #selected == 0 then
                        return vim.tbl_extend("force", self, { program = dap.ABORT })
                    end
                    return vim.tbl_extend("force", self, {
                        program = binary,
                        args = { "--gtest_filter=" .. table.concat(selected, ":") },
                        -- Test binaries resolve data relative to themselves.
                        cwd = vim.fn.fnamemodify(binary, ":h"),
                    })
                end,
            }),
            {
                name = "gdb: open core",
                type = "gdb",
                request = "attach",
                program = ask("Binary: ", vim.fn.getcwd() .. "/", "file"),
                core = ask("Core: ", vim.fn.getcwd() .. "/", "file"),
            },
            {
                name = "gdb: attach pid",
                type = "gdb",
                request = "attach",
                pid = function()
                    return tonumber(input("PID: "))
                end,
            },
        }
        dap.configurations["c"] = dap.configurations["cpp"]
    end
}
