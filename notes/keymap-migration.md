# Migration des keymaps du 2026-08-25

Faite à partir de `keyreport_25_08.txt` (deux mois de `:KeyReport`). Si un keymap que vous
cherchez manque, il est dans le premier tableau : tapez la commande à la place.

## Keymaps supprimés → commande à taper

| Ancien keymap | Usages | Commande |
| --- | --- | --- |
| `<Space>a` code action (n + v) | 21 | `:CodeAction` (accepte un range en visuel) |
| `<Space>t` oil sur le projet | 11 | `:Oil .` — `<Space>t` ouvre maintenant un terminal |
| `<Space>u` undotree | 11 | `:UndotreeToggle` |
| `<Space>g` grep dans le buffer | 1 | `:FzfLua grep_curbuf` |
| `<Space>zn` / `zi` / `zb` zk | 0 | `:ZkNew`, `:ZkInsertLink`, `:ZkBacklinks` |
| `<Space>rs` rip-substitute | 0 | `:S` (pcre) — le plugin rip-substitute est retiré |
| `<Space>y` keymaps dans un buffer | 0 | `:Keymaps` |
| `<Space>?` which-key buffer-local | 0 | `:WhichKey '' n` |

Gardé malgré 1 usage : `<C-l>` de pcre, qui efface les surlignages pcre avant le `:noh` — le
`<C-l>` intégré ne le ferait pas.

## Commandes → nouveaux keymaps

| Commande | Usages | Keymap |
| --- | --- | --- |
| `:CopyLoc` | 122 | `<Space>y` |
| `:terminal` | 103 | `<Space>t` |
| `:ArcBlame` | 53 | `<Space>ab` |
| `:ArcPrBlame` (ex-`:ArcBlamePr`) | 27 | `<Space>ac` |
| `:ArcDiff` | 53 | `<Space>ad` |
| `:ArcPrDiff` | 15 | `<Space>ae` |
| `:ArcLinkCreate` | 20 | `<Space>al` |
| `:ArcPrView` | 1 | `<Space>ap` |

Règle du préfixe `<Space>a` : la lettre suivante fait la même chose sur la PR au lieu du
checkout (`ab`/`ac`, `ad`/`ae`). Dans arc.nvim, `:ArcBlamePr` a été renommé `:ArcPrBlame` pour que
toutes les commandes PR commencent par `ArcPr`.

Restées en commandes, trop rares : `:Diff`, `:ArcFzfPrFiles` (12), `:ArcFzfDirty`, `:ArcPrIssues`,
`:ArcLinkOpen`, `:ArcBlameLine`, `:ArcFzfCs`, `:Pcre` (23), `:Restart` (30, `<Space>m` fait pareil).
