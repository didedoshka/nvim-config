# Commandes et raccourcis ajoutés par Claude (depuis la mi-mai 2026)

Recensement par historique git : les commits co-signés `Co-Authored-By: Claude` ne commencent que le
8 juillet — tout ce qui est antérieur (mi-mai → début juillet : telescope→fzf-lua, hardtime, undotree,
`:ArcanumLink` initial, etc.) est de didedoshka et n'est pas listé ici.

## Config nvim (`~/.config/nvim`)

### Commandes

| Commande | Ce qu'elle fait |
| --- | --- |
| `:CopyLoc` (range) | copie `chemin/absolu:ligne` (ou `:l1-l2` en visuel) dans le registre `+` |
| `:GdbBtQf` | parse une backtrace GDB (clipboard) en quickfix, racine résolue via `arc root` |
| `:GdbBtQfSelection` | idem, sur la sélection visuelle |
| `:KeyReport` | affiche le comptage des touches/commandes réellement utilisées (keylog, opt-in) |
| `:Restart` | `:restart` en conservant le layout — session sauvée puis re-sourcée (terminaux exclus) |
| `:Connect` | bascule l'UI vers le serveur nvim d'un autre projet (analogue de tmux switch-client) |

### Raccourcis

| Touche | Ce qu'elle fait |
| --- | --- |
| `gd` / `gi` | définitions / implémentations LSP via fzf-lua, pour ne plus écraser la quickfix |
| `<C-f>` (dans les pickers fzf files/grep) | rouvre le picker dans le répertoire du buffer courant, en gardant la requête (port du comportement telescope) |
| `<bs>` (normal **et** visuel) | entre en mode debug (debugmaster) ; `<Esc>` en sort |
| `x` | layer litre (voir litre.nvim ci-dessous) |
| `/`, `n`, `N` | repris par pcre.nvim (voir ci-dessous) ; `*` `#` `g*` `g#` restent natifs mais purgent d'abord les highlights pcre |

Aussi : les quatre configs DAP gdb (`launch binary`, `launch gtest` avec picker fzf des tests,
`open core`, `attach pid`) — pas des raccourcis, mais des entrées de `vim.ui.select` au lancement du debug.

## arc.nvim (`~/personal/arc.nvim`)

