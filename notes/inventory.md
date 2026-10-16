# Inventory: keymaps, commands, plugins

What this config gives you on 2026-10-14 (commit 058cf40, quicker.nvim commented out): every
keymap and `:Command` defined by the config, its plugins and the `~/p` plugins, then all 43
plugins. Collected from a headless run of the real config with every plugin loaded, not from
memory. Neovim's own defaults are left out unless the config changes them. It is a snapshot; the
live sources below never go stale.

## Look it up live

- Pause 2 s after any prefix (`<Space>`, `g`, `z`, `[`): which-key lists what can follow; after
  `"` it lists the registers, after `'` or `` ` `` the marks. `:WhichKey` shows every
  normal-mode key.
- `:FzfLua keymaps`, `:FzfLua commands`: fuzzy search over what exists right now.
- `F1` in an fzf-lua picker, `g?` in oil, `?` in undotree, `H` in debug mode, `?` in lazygit: that
  surface's own keys.
- `env -u NVIM nvim --headless -u init.lua -l tests/keymap_dump.lua '<leader>g'`: what already
  holds a key, LspAttach maps included.

## Keys that aren't stock Neovim

Normal mode unless noted.

| Key | Does here | From |
| --- | --- | --- |
| `s` | picker: pinned files, then open buffers (Find & open) | fzf-pin |
| `x` | task layer (Tasks) | liter |
| `<BS>` | enter debug mode, also from visual; `<Esc>` leaves (Debug) | debugmaster |
| `<CR>` | server picker (Terminals & servers); quickfix and the cmdline window keep theirs | no-tmux |
| `y` | `<C-w>`: `yv` `ys` split, `yh` `yj` `yk` `yl` move, `yq` close, `yo` only; visual `y` and `Y` still yank | config |
| `<C-k>` `<C-j>` | jumplist back / forward | config |
| `<C-o>`, `<Tab>`, `S`, visual `s` `S` | print `habit` | config |
| `f` `F` `t` `T` | across lines, labels when several targets, the same key again for the next (also visual, operator) | flit |
| `/` `?` `n` `N` `gn` `gN` | PCRE2 search (also visual, operator-pending) | pcre |
| `*` `#` `g*` `g#` | PCRE2 word search; visual `*` `#` search the selection | pcre |
| `<C-l>` | also clears the pcre highlights | pcre |
| `gc` `gb` | Comment.nvim instead of the builtin `gc` | comment |
| `ga` | prefix of the case conversions (Edit) | text-case |
| `-` | the file's directory in oil (measured) | Neovim + oil |
| `gx` | copies the URL under the cursor (OSC52): this box has no browser | config |
| `:s/…` | runs as PCRE2 `:S` on `<CR>`; `:su` is the native one | pcre |
| `:q` `:qa` | print `habit` in an `nt` server (`:q` only when it would end the session) | no-tmux |
| insert `<C-l>` | toggle the Russian layout (`keymap/russian-yasherty.vim`) | config |
| terminal `<C-e>` | leave terminal mode | config |

## `<Space>`, the leader

| Key | Does | Where |
| --- | --- | --- |
| `a` + letter | arc: blame, diff, grep, link, PR (Arcadia) | `ag`, `al` also visual |
| `c` | code action | LSP buffers, also visual |
| `d` | diagnostics of the line in a float | LSP buffers |
| `f` | format | LSP buffers, also visual |
| `g` | grep in files | also visual |
| `j` | workspace diagnostics picker | LSP buffers |
| `k` | switch source / header | clangd buffers |
| `l` | resume the last picker | |
| `m` | `:restart` | |
| `n` | breadcrumbs winbar on / off | |
| `o` | open file | also visual |
| `p` | Neovim help | also visual |
| `q` | close the buffer, keep the window | |
| `r` | rename | LSP buffers |
| `s` | semantic highlighting on / off in this buffer | |
| `t` | terminal | |
| `u` | undotree | |
| `v` | inlay hints on / off | LSP buffers |
| `w` | oil on the file's directory | |
| `y` | copy `path:line` | also visual |
| `/` | toggle comment | also visual |

Free: `b` `e` `h` `i` `x` `z`.

## Find & open

