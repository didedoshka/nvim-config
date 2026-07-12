# Story 01 — run common arc/ya commands from keymaps (via `.brd.lua`)

> *"arc and ya make commands are common and long to type, if i had them set up in
> `.brd.lua` and could run them with keymaps from vim it would be great."*
> Plus the **Merge to release** chain (checkout → cherry-pick → submit) as a
> "three commands with wait, no-brain action".

This is the same itch as the `## BRD` redesign notes in `ideas.md` ("цепочки команд",
"установка переменных (флагов) и их выбор"), so I've designed them together.

## Verdict
Medium effort. The good news: **`brd` already has 90% of the machinery.** It reads
`.brd.lua`, runs commands in a waited floating terminal (`execute_in_terminal` chains a
list with `&&` and blocks on the OSC-133 exit code), resolves `function` values at run
time (`normalize`), and offers interactive selection (`co_select` / `vim.ui.select`).
What's missing is a place for *ad-hoc, non-build* commands and a key to run them.

## Why not a fresh plugin
`brd`'s terminal already gives you exactly the "run these N commands sequentially, stop
on failure, stay interactive (cherry-pick/submit open `$EDITOR`), wait for me" behaviour
that the Merge-to-release chain needs. Re-implementing a terminal runner in the config
would duplicate that. So: **extend `brd`** (it's your plugin) with a `commands` table.

## Design — add `commands` (+ optional `vars`) to `.brd.lua`
See [`code/example.brd.lua`](code/example.brd.lua) for the full shape. Summary:
- `commands` — a name → (string | list | function) map of ad-hoc commands. A list is
  chained with `&&` and waited (reusing `execute_in_terminal`). A function is called at
  run time and may prompt (`vim.fn.input`) or return a list.
- `vars` — named selectable flags/branches (`release`, `target`, …). Picked once via
  `vim.ui.select`, cached, and passed to command functions as `v`. This is the
  "установка переменных и их выбор" idea: choose the release branch / the `ya make` mode
  once, reuse across commands.
- `commands` and `vars` are **reserved keys** — brd must skip them when enumerating
  build/run/debug targets, so existing `.brd.lua` files keep working.

### The Merge-to-release chain
Expressed as one `commands` entry returning a 3-element list:
```lua
["merge to release"] = function(v)
    local commit = vim.fn.input("commit to cherry-pick: ")
    local name   = vim.fn.input("PR name: ")
    return {
        "arc checkout " .. v.release,
        "arc cherry-pick " .. commit,
        'arc submit -m "[26.1] ' .. name .. '"',
    }
end,
```
`execute_in_terminal` already joins with `&&\r\n` and waits — so it *is* "three commands
with wait, stop on failure", running in a real terminal so cherry-pick/submit stay
interactive. That's the no-brain action.

## Patch to `brd/lua/brd.lua`
Small, in brd's own style (`run_co` + `co_select` + `normalize` + `execute_in_terminal`,
all already defined in that file). Add near the `BrdConfig` command:

```lua
-- resolve the vars table: pick+cache any that are lists of choices, pass through the rest
local _vars = {}
local function resolve_vars(config)
    local spec = config.vars or {}
    for name, choices in pairs(spec) do
        if _vars[name] == nil then
            if type(choices) == "table" then
                _vars[name] = co_select(choices, { prompt = name .. ": " })
            else
                _vars[name] = normalize(choices)
            end
        end
    end
    return _vars
end

M.run_command = function()
    run_co(function()
        local config, config_dir = get_config()
        if config == nil then return end
        local commands = config.commands
        if commands == nil then
            print("no `commands` table in .brd.lua")
            return
        end
        local names = {}
        for k in pairs(commands) do names[#names + 1] = k end
        table.sort(names)

        local choice = co_select(names, { prompt = "run command: " })
        if choice == nil then return end

        local v = resolve_vars(config)
        local value = commands[choice]
        local cmd = (type(value) == "function") and value(v) or value
        execute_in_terminal(config_dir, cmd)
    end)
end

vim.api.nvim_create_user_command("BrdRun", function() M.run_command() end, {})
```

And make target enumeration skip the reserved keys. In `is_target_ok`, `choose_target`,
and `get_target`, the loops do `for k, _ in pairs(config)` — filter out reserved keys:
```lua
local RESERVED = { commands = true, vars = true }
-- inside each `for k in pairs(config)` that builds targets:
if not RESERVED[k] then ... end
```

## Config-side keymap
`brd` is loaded through `lua/plugins/dap.lua`. Add one keymap there (or in the `brd`
setup), matching your `<bs>` = brd layer:
```lua
vim.keymap.set("n", "<bs>r", "<cmd>BrdRun<cr>", { desc = "brd (r)un command" })
```
`<bs>` is your brd layer leader, `<bs>r` is free (build/run/debug/console use J/X/P/x/p/C
inside debugmaster, not `<bs>r`).

## Alternatives considered
- **Pure-config module (no brd change).** A `plugin/run_command.lua` with its own
  terminal. Rejected: it would duplicate `execute_in_terminal`'s waited/interactive
  terminal, and `brd`'s internals (`execute_in_terminal`, `co_select`) are `local`, not
  exported, so a config module can't reuse them. Extending brd is cleaner and it's your code.
- **Just fish abstractions + a terminal.** You already have `brd.fish` (`b`/`r`/`br`).
  You could add `arc`/`ya` fish functions and call them from a brd terminal, but then the
  command list isn't discoverable from a picker and vars-selection is manual. The
  `commands` table gives you the `vim.ui.select` menu for free.

## Effort / risk
- Patch is ~35 lines in `brd.lua`, no new dependencies, reuses tested code paths.
- Main risk: the reserved-key filter — if you already have a real target literally named
  `commands`/`vars` it'd shadow it (you don't). Documented above.
- Since `brd` is a separate repo (not this config), the patch belongs on a branch there;
  I did not modify it. The config-side change is just the one `<bs>r` keymap.
