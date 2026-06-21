# Ideas

## Плагины, которые возможно стоит добавить:
- https://github.com/Wansmer/treesj (or splitjoin.nvim)
- https://github.com/nvim-treesitter/nvim-treesitter-textobjects
- https://github.com/JoosepAlviste/nvim-ts-context-commentstring
- https://github.com/A7Lavinraj/fyler.nvim
- https://arcanum.yandex-team.ru/arcadia/junk/magnickolas/arcblamer.nvim
- плагины tpope
- плагины chrisgrieser
- подумать, стоит ли заменить render-markdown на markview


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


## Работа со списками
### Примеры списков
- все файлы, измененные в пулреквесте
- список интересных файлов
- бэктрейс
- ишьюс
- дефолтные: греп и rg

### Функционал
- jumplist: пользоваться не только C-j и C-k
- сохранять списки


## Другое
- можно ли сделать форматирование с помощью nvim-treesitter
- подумать про буфер обмена (копировать в регистры, разобраться в какие регистры копируется и как этим нормально пользоваться)
- https://www.reddit.com/r/neovim/comments/1pqks2r/edit_any_macos_text_field_in_neovim_with_a/
- статистика использования hotkeys
- go to definition of the function/class you are currently inside
- clang-format selected lines
- disable inline-hints (чтобы проверить отступы)


### скрипт/по хрону строить протобуфы и compile_commands.json
compile_commands.json в a/yt a/util a/library/cpp

### Buffer-specific wrap setting (pull-request to neovim)
- is this feature wanted?

### vim-regex is stupid? https://github.com/chrisgrieser/nvim-rip-substitute
- rewrite it to support pure search, n/N, * (search under cursor)
- do I need regex syntax highlighting? (and thus a window instead of command line (though jumping between search/replace may be useful))
https://github.com/google/re2/wiki/Syntax?clckid=4161aae6

### enhance debugmaster 
https://github.com/MironPascalCaseFan/debugmaster.nvim/blob/main/doc/designphilosophy.md
- keys that are used now are not gdb-like
- настроить для unit-test'ов arcadia

### work/personal 
https://www.reddit.com/r/neovim/comments/1gesejh/comment/lucx4zy/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
- важно что когда лежит сервер ya tool c++ не работает
- как определять режим? если по имени пользователя/компьютера, то нельзя делиться конфигом в/вне яндекса, нельзя менять
- ya tool ads-clang-format: перестать опираться на ya, хочется пользоваться даже когда ya лежит


## User stories
### arc and ya make
arc co releases/yt/stable/26.1
arc co app/build-cache/hot
arc cherry-pick
ya make -A -F ...
ya make -L -F ...
ya make -A --pytest-args="-rP -vv --log-level=ERROR"

#### Merge to release
arc co releases/yt/stable/26.1
arc cherry-pick <commit>
arc submit -m "[26.1] <Cherry-picked pull-request> name"

### python tests, run and look to logs/stdout
ya make -A --pytest-args="-rP -vv --log-level=ERROR"
cd very/long/path/of/directory/with/stdout
(vim stdout) || (cd TestName/logs; (rg||vim) http-proxy-log.debug.log)

### Can't escape browser
#### Blame
reading code in neovim
want to find blame, :ArcanumLink
jump to pull request (or look at the code prior to it)
now i'm reading code in the browser, no easy way to go back to vim
#### Code search
same as previous but starts from code search
##### Solution
at least searching inside arc/yt should be easy, and whole arcadia should be searchable the same way
telescope picker is worse than cs.y-t.ru
- filename is very long
- window is narrow
- line doesn't fit
- lines are not left-aligned


## Thoughts
Nvim = text editor + tmux + different tui (lazygit). Can it be used instead of tmux?
