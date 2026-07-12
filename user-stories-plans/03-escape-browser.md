# Story 03 — can't escape the browser

Three sub-stories, each "I end up in a browser and there's no easy way back to vim":
**3a Blame → PR**, **3b Code search**, **3c Issues → editor**. The common thread: keep
the round-trip inside Neovim, and when a link *is* involved, make it bidirectional.

---

## 3a — Blame → PR → back to vim

> reading code in nvim → want blame → `:ArcanumLink` → jump to PR (or the code prior to
> it) → now stuck reading in the browser, no easy way back.

**Key realization:** the commit message already carries the PR id. From the `arc info`
dump I captured, messages end with `REVIEW: 14182098`. So blame → commit → PR is fully
derivable locally; you only need the browser for the *final* PR discussion, and even the
introducing diff can be read in nvim.

### Proposed `:ArcBlameLine` (stay in nvim)
Verified against your `arc`: `arc blame --json -L <l>,<l> <path>` returns
`{ annotation:[{ commit, author, date, text, line }], commits:[{ commit, parents:[...] }] }`.
So the cursor line's commit **and** its parent (for "code prior to it") are both in one call:
```lua
-- for the cursor line: show the introducing commit (message + diff) in a scratch buffer.
local function arc_blame_line()
    local file = vim.api.nvim_buf_get_name(0)
    local dir  = vim.fs.dirname(file)
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local out = vim.system(
        { "arc", "blame", "--json", "-L", line .. "," .. line, file }, { cwd = dir, text = true }):wait().stdout
    if not out or out == "" then vim.notify("no blame", vim.log.levels.WARN); return end
    local hash = vim.json.decode(out).annotation[1].commit
    -- show the whole commit (message incl. `REVIEW: <pr>` + diff) in a scratch buffer
    local show = vim.system({ "arc", "show", hash }, { cwd = dir, text = true }):wait().stdout
    vim.cmd("botright vnew"); vim.bo.buftype = "nofile"; vim.bo.filetype = "git"
    vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(show or "", "\n"))
    vim.notify("commit " .. hash:sub(1, 12))
end
```
Now blame reading happens in nvim: you see who/why/when **and** the `REVIEW: <pr>` line.
- Want the PR in the browser anyway? A follow-up `:ArcPr` reads the `REVIEW:` id from the
  message and opens `https://a.yandex-team.ru/review/<id>` (copy to `+`, same as
  `arcanum_link`). But you frequently *won't need to* — the diff is right there.
- "look at the code prior to it": the blame JSON's `commits[].parents[1]` gives the parent
  hash; `arc show <parent>:<relpath>` prints the pre-change version into a scratch buffer.
  Optional `:ArcParent` (no revspec guessing needed — the parent is right there in the JSON).

**Back to vim** is now a non-issue because you never left. (`arc blame --json` output shape
confirmed above, so the parse is real, not a guess.)

*Bigger option (only if you want live gutter blame):* a virtual-text current-line blame
(`arc blame` for the cursor line, debounced on `CursorHold`). More moving parts and it
edges toward the "no clutter" line — I'd start with the on-demand `:ArcBlameLine` above.

---

## 3b — Code search

> want cs.yandex-team.ru-quality search in nvim. fzf-lua ivy mostly fixed the *ergonomics*
> (long filename, narrow window, unaligned lines), but there's **no whole-arcadia search**.

Two separate problems:

### (i) Ergonomics — mostly done, small tuning left
You noted the ivy switch fixed most of it. To make results read like CS (filename first,
left-aligned, wide preview):
```lua
-- lua/plugins/fzf.lua
grep = {
    multiline = 1,
    formatter = "path.filename_first", -- basename first, dir dimmed after -> short & aligned
},
winopts = { preview = { layout = "vertical", vertical = "up:55%" } }, -- wide, tall preview
```

### (ii) Whole-arcadia search — the real gap, and the constraint that shapes it
**Correction to my first instinct:** there is **no `arc grep`** (verified:
`'grep' is not an arc command`). And you've told me a local `rg` over `~/arc` — *any*
subtree of it — is off the table (huge VFS + ban risk). So there is **no safe local
primitive for monorepo-scoped search at all**, regardless of scope. That is *precisely
why* cs.yandex-team.ru exists: monorepo search must be served by the **codesearch
backend**, not a local walk.

What that means concretely:
- **The only fully-safe local searches** are within already-loaded content: current buffer
  (`<leader>g`, you have it), across open buffers (`fzf-lua.lines`), or within a
  materialized non-VFS dir (test output — see [story 02](02-python-tests-logs.md)). None of
  these is "whole-arcadia".
- **Real code search (project- or arcadia-scoped) needs the codesearch service.** The
  nvim side is easy and I can write it fully — a fzf-lua *live* provider
  (`fzf_lua.fzf_live`) that shells a query to the backend and renders `file:line:text` with
  `ctrl-q` → quickfix. The one missing fact is the backend call itself:
```
  fzf-lua live provider  ──query──►  codesearch service  ──results──►  quickfix / fzf list
```
  To fill that in, capture the request `cs.yandex-team.ru` fires (browser devtools →
  Network) or locate the internal codesearch CLI under `devtools`, and drop that single
  call into the provider. **This is the one item in the whole backlog I cannot ground for
  you without hitting an internal service** — everything else here is buildable now.

So, unlike my first draft: I will *not* offer a "project-scope `arc grep` now" — it doesn't
exist and the rg alternative is forbidden. The honest path is codesearch-backend or nothing
for monorepo search.

---

## 3c — Issues → open the codeline in the editor

> issues live in the browser; hard to open the corresponding code lines in the editor.

Two mechanisms:
- **Any arcadia/CS link → editor:** `:ArcanumOpen [url]` — **done, shipped** in
  `plugin/arcanum_link.lua` (story 04). Copy a link out of the issue, `:ArcanumOpen`,
  land on the line. Handles `?rev=` too.
- **Pasted issue text with `path:line` refs → navigable list:** `:Qf` (drafted in
  [story 06](06-working-with-lists.md) / `code/arc_lists.lua`). Paste the issue body,
  `:Qf`, and every `path:line` becomes a quickfix entry you step through with
  `:cnext`/`:cprev`. This is the
  generalization of your `gdb_bt_qf.lua` to arbitrary pasted lists.

Together those two cover "issue in browser → code in editor" without a dedicated tracker
integration. (A full Tracker-in-nvim client is possible but is a much larger project and
fights the minimalism goal; I'd only reach for it if issue-triage volume justifies it.)

---

## Summary of what 03 needs
| Piece | Buildable now? | Depends on |
| --- | --- | --- |
| 3a `:ArcBlameLine` / `:ArcPr` / `:ArcParent` | yes | none — `arc blame --json` shape confirmed |
| 3b (i) fzf-lua CS-like ergonomics | yes | none (config tweak) |
| 3b (ii) monorepo code search (any scope) | **blocked** | the codesearch service request/endpoint (no `arc grep`; local rg forbidden) |
| 3c `:ArcanumOpen` + `:Qf` | `:ArcanumOpen` shipped (story 04); `:Qf` drafted | story 06 |
