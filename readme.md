# didedoshka's neovim config

My minimalistic config for neovim.

## Goals

1. It should look and feel like vim, using vim workflow. It shouldn't be cluttered up with information and popups everywhere. 
2. I should understand every line of lua config that's written.

## Plugins

The full list of installed plugins is the `lazy.setup{}` table in `init.lua`, plus `lua/plugins/`. A couple of notes:
- refactoring.nvim (:Refactor)
- text-case.nvim (:Subs, gas - snake, gac - camel, gad - dash)

Arcadia work inside nvim (codesearch, PRs, tracker issues, blame) lives in its own plugin: `~/personal/arc-nvim`, loaded via a local `dir` spec in `init.lua`.

## Tests

`./tests/run.sh` — lints the config and loads it headlessly, offline, in about a second. One tier
runs under `nvim --clean` with no plugins (so it works on a fresh clone); the other loads the real
`init.lua` and checks what it actually defines, autosave included.

You can find the list of ideas [here](notes/ideas.md)