| Key / command | Does | From |
| --- | --- | --- |
| `<Space>o`, `:FzfLua files` | file by name; visual: the selection is the query | fzf-lua |
| `<Space>g`, `:FzfLua live_grep` | live grep (rg); visual: grep the selection | fzf-lua |
| `<Space>p`, `:FzfLua helptags` | Neovim help; visual: help for the selection | fzf-lua |
| `<Space>l`, `:FzfLua resume` | the last picker back, with its query and cursor | fzf-lua |
| `s` | pinned files (`[e] path`), then the open buffers | fzf-pin |
| `<Space>w`, `:Oil [dir]` | directory as an editable buffer (also `-`, `:e dir`) | oil |
| `<Space>q` | close the buffer, keep the window | config |
| `<Space>y`, `:CopyLoc` | absolute `path:line` to the clipboard; visual: `path:l1-l2` | config |
| `:Workspace` | edit the `.workspace` in force, or start one with `yt/yt` `yt/cpp` `library/cpp` | config |

A `.workspace` (one directory per line, found walking up from the cwd) makes `<Space>o` and
`<Space>g` search only those directories from its root, and `s` show paths relative to it.

More pickers, no key: `:FzfLua` + `buffers` `oldfiles` `grep_curbuf` `blines` `lines` `marks`
`jumps` `changes` `registers` `command_history` `search_history` `quickfix` `quickfix_stack`
`loclist` `spell_suggest`; `:FzfLua builtin` lists them all.

In oil, edit the listing like text and `:w` applies it (create, rename, move, delete); `<CR>`
open, `-` parent, `_` the cwd, `<C-p>` preview, `g.` hidden files, `g?` the rest. netrw is off
(oil replaces it): no `:Explore` and friends.

Inside fzf-lua pickers:

| Key | Does |
| --- | --- |
| `F1` | the picker's keys |
| `ctrl-q` | every result to a new quickfix list (file and buffer pickers; config) |
| `tab`, `alt-q` | select entries, send the selected ones to quickfix |
| `ctrl-s` `ctrl-v` `ctrl-t` | open in a split / vsplit / tab |
| `ctrl-p` `ctrl-n` | earlier / later queries, a history per picker (config) |
| `ctrl-j` `ctrl-k` | down / up |
| `ctrl-f` | `<Space>o` / `<Space>g` only: reopen in the buffer's directory, ignored files included, query kept (config) |
| `ctrl-g` | grep: switch between rg and fuzzy filtering of the hits |
| `alt-i` `alt-h` | files and grep: toggle ignored / hidden files |
| `shift-up` `shift-down`, `F4` | scroll the preview, toggle it |
| `esc` | hide (`<Space>l` brings it back) |

Inside the `s` picker (the `x` and `<CR>` pickers are the same machine):

| Key | Does |
| --- | --- |
| a pinned char | open it |
| a free char (`a`–`z` but `i`) | pin the current file to it; pins are per cwd and survive restarts |
| `i` | type to fuzzy-search instead; `esc` back to chars |
| `enter` | open the selected entry |
| `ctrl-x` | unpin; on a plain buffer: close it (a terminal asks first) |
| `esc` | close |

## Search & replace

| Key / command | Does | From |
| --- | --- | --- |
| `/` `?` | PCRE2 search, live highlight, `[cur/total]` count; extends a visual selection, is the motion after an operator | pcre |
| `n` `N` | next / previous match; native again after a native search | pcre |
| `*` `#`, `g*` `g#` | the word under the cursor as `\bword\b`, or without the `\b`; visual: the selection | pcre |
| `gn` `gN` | select the next / previous match: `cgn` then `.` changes them one by one | pcre |
| `<C-l>` | clear every search highlight, `:diffupdate`, redraw | pcre |
| `:s/pat/rep/flags` | runs as `:S`: groups `$1` or `\1`, `${name}`, flags `g` `c` `i` | pcre |
| `:Pcre` | pcre off / on, to compare with Vim's engine (`:S` stays PCRE2) | pcre |
| `:Subs/old/new/` | every case form of `old` (`old_name`, `oldName`, `OLD_NAME`, …) to the same form of `new`; whole file, or a range | text-case |
| `:TextCaseStartReplacingCommand` | types `:Subs/<word under cursor>/` for you | text-case |

PCRE2 is case-sensitive; `(?i)` in the pattern ignores case. Inside the `/` prompt: `<Up>` `<Down>`
or `<C-p>` `<C-n>` history, `<C-g>` `<C-t>` next / previous match while typing, `<C-r>{reg}` a
register (newlines become spaces), `<C-r><C-w>` word, `<C-r><C-a>` WORD, `<C-r><C-l>` line,
`<BS>` on an empty prompt cancels. Across all of arcadia: `:ArcGrep` (Arcadia).

