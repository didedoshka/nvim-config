# Story 02 — run python tests, then read logs/stdout without cd-ing forever

> ```
> ya make -A --pytest-args="-rP -vv --log-level=ERROR"
> cd very/long/path/of/directory/with/stdout
> (vim stdout) || (cd TestName/logs; (rg||vim) http-proxy-log.debug.log)
> ```

## Verdict
Medium/low effort. Two halves: (1) *running* the test command — solved by story 01's
`.brd.lua` `commands`; (2) *getting to the output fast* — a tiny module that points
fzf-lua (which you already use) at the test-output dir so you never type the long path.

## Where `ya make` puts things
`ya make` writes results under the project into:
```
<project>/test-results/<test_type>/testing_out_stuff/
        <Class>.<test>.out            <- stdout you `vim` today
        <Class>.<test>.err
        <TestName>/logs/*.log         <- http-proxy-log.debug.log lives here
```
`<test_type>` is e.g. `py3test`. So the "very long path" is deterministic relative to
the project root: find `test-results` upward, descend to `*/testing_out_stuff`.

## Design → `code/ya_test.lua`
[`code/ya_test.lua`](code/ya_test.lua) (syntax-checked) adds:

| Command | Effect |
| --- | --- |
| `:YaTestOut` | fuzzy-open files under the nearest `test-results/**/testing_out_stuff` (fzf-lua files + preview) — replaces `cd very/long/path && vim stdout` |
| `:YaTestGrep` | live-grep within that dir — replaces `cd TestName/logs && rg http-proxy-log.debug.log` |

It walks up from the current buffer to the first `test-results` dir (`vim.fs.find(...,
{upward=true})`), finds the `testing_out_stuff` dirs (one per test type; `vim.ui.select`
if several), and hands that single dir to `fzf-lua.files` / `fzf-lua.live_grep_native`.
Filename fuzzy-matching over the output dir means the stdout file and every `*.log` are
one `<leader>`-ish keystroke and a few characters away — no path typing.

### ⚠ The `~/arc` rule
You told me never to rg/scan the arcadia VFS. This module is careful about that: it only
ever points fzf-lua at **one** `testing_out_stuff` directory. That is materialized local
build output — small and bounded — **not** the VFS source tree. It never greps `~/arc`
broadly. (If you want to be extra safe, `:YaTestGrep` can be dropped and you keep only
`:YaTestOut` + open-and-`/`-search.)

## Running the test itself (ties to story 01)
Put the command in `.brd.lua` `commands` so it's a keymap away with the pytest args baked
in (and selectable log-level via `vars`):
```lua
commands = {
    ["ya make -A pytest"] = 'ya make -A --pytest-args="-rP -vv --log-level=ERROR"',
},
```
Then the whole loop is: `<bs>r` → pick "ya make -A pytest" (runs, waited, in the brd
terminal) → `:YaTestOut` to read stdout → `:YaTestGrep` for the debug log. No `cd`.

## Config wiring
`ya_test.lua` is a `plugin/` drop-in (auto-loaded, like `arcanum_link.lua`). No keymaps
added by default; natural choices if you want them (both free):
```lua
vim.keymap.set('n', '<leader>to', '<cmd>YaTestOut<cr>',  { desc = "(t)est (o)utput" })
vim.keymap.set('n', '<leader>tg', '<cmd>YaTestGrep<cr>', { desc = "(t)est log (g)rep" })
```

## Nice-to-haves (not built, flagged)
- **Jump to the *last* run's stdout directly.** `ya make` prints the result path; a brd
  post-run hook could capture it and expose `:YaTestLast`. Needs a hook point in brd's
  `execute_in_terminal` (it already reads the terminal via OSC-133; it could scrape the
  printed `testing_out_stuff` path). Worth it only if `:YaTestOut`'s fuzzy pick feels slow.
- **Failures → quickfix.** `ya make` can emit machine-readable results (JUnit/`resource`
  json). Parsing failed tests into quickfix (via story 06's `:Qf`/`errorformat`) would let
  you `[q`/`]q` between failures. Bigger task; only if you want it.
