# `[ ]` and `g` cheatsheet

Legend: **[you]** = mapped in your config · **[def]** = Neovim default mapping ·
**[vim]** = classic built-in motion (not shown by `:nmap`, lives in the C core) ·
**[add]** = suggested, not set yet.

---

## `[` / `]` motions

### Diagnostics & scope (LSP)
| Key | Action | |
|-----|--------|-|
| `[d` `]d` | prev / next diagnostic (with float) | [you] (overrides [def]) |
| `[D` `]D` | first / last diagnostic in buffer | [def] |
| `[f` | jump to enclosing **function / method** header | [you] (LSP) |
| `[c` | jump to enclosing **class / struct** header | [you] (LSP, shadows diff `[c`) |

> `[f` / `[c` use LSP `documentSymbol` (semantic), so they don't trip on C++'s
> most-vexing-parse the way a treesitter scan did. See also `g{` below.

### Lists & navigation (all [def])
| Key | Action |
|-----|--------|
| `[q` `]q` | `:cprevious` / `:cnext` (quickfix) |
| `[Q` `]Q` | `:crewind` / `:clast` |
| `[<C-q>` `]<C-q>` | `:cpfile` / `:cnfile` (quickfix, prev/next file) |
| `[l` `]l` | `:lprevious` / `:lnext` (location list) |
| `[L` `]L` | `:lrewind` / `:llast` |
| `[b` `]b` | `:bprevious` / `:bnext` (buffers) |
| `[B` `]B` | `:bfirst` / `:blast` |
| `[a` `]a` | `:previous` / `:next` (arg list) |
| `[A` `]A` | `:first` / `:last` (arg list) |
| `[t` `]t` | `:tprevious` / `:tnext` (tag matches) |
| `[T` `]T` | `:trewind` / `:tlast` |
| `[<Space>` `]<Space>` | add blank line above / below cursor |

### Code structure ([vim] — always available)
| Key | Action |
|-----|--------|
| `[[` `]]` | prev / next section start (`{` in column 0) |
| `[]` `][` | prev / next section end |
| `[{` `]}` | prev / next unmatched `{` / `}` |
| `[(` `])` | prev / next unmatched `(` / `)` |
| `[m` `]m` | prev / next method start (brace-based, Java-ish; fails on Python) |
| `[M` `]M` | prev / next method end |
| `[c` `]c` | prev / next change (only in `:diff` mode — otherwise `[c` is your class jump) |
| `[s` `]s` | prev / next misspelled word (needs `spell`) |
| `[z` `]z` | start / end of current open fold |
| `[p` `]p` | paste, reindented to current line |
| `[i` `]i` | show first line containing keyword under cursor |

### Visual-mode treesitter nodes ([def])
| Key | Action |
|-----|--------|
| `[n` `]n` | select prev / next node |
| `[N` `]N` | select prev / next sibling node |
| `an` / `in` | node textobject (around / inside) |

---

## `g` commands

### LSP defaults ([def]) — free, you may not be using them
| Key | Action |
|-----|--------|
| `grn` | rename (`vim.lsp.buf.rename`) |
| `gra` | code action |
| `grr` | references |
| `gri` | implementation |
| `grt` | type definition |
| `grx` | run codelens |
| `gO` | document symbols (outline) |

> **Conflict:** your buffer-local `gr` → fzf references *shadows the whole `gr…` family*
> in LSP buffers, so `gra/grn/grr/gri/grt` are dead exactly where you'd want them.
> See suggestions below.

### Your `g` maps
| Key | Action | |
|-----|--------|-|
| `g{` | **walk up** enclosing scope: innermost header, then one level up per press | [you] (LSP) |
| `gd` | definition (LSP) | [you] (overrides [vim] keyword search) |
| `gD` | declaration (LSP) | [you] |
| `gi` | implementation (LSP) | [you] (overrides [vim] `gi` = insert at last spot) |
| `gr` | references (fzf) | [you] (shadows `gr` prefix) |

### Motion & display lines ([vim])
| Key | Action |
|-----|--------|
| `gg` / `G` | first / last line |
| `gj` `gk` | down / up by *display* line (wrapped text) |
| `g0` `g^` `g$` | display-line start / first non-blank / end |
| `g_` | last non-blank char |
| `gm` | middle of screen line |

### Edit / case / format ([vim])
| Key | Action |
|-----|--------|
| `gu` `gU` `g~` | lowercase / uppercase / toggle case (operators) |
| `gq` `gw` | format lines (`gw` keeps cursor) |
| `gJ` | join lines without inserting space |
| `gp` `gP` | paste, leaving cursor *after* pasted text |
| `gc` `gcc` | toggle comment (built-in [def] — your Comment.nvim on `<leader>/` duplicates this) |
| `g?` | rot13 |

### Search & history ([vim])
| Key | Action |
|-----|--------|
| `g*` `g#` | search word under cursor, *not* whole-word |
| `gn` `gN` | select next / prev match of last search — `cgn` then `.` is the killer combo |
| `g;` `g,` | older / newer position in change list |
| `gv` | reselect last visual selection |
| `gi` | insert at last insert position *(you overrode this)* |

### Files & misc
| Key | Action | |
|-----|--------|-|
| `gf` `gF` | open file (+ line) under cursor | [vim] |
| `gx` | open URL / file under cursor with system handler | [def] |
| `ga` | show char code under cursor | [vim] |
| `gt` `gT` | next / prev tab | [vim] |
| `g<C-g>` | word / line / byte count | [vim] |

---

## Suggested additions

1. **Fix the `gr` conflict.** Rename your fzf references map `gr` → `grr` (matches the
   default). That single change un-shadows `gra/grn/gri/grt`, giving you 4 LSP actions
   for free — you could then drop your `<leader>a` / `<leader>r` / `gi` maps if you like.

2. **Error-only diagnostics `[e` / `]e`:**
   ```lua
   vim.keymap.set("n", "]e", function()
       vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR, float = true })
   end, { desc = "next (e)rror" })
   vim.keymap.set("n", "[e", function()
       vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR, float = true })
   end, { desc = "prev (e)rror" })
   ```

3. **Builtins worth building the habit for:** `gO` (symbol outline), `gx` (open link),
   `cgn` (change match + repeat with `.`), `g;`/`g,` (jump to last edits), `gv` (reselect).

4. *Optional:* git hunk motions `[h` / `]h` need a plugin (e.g. gitsigns) — you use
   lazygit, so skip unless you want inline hunk nav.
