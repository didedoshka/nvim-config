# Ideas
## TODO
- подумать про буфер обмена (копировать в регистры, разобраться в какие регистры копируется и как этим нормально пользоваться)
- по крону обновлять нужные ya tool, делать симлинки на низлежащий инструмент
- сделать красивый markdown (см. markview)
- как открывать ссылку в браузере?
- fzf-lua grep in current directory/specify directory. :Cs as well

## debugmaster.nvim/gdb
- Running binary by specifying its full path is tedious: brd is needed
- don't show dap "the adapter is slow message"
- <Tab>-prefix doesn't work in debugmaster's panels
- backtrace (and other windows) have no borders
- would be nice to dump backtrace to quickfixlist/fzf-lua, like gdb_qf_bt


## Плагины, которые возможно стоит добавить:
- https://github.com/Wansmer/treesj (or splitjoin.nvim)
- https://github.com/nvim-treesitter/nvim-treesitter-textobjects
- https://github.com/JoosepAlviste/nvim-ts-context-commentstring
- https://github.com/A7Lavinraj/fyler.nvim
- https://arcanum.yandex-team.ru/arcadia/junk/magnickolas/arcblamer.nvim
- плагины tpope
- плагины chrisgrieser
- подумать, стоит ли заменить render-markdown на markview
- https://github.com/tiagovla/scope.nvim


## BRD
- посмотреть на альтернативы
    - https://github.com/tpope/vim-dispatch
- подумать над редизайном
    - цепочки команд
    - установка переменных (флагов итд) и их выбор


## didecolors
- не обрабатывать весь файл при запуске, вим зависает
- разобраться как работает treesitter highlight в исходниках neovim
    - для этого установить https://www.reddit.com/r/neovim/comments/1h43mjj/snacksprofiler_a_neovim_lua_profiler/
- доделать для любой темы, выложить, сделать плагином
- починить баг, что цвета не обновляются в строках, которые не изменились, но изменили семантику (цветной if, цветной private)
- https://github.com/nvim-mini/mini.base16/tree/main
- make fzf-lua more colorful (including preview)


### скрипт/по хрону строить протобуфы и compile_commands.json
compile_commands.json в a/yt a/util a/library/cpp

### vim-regex is stupid? https://github.com/chrisgrieser/nvim-rip-substitute
- rewrite it to support pure search, n/N, * (search under cursor)
- do I need regex syntax highlighting? (and thus a window instead of command line (though jumping between search/replace may be useful))
https://github.com/google/re2/wiki/Syntax?clckid=4161aae6

### work/personal 
https://www.reddit.com/r/neovim/comments/1gesejh/comment/lucx4zy/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
- важно что когда лежит сервер ya tool c++ не работает
- как определять режим? если по имени пользователя/компьютера, то нельзя делиться конфигом в/вне яндекса, нельзя менять
- ya tool ads-clang-format: перестать опираться на ya, хочется пользоваться даже когда ya лежит



## Keys that can start a layer in normal mode
<BS> -- currently debugmaster (mode toggle + one-shot prefix)
s -- currently arrow
<Tab> -- currently <C-w>
x
<Esc>
<Cr>


## Thoughts
Nvim = text editor + tmux + different tuis (like lazygit). Can it be used instead of tmux?
