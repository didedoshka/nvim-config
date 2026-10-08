# Two-monitor single-window setup (handoff)

Goal: one nvim session whose splits span both monitors, as part of the nvim-as-tmux plan (see
`nvim-as-tmux.md`). Monitors: portrait external 1200x1920 (main, on top), MacBook 1728x1117 below.
Stack: iTerm2 + ssh + nvim; tmux being phased out.

## Why not two windows

Neovim cannot give two UIs independent views of one session: all attached UIs mirror one global
window layout. Feature request closed as dup of neovim/neovim#2161 (open since 2015, `complexity:high`,
nobody working on it). Grouped tmux sessions were rejected: the whole point is moving between nvim
splits across monitors, which requires one OS window. So: one giant iTerm window spanning both screens.

## macOS constraints discovered (the hard way)

- "Displays have separate Spaces" must be OFF (System Settings → Desktop & Dock → Mission Control),
  requires re-login. Check: `defaults read com.apple.spaces spans-displays` → 1.
- Every scripted resize path (AppleScript/System Events, Hammerspoon `setFrame`, iTerm2 Python API
  `async_set_frame`) is clamped to one display. Borderless/No Title Bar doesn't help.
- Rules reverse-engineered from manual behavior:
  - A dragged resize edge cannot cross a display boundary.
  - A window "belongs" to the display holding most of its area; resizing while majority-on-the-lower
    screen (or dragging the TOP edge, or moving an already-spanned window) snaps it to that screen.
  - Drag-MOVES can straddle the boundary; scripted position changes to a straddling frame snap.
- Working recipe: full-height on portrait → drag-move down by a nudge so the bottom edge crosses →
  drag the bottom edge to the laptop bottom. Never touch the top edge afterwards.
- Synthetic drags need `hs.mouse.absolutePosition` first + `mouseEventClickState=1` on every event.
- Minimum working nudge: 34 px → permanent dead strip at the top (~1.1%). All reclaim attempts snap.
  The only true bypass is yabai's scripting addition (SkyLight private API), which needs SIP partially
  disabled — off-limits on a work MacBook.
- Menu bar auto-hide is ON (System Settings → Control Center) to recover its 24 pt; with it, `TOP_Y = 0`
  works and the title-bar grab offset must clear the menu-bar reveal zone. Net vs the old two-window
  setup: ~10 pt worse, in exchange for cross-monitor nvim splits.

## Final implementation

- `~/.hammerspoon/span.lua`: `spanITerm()` = setFrame full-height on portrait (`TOP_Y = 0`), synthetic
  title-bar drag down `NUDGE = 34`, synthetic bottom-edge drag to `BOTTOM_Y = 3036`. Bound to
  `hammerspoon://span`. Loaded from init.lua via `require("span")` (init.lua also does keypress logging —
  don't touch that part).
- Trigger: `open -g "hammerspoon://span"` (CLI, Raycast script command, or Hammerspoon hotkey).
- Reload config: `hs -c "hs.reload()"` or the pathwatcher auto-reload if added.
- Helper scripts in `~/raycast-scripts/`: `get_frame.py` / `span_iterm.py` (iTerm2 Python API; API
  enabled in iTerm Settings → General → Magic). Superseded by Hammerspoon for spanning but `get_frame.py`
  is still the way to inspect the window frame. iTerm coords: Cocoa-style, y up, boundary at 0;
  full span reads ≈ `Point(0, -1117), Size(1200, ~3000)`.
- Coordinate cheat sheet (Hammerspoon, y down from portrait top-left): portrait 0..1920, laptop
  1920..3037, boundary 1920.

## State / open items

- Working as of 2026-08-05 with `TOP_Y = 0`, `NUDGE = 34`, grab offset tuned for the hidden menu bar.
- The 34 px strip is accepted; revisit only if yabai ever becomes acceptable or Apple changes behavior.
- Fragile against: display sleep/reconnect (rerun the trigger), macOS updates (retest the drag rules),
  changed monitor arrangement (update W/TOP_Y/BOTTOM_Y/boundary constants).
- Long-term exit: neovim/neovim#2161 (per-UI layouts) would make all of this unnecessary.
- nvim side (from earlier in this effort): split boundary can be parked on the bezel via `:resize`
  with `&lines/2`; the nvim-as-tmux migration itself is tracked in `nvim-as-tmux.md`.
