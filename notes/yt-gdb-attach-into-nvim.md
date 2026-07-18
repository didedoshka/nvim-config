# Routing yt's attach_gdb into nvim-dap

`yt/yt/tests/library/gdb_helpers.py:attach_gdb` spawns

    tmux new-window "ya tool gdb -p <pid> -ex '<user ex>' -ex 'source <tmpdir>/prologue.gdb' -ex 'resume'"

then blocks until `<tmpdir>/init_barrier` appears. Attaching freezes the test
process, so the barrier can only ever be released from outside — which is why
`~/.config/nvim/gdb/nvim-dap-attach <pid> <barrier>` is all the editor side needs.

Preferred route is the trunk PR: an `YT_GDB_ATTACH_COMMAND` env var with `{pid}`
and `{barrier}` placeholders, defaulting to today's tmux window.

## If that PR is rejected

Shim `tmux` earlier in `$PATH`; no trunk change needed. What matters:

- Match on `$1 = new-window` **and** `$2` containing `ya tool gdb -p`; `exec` the
  real tmux for everything else, or unrelated `new-window` calls get swallowed.
- pid: scrape `-p <n>` out of `$2`.
- barrier: **not in the command line.** Derive it — `dirname` of the
  `source .../prologue.gdb` argument, plus `/init_barrier`. That prologue path is
  the only trace of the tmpdir in the command, and both files are built from the
  same `create_tmpdir("gdb")`.

Verified working 2026-07-19 (intercept + faithful passthrough) — the derivation
above is the whole trick, the rest is a dozen lines of sh.
