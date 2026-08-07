# Éditer la ligne de commande du terminal comme du texte Neovim — handoff

Handoff d'une conversation Claude (2026-08-07) sur les raccourcis dans le `:terminal`.

## Contexte et décisions

- fish tourne avec `fish_vi_key_bindings` (config.fish:17). Discussion : dans un `:terminal`, le mode
  vi de fish fait double emploi avec le mode terminal-normal de nvim (`<C-e>`). Alternatives évoquées :
  `fish_hybrid_key_bindings`, ou revenir à `fish_default_key_bindings` et laisser nvim porter le côté vi.
  Rien n'a été changé côté fish — décision reportée.
- Le buffer terminal n'est pas éditable par nature : la ligne de commande vit dans la mémoire de fish,
  nvim ne fait qu'en afficher le rendu. Le pont officiel est `edit_command_buffer` de fish (ouvre
  `$EDITOR` sur la ligne de commande), lié à `alt-e`/`alt-v` — **intapable ici : alt-e produit `é`**
  (disposition clavier avec lettres accentuées).

## Fait dans cette session

- **flatten.nvim installé** (`lua/plugins/flatten.lua`, commit `da36d3f`) : un nvim lancé dans un
  `:terminal` ouvre ses fichiers dans l'instance hôte au lieu de s'imbriquer.
- **Wrapper `~/.local/bin/nvim-wait`** (hors dépôt) : `exec nvim --cmd "let g:flatten_wait=1" "$@"`.
  Le `g:flatten_wait` force flatten à bloquer l'invité jusqu'à la fermeture du buffer dans l'hôte —
  indispensable pour tout outil qui attend la fin de `$EDITOR` (ctrl-g de Claude Code,
  `edit_command_buffer`, git commit). Hors nvim, la variable est inoffensive.
- `EDITOR` et `VISUAL` (variables universelles fish) pointent sur `nvim-wait`.
- Vérifié headless : l'invité transmet le fichier à l'hôte et bloque ; `:bdelete` côté hôte le libère.
- **Piège** : les shells déjà ouverts (et le serveur no-tmux) ont hérité l'ancien `EDITOR=nvim`, qui
  masque la variable universelle. Il faut redémarrer le serveur (ou `set -gx EDITOR nvim-wait` dans les
  terminaux existants) pour que ctrl-g dans Claude Code voie `nvim-wait`.

## Idée pour plus tard : `a`/`i` en mode terminal-normal → buffer d'édition de la commande

Comportement voulu : dans le `:terminal` en mode terminal-normal, taper `a` ou `i` n'entre pas en mode
terminal mais ouvre un buffer nvim contenant la ligne de commande fish courante ; on l'édite comme du
texte ordinaire, on ferme, fish récupère la commande.

Piste d'implémentation :

- Côté fish : lier `edit_command_buffer` à une séquence intapable au clavier, p. ex.
  `bind \e\[999~ edit_command_buffer` (les modes vi ont leurs propres tables `bind -M`).
- Côté nvim : keymap terminal-normal (`n` local au buffer terminal, `TermOpen` autocmd) pour `a`/`i` qui
  envoie cette séquence au job : `vim.api.nvim_chan_send(vim.b.terminal_job_id, seq)`. fish déclenche
  `edit_command_buffer` → `$EDITOR` = `nvim-wait` → flatten ouvre le buffer dans l'hôte. Toute la
  tuyauterie de cette session sert telle quelle.
- Questions ouvertes : comment rentrer en mode terminal « brut » si `a` et `i` sont pris (garder `A` ?) ;
  ne mapper que quand le job est fish (inspecter `b:term_title` ?) ; et `a` vs `i` pourraient placer le
  curseur différemment dans le buffer (après/avant le caractère courant, via `commandline -C`).