## Move

| Key / command | Does | From |
| --- | --- | --- |
| `f` `F` `t` `T` | to a char, across lines; labels when there are several (normal, visual); same key again for the next | flit + leap |
| `<C-k>` `<C-j>` | jumplist back / forward | config |
| `y` + a `<C-w>` key | window commands (`yv` `ys` `yh` `yj` `yk` `yl` `yq` `yo`) | config |
| `<Space>n` | breadcrumbs (enclosing class, function) in the winbar | navic |
| `:GoEnclosingFunction`, `:GoEnclosingClass` | the header of the enclosing function / class | config |
| `:GoScopeUp` | the innermost scope's header, one level up per call | config |
| `:GoNextMethod` | inside a class, the next method header below the cursor | config |

The `Go*` commands are buffer-local, in buffers whose server has document symbols. LSP jumps
(`gd`, `gr`, …) are under LSP.

## Edit

| Key / command | Does | From |
| --- | --- | --- |
| `<Space>/` | toggle the line's comment, or the selection's | comment |
| `gcc`, `gc{motion}`, visual `gc` | line comments | comment |
| `gbc`, `gb{motion}`, visual `gb` | block comments (`/* */`) | comment |
| `gco` `gcO` `gcA` | a comment on a new line below / above, at the end of the line | comment |
| `ga` + `s` `c` `p` `d` `n` `u` `l` | the word (visual: the selection) to snake_case, camelCase, PascalCase, dash-case, CONSTANT_CASE, UPPER, lower | text-case |
| `gao` + letter + motion | the same, as an operator | text-case |
| `ga` + `S` `C` `P` `D` `N` `U` `L` | LSP rename into that case | text-case |
| `:Refactor extract_var NAME` | the selection into a variable (live preview) | refactoring |
| `:Refactor extract_func NAME`, `extract_func_to_file NAME FILE` | the selection into a function, here or in another file | refactoring |
| `:Refactor inline_var`, `inline_func` | inline the variable / function under the cursor | refactoring |
| `<Space>u`, `:UndotreeToggle` | the undo tree (also `:UndotreeShow` `:UndotreeHide` `:UndotreeFocus` `:UndotreePersistUndo`) | undotree |

Refactoring speaks C++, Lua, Python and a few more. In undotree: `J` `K` older / newer state,
`<CR>` go to the state under the cursor, `<` `>` saved states, `D` diff panel, `T` timestamps,
`=` `M` set / clear the diff marker, `C` clear the history, `<Tab>` back to the file, `q` close.

Insert mode:

| Key | Does | From |
| --- | --- | --- |
| `<C-n>` `<C-p>` | completion next / previous, also on the `:` line | cmp |
| `<C-y>` `<C-e>` | accept / dismiss, also on the `:` line | cmp |
| `<C-j>` `<C-k>`, `<C-c>` | snippet: next / previous tabstop, stop (only while a snippet is active) | mini.snippets |
| `<CR>` between brackets, `<BS>` | open a block, delete the pair | autopairs |
| `<M-e>` after an opening bracket | fast wrap: choose where its closing pair goes | autopairs |
| `<C-l>` | toggle the Russian layout; in typst, `$` toggles it too | config |

Completion draws from snippets, LSP, paths and buffer words, with ghost text. Snippets expand
from the completion menu; there is no expand key. Own snippets in `snippets/`:

- c, cpp: `f` / `fb` for loop up / down, `en` newline; cpp also `ft` typed for loop, `vi` `vvi`
  vectors, `be` `x.begin(), x.end()`, `fff` / `ttt` contest templates (one test / many)
- lua: `liter_header`, `liter_task`, `liter_parameter`, `liter_cmake` (a whole `.liter.lua` for a
  cmake project)

## LSP

Servers: lua_ls, pyright + ruff, clangd, cmake, tinymist (typst), rust_analyzer, protols, gopls.
Formatting is none-ls (cmake_format, prettier, clang-format), Python's is ruff.

Once a server attaches (the keys are buffer-local):

