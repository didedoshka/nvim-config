# User stories — plans & suggestions (overview)

Investigation of the **User stories** section of `ideas.md`, done overnight. One doc per
story with grounded analysis, a concrete design, ready-to-use Lua, and honest unknowns.
Nothing in `lua/` was modified — proposed code lives under `code/` and is syntax-checked
with `nvim --headless`. `arc`/`ya`/`nvim`/`fish` were all confirmed present; every `arc`
flag I rely on was checked against your actual `arc` (version 20225420).

## The stories
| # | Story | Doc |
| --- | --- | --- |
| 01 | Run common arc/ya commands from keymaps via `.brd.lua` (+ merge-to-release chain) | [01-run-commands-brd.md](01-run-commands-brd.md) |
| 02 | Run python tests, then read logs/stdout without cd-ing forever | [02-python-tests-logs.md](02-python-tests-logs.md) |
| 03 | Can't escape the browser — blame / code search / issues | [03-escape-browser.md](03-escape-browser.md) |
| ~~04~~ | ~~`:ArcanumLink` should respect the commit~~ — **done, shipped to `main`** | — |
| ~~05~~ | ~~Go-to-definition clobbers the quickfix list~~ — **done, shipped to `main`** | — |
| 06 | Working with lists (quickfix as backbone, fzf-lua as feeder) | [06-working-with-lists.md](06-working-with-lists.md) |

Stories 04 and 05 are implemented and their planning docs removed. 05 shipped
Fix A only (`gd`/`gi` → fzf-lua); the optional quickfix-stack keymaps were
deliberately **not** adopted.

## Priority — effort vs. impact
```
 impact
   ^
 h |  [04]✓       [05]✓                [01]
   |  arcanum    qf-nav               brd commands
   |  link       (done)               (~35-line brd patch)
 m |              [06]                 [02]            [03a] blame
   |            lists/qf              test logs        [03c] issue->editor
   |
 l |                                                   [03b-ii] monorepo search
   |                                                   (blocked on codesearch backend)
   +----------------------------------------------------------------> effort
        tiny            small              medium            (external unknown)
```

## Recommended order
1. ~~**04 — ArcanumLink v2.**~~ **Done** — `plugin/arcanum_link.lua` rewritten and shipped.
2. ~~**05 — LSP nav off quickfix.**~~ **Done** — `gd`/`gi` routed through fzf-lua (Fix A);
   the quickfix-stack keymaps were intentionally left out.
3. **06 — `arc_lists.lua`.** `:Qf`, `:ArcChangedFiles`, `:QfSave/:QfLoad`. Turns quickfix
   into the durable list backbone that 02/03 lean on. Ready in `code/arc_lists.lua`.
4. **02 — `ya_test.lua`.** Fast jump to test stdout/logs. Ready in `code/ya_test.lua`.
5. **01 — brd `commands`/`vars`.** The `.brd.lua` command runner + merge-to-release chain.
   Patch sketched (in brd's own repo, not this config); example in `code/example.brd.lua`.
6. **03 — browser escape.** 3a (blame-in-nvim) and 3c (link/issue → editor) are ready;
   3b-ergonomics is a config tweak; **3b whole-arcadia search is blocked** on the
   codesearch backend request (the one thing I can't get without an internal service).

## Cross-cutting theme
Almost everything converges on **two primitives**:
- **the quickfix list** as the one durable, navigable, saveable list (stories 05, 06, 02,
  03c, and your existing `gdb_bt_qf.lua`), and
- **thin `arc`/`ya` CLI wrappers** that shell out and either copy a string, open a buffer,
  or fill the quickfix list (stories 01, 03a, 03c, 04, 06).

Neither needs a heavy plugin or any UI beyond `vim.notify` / `vim.ui.select` / fzf-lua /
quickfix — i.e. it all fits "look and feel like vim, no clutter, every line understandable".

## Code artifacts (`code/`, syntax-checked, NOT installed)
| File | Story | Install as |
| --- | --- | --- |
| `arc_lists.lua` | 06, 03c | new `plugin/arc_lists.lua` |
| `ya_test.lua` | 02 | new `plugin/ya_test.lua` |
| `example.brd.lua` | 01, 02 | a `.brd.lua` at a project root |

(Story 04's `arcanum_link.lua` has been installed as `plugin/arcanum_link.lua` and
its draft removed.) Everything else (01's brd patch, 03a's `:ArcBlameLine`, fzf-lua
tweaks) is inline in the story docs as copy-paste snippets rather than whole files.

## Honest caveats
- **Not runtime-tested.** I syntax-checked every module with Neovim's own loader, and
  verified each `arc` subcommand/flag and `arc info`/`arc blame` JSON shapes against your
  real `arc`. But I did **not** drive them inside a live `nvim` session (no reliable
  headless way to exercise the interactive/terminal paths without risking your running
  editor and uncommitted changes). Treat the still-unshipped code as "reviewed +
  compiles", not "I watched it work". Stories 04 and 05 are now shipped to `main` but
  were not runtime-driven either — try `:ArcanumLink`/`:ArcanumOpen` on a real arc file.
- **`brd` is a separate repo** (`~/.local/share/nvim/lazy/brd`), so story 01's patch lands
  there, not in this config. Only the `<bs>r` keymap is a config change.
- **One hard blocker:** whole-arcadia code search (03b-ii) needs the codesearch service
  request, which I can't obtain without hitting internal infra. Flagged, not faked.
- I did **not** grep/scan `~/arc` anywhere in this work (per your rule) — only single
  metadata reads (`arc info`, `arc blame` on one file, `--help`).
