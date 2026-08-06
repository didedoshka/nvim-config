# Обновление ya tools по крону + симлинки — implemented (needs 2 commands)

`crontab` is **forbidden for your user on this box** ("You (dagorokhov) are not allowed
to use this program"), so this is a systemd **user timer** instead. It automates the
pattern you already started by hand with `ads-clang-format` → `~/.local/cellar/`.

Installed:

- `~/.local/bin/ya-tool-refresh` — for each tool in the list at the top
  (`cs ruff ads-clang-format`, edit to taste): resolves the real binary with
  `ya tool <t> --print-path`, copies it into `~/.local/cellar/<t>/<t>` (only when
  changed, atomically), and symlinks `~/.local/bin/<t>` to the copy. The copy is the
  point: ya GC can delete old `~/.ya/tools` versions, the cellar copy survives, so the
  tool works even when ya's backend is down.
- `~/.config/systemd/user/ya-tool-refresh.service` + `.timer` — daily, `Persistent=true`
  (catches up after reboots), randomized ±1h.

The permission sandbox wouldn't let me chmod/enable, so run once:

```
! chmod +x ~/.local/bin/ya-tool-refresh && ~/.local/bin/ya-tool-refresh
! systemctl --user daemon-reload && systemctl --user enable --now ya-tool-refresh.timer
```

Natural follow-up (not done): once `~/.local/bin/ruff` exists, `lspconfig.lua` could use
`{ vim.fn.expand("~/.local/bin/ruff"), "server" }` instead of `ya tool ruff server` — then
the ruff LSP also survives ya being down (the `-- важно что когда лежит сервер ya tool
c++ не работает` item).