| Key / command | Does |
| --- | --- |
| `K` | hover |
| `gd` `gi` `gr` | definitions / implementations / references in fzf-lua; a single result jumps straight there; quickfix untouched |
| `gD` | declaration |
| `<Space>r` | rename |
| `<Space>c`, `:CodeAction` | code action; visual or a range: for the selection |
| `<Space>f` | format the buffer, or the selection |
| `<Space>d` | the line's diagnostics in a float |
| `[d` `]d` | previous / next diagnostic, with its float |
| `<Space>j` | workspace diagnostics in fzf-lua (`ctrl-q` to quickfix) |
| `<Space>v` | inlay hints on / off (on by default where the server has them) |
| `<Space>k` | clangd: switch between source and header |

Neovim's own LSP keys work here too: `grn` typed in one go still reaches rename despite the
buffer-local `gr` (measured). They are `grn` rename, `gra` code action, `grr` references into
quickfix, `gri` implementation, `grt` type definition, `grx` run codelens, `gO` document symbols,
`[D` `]D` first / last diagnostic, insert `<C-s>` signature help.

No key: `:FzfLua lsp_document_symbols`, `lsp_live_workspace_symbols`, `lsp_incoming_calls`,
`lsp_outgoing_calls`, `lsp_finder`, `diagnostics_document`.

