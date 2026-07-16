---
name: verify
description: Verify a change to didedoshka's nvim config actually works — offline suite first, then the live checks that need a real UI, a real LSP or the arc mount.
---

# Verifying a change to this config

Work down the tiers. Tier 1 is cheap and always applies; stop climbing once the
tier that actually covers your change is green.

## Tier 1 — offline suite (always, ~1s)

```sh
./tests/run.sh          # lint + both test tiers
./tests/run.sh --quick  # tests only, skip the lint pass
```

Non-zero exit means something broke. This is also what the `Write|Edit` hook
runs, so a Lua edit that breaks it comes back immediately.

Three things it does, and why:

- **lint** — `lua-language-server --check` at the **workspace root**. It must be
  the root: given a subdirectory or a single file it never finds `.luarc.json`,
  and then every `vim` is an undefined global. Default checklevel (Warning) is
  deliberate — at `--checklevel=Hint` this repo reports ~30 unused-local /
  unused-function notes on deliberate style, and a check that cries wolf gets
  ignored.
- **`tests/core_spec.lua`** — `nvim --clean`, no plugins. Everything that is
  genuinely ours: `dide`'s highlight groups, `gdb_bt_qf` parsing end-to-end,
  `plugin/` features, spec conventions, snippets, queries. Green on a fresh
  clone.
- **`tests/init_spec.lua`** — the real `init.lua` with the real plugins. Options,
  filetypes, keymaps, commands, and autosave driven end-to-end against a real
  file on disk. Skipped (not failed) if lazy is not installed, so a fresh clone
  never triggers a plugin download.

### Two traps this suite exists to cover

- **`nvim` exits 0 even when `init.lua` throws.** The traceback only reaches
  stderr. `run.sh` therefore fails the init tier on *any* stderr output — never
  "verify" an init.lua change by exit code alone.
- **`lua-language-server` does not catch cross-module breakage.** Renaming
  `gdb_bt_qf`'s `M.setup()` while `init.lua` still calls it is *"no problems
  found"* to `--check`. Only loading the code catches it. That is why the hook
  runs the whole suite and not just the linter — don't "optimise" it back to a
  lint-only hook.

## Tier 2 — extend the suite

If you changed behaviour the suite doesn't assert, add the assertion; don't just
eyeball it. Rules of thumb for which file:

- Needs no plugins → `core_spec.lua`. Do **not** `:edit` a real file there:
  applying `dide` registers a `FileType` autocmd that requires nvim-treesitter,
  which does not exist under `--clean`. Name a scratch buffer with
  `nvim_buf_set_name` instead — that fires no `FileType`.
- Needs plugins, or a real buffer with a filetype → `init_spec.lua`.
- Shelling out (like `gdb_bt_qf`'s `arc root`) is the one thing worth stubbing.
  Zero `vim.v.shell_error` with a real successful command *before* swapping
  `vim.fn.system`, since `v:shell_error` is read-only.
- Stubbing a `vim.*` field? Keep its real arity. `vim.notify = function() end`
  teaches `lua_ls` that `vim.notify` takes no arguments and lights up every real
  call in the config. See `harness.quiet()`.

## Tier 3 — live, manual (needs a real UI or a real service)

The suite is headless and offline, so none of this is covered. Ask
didedoshka to run these; don't fire them blind.

- **Colorscheme look** — `core_spec` asserts `Normal` and the semantic palette
  exist, not that the result is *pleasant*. A palette change needs real eyes on
  a real file.
- **Semantic highlighting** (`<leader>s`) — needs treesitter parsers and a real
  buffer.
- **LSP** — servers only attach to a real file in a real project. Several run
  through `ya tool …` (clangd, ruff) and need the arc mount.
  **Do not try to attach `lua_ls` headlessly to test formatting: it hangs.**
  Ask didedoshka to run `:lua vim.lsp.buf.format()` instead.
- **Completion, dap/debugging, fzf-lua, oil, lazygit** — all interactive.
- **`:GdbBtQf`** — the suite covers parsing with `arc root` stubbed. The real
  path resolution needs an actual arc checkout.

## Never fire just to "test it"

- Anything in `~/personal/arc-nvim` that posts to Arcanum or the tracker
  (comments, PR actions). Writes to real systems; verify by reading.
- Searching the arc mount to "check a path resolves" — the global traversal ban
  applies here like everywhere else.
