# ripgrep-regex buffer search in Neovim — research notes

_Saved 2026-06-15_

## What I wanted

I like `nvim-rip-substitute` (chrisgrieser) because it searches with **modern
regex** instead of arcane vim regex. But it only does search **and replace**. I
usually *just search*, and I want to do that with ripgrep-style regex syntax —
ideally with native-feeling `n`/`N` navigation through matches in the current
buffer.

## Which regex syntax does ripgrep actually use?

Two engines — important not to conflate them:

- **Default `rg`** uses the Rust [`regex`](https://docs.rs/regex) crate: a
  finite-automata engine (linear time, no catastrophic backtracking). Syntax is
  very PCRE-*like* — `\d \w \s`, `[...]` classes, `*+?{n,m}`, `|`, `^$` anchors,
  groups, named captures `(?<name>...)`. **No backreferences and no lookaround**
  (`(?=...)`, `(?<=...)`, `(?!...)`), by design.
- **`rg -P` / `rg --pcre2`** swaps in the PCRE2 library, which *adds* lookaround
  and backreferences. It's opt-in via the flag — ripgrep is **not** PCRE2 by
  default.

`nvim-rip-substitute` gives PCRE2 because **the plugin sets the flag for you**
(`regexOptions.pcre2 = true` by default; setting it `false` drops features "like
lookaheads"). That's the plugin's choice, not ripgrep's default.

Upshot: only reach for `--pcre2` if you actually need lookaround/backrefs.
Otherwise plain `rg` (Rust regex) already gives the modern, non-vim syntax —
and it's faster with no backtracking risk.

## Bottom line

**No off-the-shelf plugin does exactly this.** There is nothing that combines:

- search-only (no replace),
- in the current buffer,
- with ripgrep regex syntax (Rust regex, or PCRE2 via `--pcre2`),
- and `n`/`N` cursor navigation like native `/`.

Every ripgrep-regex-in-buffer plugin is replace-oriented, and every
`n`/`N`-navigation plugin uses Vim's regex engine. (Neovim's native `/` is
locked to vim regex and can't be swapped for ripgrep's engine — getting
ripgrep syntax requires shelling out to `rg`.)

## Closest existing options

### Gets ripgrep regex, but no n/N
- **nvim-rip-substitute** (already installed, `<leader>rs`) — open it, type a
  pattern in the *search* field, leave *replace* empty. It live-highlights every
  match in the buffer with a live match count. De-facto ripgrep search (PCRE2 by
  the plugin's default); just doesn't move the cursor through matches.
  https://github.com/chrisgrieser/nvim-rip-substitute
- **grug-far.nvim** — full ripgrep find-and-replace, can be scoped to the
  current buffer; results in a side window you jump from. Heavier,
  replace-oriented, but the most "real ripgrep search" of a buffer.
  https://github.com/MagicDuck/grug-far.nvim

### Gets n/N navigation, but Vim regex (not ripgrep)
- **improved-search.nvim** — stable next/prev, search word under cursor without
  moving, etc. https://github.com/backdround/improved-search.nvim
- **vim-side-search** — ripgrep results in a side buffer with `n`/`N` mappings to
  step through them (project grep, not the in-place `/` feel).
  https://github.com/ddrscott/vim-side-search

## The two realistic paths

1. **Accept rip-substitute-with-empty-replace** as the "ripgrep search" and live
   without cursor navigation.
2. **Build a small custom command** (~80 lines): prompt for a pattern via
   `vim.ui.input`, run `rg --json` over the current buffer content (via stdin) —
   add `--pcre2` only if lookaround/backrefs are wanted — parse match positions
   from the JSON `submatches` (byte offsets), set extmark highlights on every
   match, jump to the next match after the cursor, and bind `n`/`N`
   (buffer-local) to cycle through the match list with `<Esc>` to clear. This is
   the **only** way to get both ripgrep syntax *and* native-search navigation,
   since it doesn't exist as a plugin.
   - nvim is 0.13-dev here, so `vim.system{ ..., stdin = text }` is available.
   - rg 15.1.0 is installed; default engine is Rust regex, `--pcre2` opts into
     PCRE2.

## Status

Decision left open: build the custom command, or stick with
rip-substitute-empty-replace for now.
