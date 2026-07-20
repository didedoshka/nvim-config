# GDB / DAP setup — how it fits together

Personal reference for the whole gdb stack: `lua/plugins/dap.lua`, `gdb/*`,
`lua/yt_gdb.lua`, `lua/gdb_bt_qf.lua`, persistent-breakpoints, and the
debugmaster "gdb" keymap scheme. Nothing here is spec — if code and this
disagree, trust the code.

## Adapter: gdb speaks DAP directly

gdb >= 14 has a built-in DAP server (`--interpreter=dap`), so no separate
adapter binary (no `cpptools`, no `codelldb`). `dap.adapters["gdb"]` in
`lua/plugins/dap.lua` builds the gdb command line by hand.

**`ya gdb` cannot be the adapter.** Its patched 17.1 build segfaults the
moment a DAP session runs the inferior — measured with a plain launch, no
core, arc printers disabled, so it's the build, not the python. System
`gdb` is what actually launches; `ya gdb`'s pretty-printers are just python
that loads fine into any gdb, so the adapter sources them from system gdb
instead of running ya's binary:

```
printers = <ya gdb --print-path>/../../share/gdb/python/arc/__init__.py
gdb -q -ex "maint set per-command time off"
       -ex "source <arc printers>"        -- only if arc_printers() resolved
       -ex "source gdb/dap_core.py"
       -ex "source gdb/dap_guard.py"
       --interpreter=dap
```

`maint set per-command time off` kills a flood of timing output events that
`~/.config/gdb/gdbinit` turns on and that otherwise spams the DAP console.

Sourcing the arc printers is slow enough to blow dap's default 4s
"adapter didn't respond" budget, hence `initialize_timeout_sec = 60` on the
adapter config (raised from an earlier smaller value — 60s has held so far).

## `gdb/dap_core.py` — teaching `attach` about core dumps

Upstream gdb DAP `attach` only takes `pid` or `target` — no core dump support.
This file deletes and re-registers `attach` with an extra `core` key, calling
`core-file <path>` instead. It has to special-case gdb >= 16 (which defers
launch/attach until `configurationDone` via `_LaunchOrAttachDeferredRequest`)
vs gdb 15 (which runs it inline) — both paths call the same `_do_attach`.

Loading a core creates a thread but never emits a DAP `stopped` event, so
every later request would answer "notStopped" forever; `_do_attach` fakes
the stop by hand (`send_event("stopped", ...)`) after loading.

## `gdb/dap_guard.py` — the OOM guard

The actual bug this exists for: gdb's DAP variable-expansion
(`gdb.dap.varref.VariableReference`) calls a pretty-printer's `children()`
**eagerly and unbounded** for any printer that predates `gdb.ValuePrinter`'s
`num_children()` API — which is every printer arc's gdb ships. Stopping on
the first line of a scope leaves that scope's locals (e.g. a `std::vector`)
holding stack garbage in `__begin_`/`__end_`; the libc++ printer then walks
a bogus multi-billion-element range. Measured: 23+ GB RSS and climbing,
DAP response never sent, on a real arc binary (unittester-ytlib,
arrow_writer.cpp:2481).

A printer that raises instead of looping is just the same wound faster:
the exception escapes the whole `variables` request, so the client loses
every variable in that scope, not just the bad one.

Fix, monkeypatched onto `VariableReference`:
- `cache_children` — walk `printer.children()` but stop at `MAX_CHILDREN =
  1000`; append `("<error>", "<error: ...>")` if the generator itself raises
  partway through, instead of losing what was already collected.
- `child_count` — caps a `gdb.ValuePrinter`'s own `num_children()` report too
  (it can bypass the children-list cap above and still get allocated at
  full size by `fetch_children`).
- `to_object` — catches exceptions from `to_string()`/type introspection and
  substitutes a `<error: ...>` placeholder for that one variable, so
  siblings in the same scope still come through.

1000 is deliberately way above `print elements` territory — this is a
backstop against nonsense, not a display limit. Checked against this box's
actual `gdb.dap.varref` internals (attribute names prefixed with `_` on this
build; varies by gdb version — don't trust docs floating around without
re-checking against the installed gdb if this ever breaks again).

Both files are gdb-version-sensitive by nature (they patch a private DAP
internal and detect a launch-flow change across gdb 15/16); if a gdb upgrade
breaks debugging, check these two first.

## `dap.configurations["cpp"]` (== `["c"]`)

Four fallback configs, used when a project has no `.litre.lua` (see below):

