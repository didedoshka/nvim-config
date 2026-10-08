# Claude reviews how I use nvim

Design discussion started 2026-10-09. Nothing is built yet, and none of the decisions below has
been taken. To pick up: "read notes/vim-usage-review.md and continue".

## The question

Can Claude watch how I use nvim and point out where I'm inefficient, then fix it with a config
change or a plugin? Examples: opening a file I have pinned on `s` through `<leader>g` instead,
underusing the jumplist, marks and LSP.

## What exists

- `plugin/keylog.lua`: opt-in (`mkdir ~/.local/share/nvim/keylog`), counts keys, mappings and
  commands per mode, `:KeyReport` shows the tally. Not enough on its own: no sequence, no file,
  no position, so no context. Insert-mode keys and command arguments are deliberately dropped.
- `keyreport_30_07.txt`, `keyreport_25_08.txt` (untracked, repo root): tally snapshots. July
  has `j` 2851, `k` 2152, `<ScrollWheelDown>` 1516, `w` 1297.
- `undofile = true` (`init.lua`), and the `timeline` skill already reads undo files and shada,
  and rebuilds an old version with `nvim -R -u NONE -c 'earlier Nm'`.
- hardtime.nvim (m4xshen): blocks repeated keys, hints faster motions, can report the most common
  bad habits. Rule-based: it catches `jjjj` but can't tell that grep was the wrong tool.

## Proposal

nvim records a trace of events with context; when I ask, Claude condenses it, reads the code it
points at and reports the episodes where I lost time, each with the faster way and a proposed
config or plugin change, applied once I approve.

| # | Decision           | Recommendation                                                   |
|---|--------------------|------------------------------------------------------------------|
| 1 | How Claude watches | trace recorded by nvim, reviewed on demand; not live, no hints   |
| 2 | Recorder           | extend `plugin/keylog.lua`; `:KeyReport` becomes a tally of it   |
| 3 | Context per event  | file, position, `<cword>`, what caused each switch (see below)   |
| 4 | Privacy line       | also record grep/`/` queries and `<cword>`; insert keys stay out |
| 5 | Who spots patterns | an `nvim -l` condenser first, then Claude reads its episodes     |
| 6 | Output             | `/vim-review` skill, run weekly; fixes applied on approval       |
| 7 | Live "just now?"   | later: trace tail, jumplist and marks via the nvim socket        |
| 8 | Edits and drift    | read the undo files too (added after the pushback below)         |

Details:

- 3: which key caused each buffer switch, jumplist moves, LSP requests, grep and `/` queries,
  fzf picks. No screen snapshots.
- 4: queries and `<cword>` are identifiers; without them "grep instead of `gd`" is invisible.
- 5: the condenser folds runs (`j×23`), splits the trace into navigation episodes and flags the
  obvious patterns itself. A month of raw events is too much to read, and `jjjj` needs no model.
- 7: same data, read sooner; needs 1–6 first.

Patterns this should catch:

- `<leader>g` landing on a file already pinned on `s` or open in the buffer list
- a grep or `/` query equal to the word under the cursor → `gd`, `gr`, `*`
- `<C-k>` six times to get back somewhere → a mark or `''`
- the same file:line reached repeatedly by scrolling → a pin or a mark
- what the `<ScrollWheelDown>` and `j` runs were looking for

## Pushback (2026-10-09) and answers

**The file will have changed by the time of the review.** The undo history recovers the file
as it was at any event: every `undotree()` entry carries a `time`, and `:earlier` rebuilds that
state. Limit, from `:h undo-persistence`: nvim ignores an undo file when the file was changed
after the undo file was written, e.g. by an `arc checkout` or rebase while the file wasn't open
in nvim. Mitigations, not yet decided: the trace also stores the cursor line text at navigation
events so a finding survives the drift; run the review often.

**Keys alone don't show complex edits.** The undo history does: each change with its timestamp
and its before/after text. Matched against the trace's keys, it shows both what I pressed and
what it did, e.g. the same replacement made by hand in twelve places → `cgn` + `.`, `:s`, or an
LSP rename.

Catch: undo files hold everything I typed, prose included, so keylog's "never records prose"
rule no longer covers the review. The data stays local and is already on disk.

## Open

- Take or amend the set 1–8.
- How to handle undo files invalidated by arc operations: line text in the trace, or accept the
  loss.

## Next step

Once decided: build the recorder, let it run for a week, then write the condenser and the
`/vim-review` skill.