Commands: `:lsp restart`, `:lsp stop`, `:lsp enable`, `:lsp disable` (Neovim's; lspconfig's
`:Lsp*` are gone), `:checkhealth vim.lsp` (what's attached), `:NullLsInfo`, `:NullLsLog`,
`:LazyDev debug`, `:LazyDev lsp` (what lazydev gave lua_ls), `:CmpStatus` (completion sources).

Automatic: lsp_signature shows the signature while you type arguments; lazydev feeds lua_ls the
nvim runtime and the plugins a file requires; lualine shows the attached servers and progress.

## Arcadia

`<Space>a` + letter; the next letter does the same on the PR instead of the checkout.

| Key | Command | Does |
| --- | --- | --- |
| `<Space>ab` | `:ArcBlame` | per-block blame (author, date, summary, PR) as virtual lines, on / off |
| `<Space>ac` | `:ArcPrBlame` | the PR that introduced the current line, as `:ArcPrView` |
| `<Space>ad` | `:ArcDiff [args]` | uncommitted changes as a diff buffer; `:ArcDiff!` since the merge-base with `app/build-cache/hot` |
| `<Space>ae` | `:ArcPrDiff [id]` | the PR's diff (merge-base to head) |
| `<Space>ag` | `:ArcGrep [flags]` | live codesearch (`ya tool cs`, junk/ and contrib/ excluded); visual: the selection |
| `<Space>ah` | `:ArcDiffHl[!]` | the same delta drawn onto every file shown, added lines green, on / off |
| `<Space>ar` | `:ArcDiffHlDeleted` | inside that, deleted lines as red virtual lines, on / off |
| `<Space>al` | `:ArcLinkCreate [trunk]` | commit-pinned a.yandex-team.ru link to the line or selection, to the clipboard (`trunk`: unpinned) |
| `<Space>ap` | `:ArcPrView [id]` | the PR as markdown: checks, description, comment threads with their code |
| | `:ArcBlameLine` | blame of the current line, as a message |
| | `:ArcFzfPrs [args]` | PR picker; args go to `arc pr list` (default `-o` mine, `-i` incoming) |
| | `:ArcFzfPrFiles [id]` | the PR's changed files, with preview |
| | `:ArcPrIssues[!] [id]` | unresolved review issues into quickfix (`!`: all) |
| | `:ArcPrWatch [id]` | `arc pr status --follow` in a terminal split |
| | `:ArcFzfDirty` | dirty working-tree files (`arc status`) |
| | `:ArcFzfTickets [query]` | tracker picker (default: my unresolved) |
| | `:ArcTicket KEY` | a ticket as markdown |
| | `:ArcRefs` | `path:line` references in the buffer or a range, into quickfix |
| | `:ArcLinkOpen [url]` | an a.yandex-team.ru URL (argument or clipboard) to the file at that line |

`[id]` defaults to the current branch's PR. Inside:

- `:ArcFzfPrs`: `enter` view, `ctrl-d` diff, `ctrl-f` files, `ctrl-o` checkout, `ctrl-y` copy URL
- `:ArcFzfTickets`: `enter` view, `ctrl-p` the ticket's PRs, `ctrl-y` copy URL
- `:ArcGrep`: the fzf-lua keys; `ctrl-f` narrows to the buffer's directory, `ctrl-g` fuzzy-filters
  the hits
- `:ArcPrView`: `<cr>` jump to the commented line, `R` reply to the comment under the cursor,
  `X` resolve / reopen, `D` the PR's diff
- diff buffers: `<cr>` jumps to that file:line; every arc buffer: `q` closes it

## Debug

`<BS>` (normal or visual) enters debug mode; the statusline says DEBUG, `<Esc>` leaves. Inside,
lowercase talks to gdb and uppercase opens panels; every other printable key does nothing
(counts, `z…`, `<C-w>`, `<Space>` and the mouse still work). `H` shows this list.

| Keys | Does |
| --- | --- |
| `c` | continue, or start a session |
| `n` `s` `fin` | next / step / finish |
| `u` | run to the cursor (place it first, outside the layer) |
| `f` | back to the current frame |
| `up` `do` | older / newer frame |
| `<CR>` | repeat the last of these |
| `r` | restart the session, or rerun the last one |
| `rc` `rn` (`rs` = `rn`) | reverse continue / reverse next (needs record or rr) |
| `b` `bc` `d` | toggle / conditional / delete breakpoint, saved to disk (`d` off a breakpoint: all of them, confirmed) |
| `bp` `bn` | previous / next breakpoint |
| `p` `w` | print / watch the word or the selection |
| `bt` `bq` | backtrace: widget / into quickfix |
| `t` `ib` `is` | threads / breakpoints / sessions |
| `e` | run the last yank or delete in the REPL |
| `q` | terminate the session and leave debug mode |
| `N` | new session |
| `U` | the sidepanel here, or go to it |
| `S` `T` `R` `W` `H` | panel: scopes / terminal / REPL / watches / help |
| `M` | move the current terminal into the panel |

In the panels: watches `a` add, `i` insert, `d` delete, `e` edit, `s` set the value, `c` copy,
`<CR>` expand, `r` refresh; breakpoints (`ib`) `c` condition, `d` delete, `<CR>` jump; scopes
`r` refresh; sessions (`is`) `<CR>` switch.

`c` with no session offers, for C/C++: launch binary, launch gtest (tests picked in fzf), open
core, attach pid. A `.liter.lua` starts one with `l.debug("cpp", …)`. yt tests attach on their own
through `$YT_GDB_ATTACH_COMMAND` (`lua/yt_gdb.lua`, notes/gdb-setup.md).

| Command | Does | From |
| --- | --- | --- |
| `:GdbBtQf`, `:GdbBtQfSelection` | a gdb backtrace in the buffer (or the selection) into quickfix, paths via `arc root` | config |
| `:PBToggleBreakpoint` `:PBSetConditionalBreakpoint` `:PBSetLogPoint` `:PBClearAllBreakpoints` | breakpoints that survive restarts (`:PBStore` `:PBLoad` `:PBReload` say they're deprecated) | persistent-breakpoints |
| `:DapContinue` `:DapNew` `:DapStepOver` `:DapStepInto` `:DapStepOut` `:DapPause` `:DapRestartFrame` `:DapTerminate` `:DapDisconnect` | the same without debug mode | nvim-dap |
| `:DapToggleBreakpoint` `:DapClearBreakpoints` | breakpoints, not saved to disk | nvim-dap |
| `:DapEval` | a `dap-eval://` buffer, `:w` evaluates it | nvim-dap |
| `:DapToggleRepl` `:DapShowLog` `:DapSetLogLevel` | REPL, adapter log | nvim-dap |

## Tasks

| Key / command | Does |
| --- | --- |
| `x` | every task from the `.liter.lua` files at and above the cwd; `[k]` is its key |
| `x` + key | run the task `map()`ped to that key |
| `xV` | pick a parameter's value, or add a new one |
| `xC`, `:LiterConfig` | edit the innermost `.liter.lua` |
| `xO` | the last task's output buffer |
| `xR` | re-run the last task |
| `xi` | fuzzy-search the tasks, `enter` runs |
| `:Liter [task]` | run by name; no argument: the layer |
| `<C-c>` in a `liter://` buffer | interrupt its task (twice: kill) |

The `liter_*` lua snippets write the boilerplate; the API is in `~/p/liter.nvim/readme.md`.

## Terminals & servers

| Key / command | Does | From |
| --- | --- | --- |
| `<Space>t` | a terminal in this window, with line numbers | config |
| terminal `<C-e>` | back to normal mode | config |
| `<CR>`, `:FzfConnect` | servers: a pinned char hops (starting a server that is down), a free char pins this one, `i` search, `ctrl-x` unpin | no-tmux |
| `:Connect` | hop to another live server, from a plain list | no-tmux |
| `<Space>m` | `:restart`: Neovim saves and restores the session itself, no question about running terminals | config |
| `:Restart` | restart keeping the layout, terminals left out, after listing them and asking | no-tmux |
| `:RestartAll` | every server, this one last | no-tmux |
| `:q` `:qa` | print `habit` in an `nt` server, `:q` only when it would end the session (`:NtQ` `:NtQa`); `:detach` leaves, `:qa!` quits | no-tmux |

Automatic: quitting with jobs still running asks first (`:qa!` overrides; what was killed goes
to `~/.local/state/nvim/killed-jobs.txt`). `nvim file` inside a `:terminal` opens here, and
`git commit` there waits for its message buffer (flatten). From fish: `nt [dir]` start or attach,
`nt --ls` list.

## Git

Git repos only (this config, `~/p/*`); arc work is under Arcadia. `?` inside lazygit lists its
keys.

| Command | Does |
| --- | --- |
| `:LazyGit` | lazygit in a float |
| `:LazyGitCurrentFile` | the same, in the current file's repository |
| `:LazyGitFilter` | the repository's commits |
| `:LazyGitFilterCurrentFile` | the commits that touched this file |
| `:LazyGitLog` | `lazygit log` |
| `:LazyGitConfig` | edit lazygit's config |

## Look

| Key / command | Does | From |
| --- | --- | --- |
| `<Space>s` | didecolors semantic highlighting on / off in this buffer | config |
| `<Space>n` | breadcrumbs winbar | navic |
| `:RenderMarkdown [cmd]` | markdown rendered in place: `toggle`, `buf_toggle`, `preview` (side by side), `expand` / `contract` (raw lines around the cursor) | render-markdown |
| `:IBLToggle` `:IBLEnable` `:IBLDisable`, `:IBLToggleScope` `:IBLEnableScope` `:IBLDisableScope` | indent guides | indent-blankline |
| `:ColorizerToggle` `:ColorizerAttachToBuffer` `:ColorizerDetachFromBuffer` `:ColorizerReloadAllBuffers` | `#rrggbb` in its own colour | colorizer |

Automatic: brackets coloured by depth (files up to 1 MiB, rainbow-delimiters); the statusline
(lualine).

## Housekeeping

| Command | Does | From |
| --- | --- | --- |
| `:Lazy [cmd]` | plugins: `sync`, `update`, `clean`, `restore`, `log`, `profile`, `health`, … | lazy |
| `:Reload` | apply init.lua and `plugin/` edits without a restart (plugin specs and deleted maps need one) | config |
| `:Keymaps` | the `<Space>` and `<BS>` maps in a sorted buffer | config |
| `:KeyReport` | what keys and commands got used; exists only while recording (`mkdir -p ~/.local/share/nvim/keylog`), off now | config |
| `:TSInstall` `:TSUpdate` `:TSUninstall` `:TSInstallFromGrammar` `:TSLog` | treesitter parsers (installed on their own at the first FileType) | nvim-treesitter |
| `:PlenaryBustedFile` `:PlenaryBustedDirectory` | run busted-style Lua specs | plenary |
| `:WhichKey [mode] [keys]` | the which-key popup on demand; inside it `<BS>` back, `<Esc>` close, `<C-d>` `<C-u>` scroll | which-key |

## Known not to work (checked 2026-10-14)

- zk-nvim: the `zk` CLI isn't installed, so `:ZkNew` `:ZkNotes` `:ZkTags` `:ZkIndex` `:ZkLinks`
  `:ZkBacklinks` `:ZkInsertLink` `:ZkInsertLinkAtSelection` `:ZkMatch` `:ZkNewFromTitleSelection`
  `:ZkNewFromContentSelection` `:ZkCd` `:ZkBuffers` all fail.
- `:TextCaseOpenTelescope`, `:TextCaseOpenTelescopeLSPChange`, `:TextCaseOpenTelescopeQuickChange`
  need telescope, which isn't installed.
- `<Space>f` in C/C++: none-ls's clang-format runs `ads-clang-format`, which is on no PATH (fish,
  or the running servers).

## Plugins

`~/p` = own plugin, loaded from the local checkout (github when there is none).

| Plugin | Gives you | Reach it |
| --- | --- | --- |
| arc.nvim (`~/p`) | arcadia in nvim: codesearch, PRs, review threads, tickets, blame, links | `<Space>a…`, `:Arc…` |
| debugmaster.nvim (`~/p`, fork) | debug mode and its panels, on nvim-dap | `<BS>` |
| fzf-pin.nvim (`~/p`) | the pin-a-char picker behind `s`, `x` and `<CR>` | `s` |
| liter.nvim (`~/p`) | tasks from `.liter.lua` files | `x`, `:Liter` |
| no-tmux.nvim (`~/p`) | a server per project, hops between them, `:Restart`, the quit guard | `<CR>`, `:Connect`, fish `nt` |
| pcre.nvim (`~/p`) | PCRE2 `/` and `:s` | `/`, `:S` |
| async.nvim | dependency of refactoring.nvim | |
| cmp-buffer | completion from buffer words | automatic |
| cmp-cmdline | completion on the `:` line | automatic |
| cmp-mini-snippets | snippets in the completion menu | automatic |
| cmp-nvim-lsp | completion from LSP | automatic |
| cmp-path | completion of file paths (pinned to d83839a) | automatic |
| comment.nvim | comment toggling | `gc`, `gb`, `<Space>/` |
| flatten.nvim | `nvim` inside `:terminal` opens in this instance | automatic |
| flit.nvim | `f` / `t` with labels, across lines | `f` `F` `t` `T` |
| fzf-lua | pickers, also behind `vim.ui.select` | `<Space>o` `g` `p` `l` `j`, `gd` `gr` `gi`, `:FzfLua` |
| indent-blankline.nvim | indent guides | automatic, `:IBL…` |
| lazy.nvim | plugin manager | `:Lazy` |
| lazydev.nvim | lua_ls knows the nvim API and the plugins a file requires | automatic, `:LazyDev` |
| lazygit.nvim | lazygit in a float | `:LazyGit…` |
| leap.nvim | the engine under flit; no keys of its own here | via flit |
| lsp_signature.nvim | the signature while you type arguments | automatic |
| lualine.nvim | statusline: mode (DEBUG in debug mode), file, diagnostics, LSP servers and progress | automatic |
| mini.nvim | only mini.snippets is set up; the other modules are installed but off | snippets via completion |
| none-ls.nvim | formatters as a language server: cmake_format, prettier, clang-format | `<Space>f`, `:NullLs…` |
| nvim-autopairs | closes brackets and quotes | automatic, insert `<M-e>` |
| nvim-cmp | completion | insert `<C-n>` `<C-p>` `<C-y>` `<C-e>`, `:CmpStatus` |
| nvim-colorizer.lua | colour codes shown in their colour | automatic, `:Colorizer…` |
| nvim-dap | debugger client (gdb speaks DAP itself) | debug mode, `:Dap…` |
| nvim-lspconfig | server configurations for `vim.lsp.enable` | automatic |
| nvim-navic | the current scope, for the winbar | `<Space>n` |
| nvim-treesitter | parsers, installed on first use | automatic, `:TS…` |
| oil.nvim | directories as editable buffers | `<Space>w`, `-`, `:Oil` |
| persistent-breakpoints.nvim | breakpoints survive restarts | debug-mode `b`, `:PB…` |
| plenary.nvim | Lua library for lazygit.nvim and none-ls | `:PlenaryBusted…` |
| rainbow-delimiters.nvim | brackets coloured by depth | automatic |
| refactoring.nvim | extract / inline variables and functions | `:Refactor` |
| render-markdown.nvim | markdown rendered in place | automatic, `:RenderMarkdown` |
| text-case.nvim | case conversion, case-aware replace | `ga…`, `:Subs` |
| undotree | the undo tree | `<Space>u` |
| vim-repeat | `.` repeats plugin actions | automatic |
| which-key.nvim | the next keys after a 2 s pause | automatic, `:WhichKey` |
| zk-nvim | zk notebooks; the `zk` CLI is missing | `:Zk…` |

Not loaded: quicker.nvim is on disk but commented out in init.lua; `lua/plugins/ayu.lua`
(neovim-ayu) is not in the `lazy.setup{}` list.