Plugin entier développé pendant les passes de juillet (le `:ArcanumLink` de base, juin, était à vous ;
`:Cs`/`:Prs` d'origine ont été refondus puis renommés).

### Commandes

| Commande | Ce qu'elle fait |
| --- | --- |
| `:FzfCs [flags]` | codesearch live (`ya tool cs`), hits sur deux lignes, `ctrl-q` → quickfix |
| `:FzfPrs [args]` | picker de PRs (`arc pr list`, défaut `-o`) |
| `:PrView [id]` | la PR en buffer markdown : checks, description, conversations en arbres |
| `:PrDiff [id]` | le diff réel de la PR (merge-base → head), `<cr>` saute au file:line |
| `:FzfPrFiles [id]` | fichiers modifiés de la PR → picker avec preview |
| `:PrIssues[!] [id]` | issues de review non résolues (avec `!` : toutes) → quickfix |
| `:PrWatch [id]` | `arc pr status --follow` dans un split terminal |
| `:Diff [args]` | diff des changements non commités (`arc diff HEAD`), `<cr>` saute |
| `:FzfDirty` | fichiers modifiés du working tree (`arc status`) → picker |
| `:FzfIssues [query]` | picker de tickets tracker (défaut : mes tickets non résolus) |
| `:Issue <key>` | un ticket en buffer markdown (résumé, description, commentaires) |
| `:Blame` | blame virtuel par blocs (auteur · date · résumé · PR), toggle |
| `:BlameLine` | blame de la ligne courante, en simple message |
| `:BlamePr` | ouvre directement la PR qui a introduit la ligne courante (`:PrView`) |
| `:ArcanumLink` (range) | permalien épinglé au commit (`?rev=…#L…`) → clipboard |
| `:ArcanumLinkTrunk` (range) | même lien sans épinglage |
| `:ArcanumOpen [url]` | sens inverse : URL arcanum (arg ou clipboard) → fichier dans le mount |
| `:Refs` (range) | extrait les références `path:line` d'un texte quelconque → quickfix |

### Touches dans les surfaces

| Où | Touche | Action |
| --- | --- | --- |
| picker `:FzfPrs` | `enter` / `ctrl-d` / `ctrl-f` / `ctrl-o` / `ctrl-y` | view / diff / fichiers / checkout / yank URL |
| picker `:FzfIssues` | `ctrl-p` / `ctrl-y` | PRs du ticket / yank URL tracker |
| buffer `:PrView` | `<cr>` / `R` / `X` / `q` | sauter au file:line / répondre au commentaire sous le curseur / résoudre-rouvrir / fermer |
| buffers scratch | `q` | fermer |

## pcre.nvim (`~/personal/pcre.nvim`)

Plugin entier (créé le 20 juillet) : `/` et `:s` avec regex PCRE2 via libpcre2 en FFI.

| Commande / touche | Ce qu'elle fait |
| --- | --- |
| `/` | recherche pcre : prompt sur la vraie cmdline, incsearch respecté, compteur `[cur/total]` |
| `n` / `N` | match suivant/précédent (re-exécutent le pattern ; retombent sur le natif hors recherche pcre) |
| `:[range]S/pat/repl/flags` | substitute PCRE2, sémantique vim (flags `g` `c` `i`, groupes `$1`/`${name}`), branché sur 'inccommand' |
| `:s` `:%s` `:'<,'>s` `:12,34s` | réécrits en `:S` à la volée (`substitute_abbrev`) ; le natif reste via `:su` |
| `:Pcre` | toggle pcre off/on pour comparer avec le moteur de vim ; `:S` reste pcre |
| dans le prompt : `<Up>/<Down>/<C-p>/<C-n>` | historique de recherche ; `<C-r>{reg}` insère un registre (newlines aplaties) |

## litre.nvim (`~/personal/litre.nvim`)

Task runner impératif (brd v2), fichiers `.litre.lua`.

| Commande / touche | Ce qu'elle fait |
| --- | --- |
| `:Litre [tâche]` | lance une tâche (picker sans argument) |
| `:LitreConfig` | ouvre le `.litre.lua` le plus proche |
| `x` (layer) | `x<touche>` tâche `map()`ée · `xx` picker · `xv` params · `xc` config · `xo` dernière sortie · `xr` relancer · `xk` tuer |

## debugmaster.nvim (`~/personal/debugmaster.nvim`)

Schéma modal « gdb » complet (`cfg.keymaps = "gdb"`), activé dans le config par `<bs>` / quitté par `<Esc>`.

| Touches | Action |
| --- | --- |
| `c` / `n` / `s` / `fin` | continue / next / step / finish |
| `f` / `u` | focus frame courante / run to cursor (until) |
| `up` / `do` | frame plus ancienne / plus récente |
| `r` / `<CR>` | rerun / répéter la dernière commande d'exécution |
| `rc` / `rs` / `rn` | reverse continue / step / next (record ou rr) |
| `b` / `bc` / `d` | toggle breakpoint / breakpoint conditionnel / supprimer (ligne, sinon tous avec confirmation) |
| `[b` / `]b` | breakpoint précédent / suivant |
| `p` | print du mot ou de la sélection |
| `bt` / `bq` | backtrace en widget / **backtrace → quickfix** |
| `t` / `w` | threads / watch le mot ou la sélection (ouvre le panel watches) |
| `ib` / `is` | info breakpoints / info sessions |
| `e` | exécuter le dernier yank/delete dans le repl |
| `q` / `N` | terminer la session et sortir / nouvelle session |
| `U` / `F` | toggle sidepanel / mode flottant |
| `S` / `T` / `R` / `H` / `W` | scopes / terminal / repl / aide / watches |
| `M` / `>` `<` / `-` `+` | déplacer le terminal / faire tourner le sidepanel / redimensionner |
| panel watches : `a` `i` `d` `e` `s` `c` `<CR>` `r` | ajouter / insérer / supprimer / éditer / set valeur / copier / plier-déplier / rafraîchir |

En plus du schéma : `keys.oneshot(prefix)` (une commande debug sans entrer dans le mode) et la
persistance des breakpoints via persistent-breakpoints.nvim quand il est installé.