- **launch binary** — asks for a path (`vim.ui.input`, prefilled with cwd),
  args typed freely and split on whitespace (quotes stripped — no shell runs
  between input and argv, so quoting the input wouldn't do anything anyway).
- **launch gtest** — asks for a binary, runs `--gtest_list_tests` on it,
  parses suite/test names (suite lines start at column 0 and end in `.`,
  tests are indented under them, both can carry a trailing `# comment` for
  type/value params), then fzf-lua multi-select → `--gtest_filter=a:b:c`.
  Implemented as a `setmetatable(..., {__call=...})` config, not a plain
  function field, specifically so the picker can depend on the binary just
  asked for in the same call — dap expands plain function fields through
  `vim.tbl_map` in unspecified order, which a callable table sidesteps.
- **open core** — asks for binary + core path, `request = "attach"`, routes
  through `dap_core.py`'s core support above.
- **attach pid** — asks for a pid.

All the `ask()`/`input()` plumbing goes through `vim.ui.input` (not
`vim.fn.input`) inside a coroutine, precisely so a future `vim.ui.input`
override (e.g. a fuzzy picker) transparently upgrades these prompts too.

## litre.nvim integration

Real projects supply a `.litre.lua` with `debug("cpp", { program = ...,
args = ..., cwd = ... })`; `lua/plugins/litre.lua` registers the `type =
"gdb", request = "launch"` template so those files only need to say *what*
to run, not *how* — the adapter/arc quirks stay centralized in
`plugins/dap.lua`. See litre.nvim's own docs for the `debug()` primitive
itself and the `x` task-layer keymap.

## yt test attach: `lua/yt_gdb.lua` + `gdb/nvim-dap-attach`

For attaching to a yt unittest process from inside a running test (as
opposed to launching one from nvim). Full story in
`notes/yt-gdb-attach-into-nvim.md`; short version:

- yt's `gdb_helpers.attach_gdb` freezes the test process on a barrier file
  and needs something to attach a debugger and then touch that file.
- `gdb/nvim-dap-attach <pid> <barrier>` is that something: a shell shim
  wired in via `YT_GDB_ATTACH_COMMAND`, which uses `$NVIM` (set by nvim for
  any job it spawns — so this only works from a terminal *inside* nvim) to
  `--remote-expr` into `require("yt_gdb").attach(pid, barrier)`.
- `yt_gdb.attach` runs `dap.run{type="gdb", request="attach", pid=...}`,
  hooks `dap.listeners.after.configurationDone` (the point where nvim-dap
  has pushed already-set breakpoints into the session and is *about* to
  resume gdb — `Session:event_initialized` sends breakpoints and only then
  issues `configurationDone`), touches the barrier there, then
  `dap.continue()`. So: attach → breakpoints land → barrier released → test
  proceeds → hits your breakpoints.

## `persistent-breakpoints.nvim`

Straight `Weissle/persistent-breakpoints.nvim`, loaded with
`load_breakpoints_event = {"BufReadPost"}` — breakpoints reload as soon as a
file is opened, not lazily on first dap session. debugmaster's fork saves
through it automatically (see that repo's `actions.lua` / CLAUDE.md);
nothing else here talks to it directly.

## Debug-mode keymaps: `cfg.keymaps = "gdb"` (Design C)

Full scheme lives in debugmaster.nvim (`doc/keymaps-gdb-modal.md`,
`lua/debugmaster/debug/schemes/gdb.lua`) — implemented 2026-07-18, not yet
battle-tested for real over many sessions. The short version, since it's a
sharp departure from stock debugmaster:

- **No vim motions inside the layer at all.** Every key either speaks gdb,
  moves a panel, or is a nop. Killed by keyreport data: `n` and `b` are
  simultaneously top-6 vim keys *and* gdb's two most important commands
  (step/break) — no split of the two ever avoided pain, so the layer now
  refuses to mean anything but gdb.
- Entry is `<bs>` (toggle, sticky — not a one-shot; see `plugins/dap.lua`
  comment on why one-shot was rejected: a lone `<bs>` would wait out
  `timeoutlen`). `<Esc>` always leaves.
- Lowercase = debugger commands (`c` continue, `n` step-over, `s` step-into,
  `fin` finish, `f` frame, `u` until, `up`/`do` frame nav, `r` run/restart,
  `rc`/`rs`/`rn` reverse — needs record/rr, `b` break, `bc` conditional,
  `d` contextual delete, `p` print/inspect, `bt` backtrace float, `bq`
  backtrace → quickfix, `t` threads, `w` watch, `ib`/`is` info widgets, `e`
  exec yanked text, `q` quit+exit layer, `N` new session).
- Uppercase = UI namespace (`U` sidepanel, `F` float layout, `S` scopes,
  `T` terminal, `R` repl, `H` help, `W` watches, `M` move terminal, `<`/`>`
  rotate panel, `-`/`+` resize).
- Visual-mode `p` (inspect selection) and `w` (watch selection) only exist
  *inside* the layer — select outside, hop into the layer, then act.
- Sidepanel direction is `"below"` and `ui_auto_toggle` is disabled (both
  set in `plugins/dap.lua`), so the panel doesn't pop on its own.

If this scheme ever feels wrong mid-session, `doc/keymaps-gdb-modal.md`'s
History section has the two designs that were tried and rejected before it
(A: literal gdb with motions as arguments; B: motion contract with gdb where
free) and *why* — worth reading before re-litigating the same trade-off.

## `lua/gdb_bt_qf.lua` — paste a backtrace, get quickfix

For a backtrace that only exists as pasted text (e.g. from a teammate, a
log, a non-DAP gdb session) rather than a live nvim-dap session: `:GdbBtQf`
parses the whole buffer, `:GdbBtQfSelection` parses a visual selection.
Wired into debugmaster too — `bq` (backtrace-to-quickfix) inside the layer
is `debug/actions.lua`'s own path for a *live* session; this module is the
paste-in path, both land in quickfix the same way (pushed like `:grep`).

Path handling: gdb prints `/-S/...` as a source-substitution prefix for the
arc root (`/-X` variants too — any single-letter tag after the dash);
stripped and re-anchored under `arc root`'s output. Frames can wrap across
multiple physical lines; continuation lines (anything not starting `#<n>`)
get folded back into the frame they belong to before parsing.

## Traps actually hit

- **`ya gdb` as the DAP binary segfaults on inferior execution.** Always
  launch system `gdb`; only source ya's pretty-printers into it.
- **Sourcing arc's printers is slow enough to trip dap's default init
  timeout** — that's what `initialize_timeout_sec = 60` is for; don't
  remove it going back to a plain adapter.
- **Uninitialized locals can OOM the variables panel** without
  `dap_guard.py` — this isn't hypothetical, it was measured at 23+ GB RSS
  on a real binary. If a future gdb version changes `gdb.dap.varref`'s
  internals, the guard may silently stop applying (it monkeypatches
  private, underscore-prefixed attributes) rather than erroring loudly —
  worth an occasional sanity check after a gdb upgrade.
