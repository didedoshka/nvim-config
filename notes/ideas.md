# Plans, tasks
S = short-term L = long-term

## Config
L commit to no-tmux setup
    L use terminals inside of nvim better (fzf to open terminal in specified directory, for example)
    S leave terminal mode ~on enter~, on command start
L read done_todo_19_07.md
S don't create KeyReport in new tab
L analyze KeyReport and redo mappings (need to collect more data, one-two weeks)
L start using litre.nvim
L restructure
L enhance render-markdown
L improve start time


## PCRE
S when search moves the screen didecolors semantic highlighting starts working only after pressing enter
S insert mode breaks if inserted the matching stirng


## debugmaster/gdb/dap
S run zz on next/step
S if file with breakpoint wasn't open, persistente breakpoint didn't load?
S `p` is inconcistent with lsp `K`. Only way to close `K` window is to move cursor, only way to close `p` is `q`. Maybe it's fine, because i can't move cursor in debug mode, but i keep pressing `<esc>`
S fzf-lua with breakpoints


## arc-worktree
L По хрону пуллить hot, запускать regen
S block until clangd regenerates, tell the progress, tell that it ended/exited with error
L create a command that allows to change the worktree (`~/a/hot/yt/yt/http` -> ~/a/28581/yt/yt/http)


## litre
L lsp doesn't work nicely in .litre.lua. Maybe make env/param upper-case, or do `l = require "litre"` in the beginning of .litre.lua files?
L xx is definetly a bad idea for a picker, xs maybe, or x<cr>
L which-key doesn't work after x


## arc
S An issue is a pull request issue, ticket is a ticket. Now tickets are called issues for some reason. Needs to be changed
L no diff in PR view

### Compare to analogues
Maybe it's better to fork one of them (or maybe extend if possible (or maybe make a pull request that makes it extensible)) than writing our own thing
- https://github.com/justinmk/guh.nvim (i like this one because justinmk is nvim's main maintainer)
- https://github.com/harrisoncramer/gitlab.nvim
- https://github.com/pwntester/octo.nvim
- other analogues

### User story
Task: implement a feature that is similar to another feature
What I do: press "View blame prior to this change" until i find the pull request that added the feature, saving (havind open) the pull requests that changed it through time


## Плагины, которые возможно стоит добавить:
L https://github.com/Wansmer/treesj (or splitjoin.nvim)
L https://github.com/A7Lavinraj/fyler.nvim
L плагины tpope
L плагины chrisgrieser
L https://github.com/tiagovla/scope.nvim (tab scoping, i don't use tabs)


## didecolors
S большие файлы все еще долго открываются, возможно из-за rainbow delimeters
L разобраться как работает treesitter highlight в исходниках neovim
L   - для этого установить https://www.reddit.com/r/neovim/comments/1h43mjj/snacksprofiler_a_neovim_lua_profiler/
L доделать для любой темы, выложить, сделать плагином
L починить баг, что цвета не обновляются в строках, которые не изменились, но изменили семантику (цветной if, цветной private)
L https://github.com/nvim-mini/mini.base16/tree/main

### make things more colorful
L fzf-lua (including preview)
L lualine
L something else?


## work/personal 
https://www.reddit.com/r/neovim/comments/1gesejh/comment/lucx4zy/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
L важно что когда лежит сервер ya tool c++ не работает
L как определять режим? если по имени пользователя/компьютера, то нельзя делиться конфигом в/вне яндекса, нельзя менять
L ya tool ads-clang-format: перестать опираться на ya, хочется пользоваться даже когда ya лежит


# Notes
## Keys that can start a layer in normal mode
<BS> -- currently debugmaster
s -- currently arrow
<Tab> -- currently <C-w>
x -- currently litre
<Esc>
<Cr>

