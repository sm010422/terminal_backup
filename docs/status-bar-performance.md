# tmux status bar performance

What the tmux status bar costs in CPU, what was changed to cut it, and what was left as is.
Nothing here changes how the status bar looks or what it shows.

Korean version: [status-bar-performance.ko.md](status-bar-performance.ko.md)

Measured: 2026-11-07 / 2026-11-08, macOS, tmux 3.8, 11 windows open.

## Why it matters

tmux re-runs every `#(...)` command in the status line once per `status-interval`. Each one is a new process, and the
cost is paid all the time, even when nothing is happening on screen.

## Before

`status-interval 2` (set by Powerline's `powerline-base.conf`). CPU time per refresh:

| Item | CPU per refresh | Notes |
|---|---|---|
| Powerline left + right | 163ms | starts Python twice (`powerline tmux left` / `right`), no daemon |
| `agent-dot.sh` × 11 windows | 94ms | ~9ms per window, grows with the number of windows |
| `continuum_save.sh` | 51ms | checks whether the 15-minute save is due |
| **Total** | **~308ms every 2s** | **~15% of one CPU core, constantly** |

Event-driven hooks (sidebar focus hook ~11ms, `agent-phase.sh` ~9ms) run only when something happens and were left
alone.

## Changes

### 1. Agent mark computed with tmux formats (commit `1e8ab7e`)

The window-tab agent mark used to run `~/.tmux/scripts/agent-dot.sh <window_id>` once per window on every refresh.
The same logic is now a set of tmux format options in `.tmux.conf`, evaluated inside the tmux server:

| Option | Role |
|---|---|
| `@agent_codes` | `#{P:...}` loops over the window's panes and emits one letter per agent pane (E error, W waiting, I idle/background, S subagent, X executing, T thinking, C compacting) |
| `@agent_state` | picks the highest-priority letter with `#{m:*E*,...}` checks in priority order |
| `@agent_tabbg` | the colour the tab is painted with (active `colour31` / per-window `@mycolor` / `colour233`) |
| `@agent_fg` | state colour, or `colour233` when it is in the same colour family as the tab |
| `@agent_dot` | the mark itself; referenced by every window-status format as `#{E:@agent_dot}` |

- Result: 94ms → 0 per refresh (no process spawned). The mark also follows window switches immediately, because it is
  computed on every redraw instead of coming from a cached job output.
- Behaviour unchanged: the output was compared with the old script for 300 combinations (10 states × 10 tab colours,
  active and inactive tab, plus a second pane in the window) and for all live windows; all matched.
- `agent-dot.sh` was removed.

### 2. `status-interval 5`

Powerline's config sets `status-interval 2`. `.tmux.conf` overrides it right after loading Powerline:

```tmux
# Powerline sets status-interval 2; refresh every 5s instead to cut its periodic CPU cost
set -g status-interval 5
```

- Result: Powerline and `continuum_save.sh` run 2.5× less often.
- Trade-off: the clock, uptime and load average on the right update up to 5s late (was up to 2s). The agent mark is
  recomputed on any redraw (window switch, key press, ...), and at the latest on the next 5s refresh. The 15-minute
  auto-save is unaffected.

## After

| Item | CPU | Interval |
|---|---|---|
| Powerline left + right | 163ms | every 5s |
| `continuum_save.sh` | 51ms | every 5s |
| Agent mark | ~0 | — |
| **Total** | **~214ms every 5s** | **~4% of one CPU core** |

From ~154ms CPU per second to ~43ms per second: **about 72% less**.

## Related: stale background on the agent mark when switching windows

**Symptom.** When moving to another window with the keyboard, a small patch of the previous tab colour stayed behind the
agent mark for a second or two (e.g. a blue square behind the dot of the tab that had just become inactive).

**Cause.** The mark used to come from `#(agent-dot.sh <window_id> <tab background>)`, and the script printed both the
glyph colour and the background. tmux caches each `#()` job's output by its expanded command string. Switching windows
flips a tab between active and inactive, which changes the background argument, so tmux sees a new command. Until that
new job finishes, tmux keeps drawing the previous output, which still carried the old background.

**Fix, step 1 (`a77ee74`).** Pass only the window ID and print only the glyph colour; the tab format paints the
background. The command string no longer changes on a window switch, so the stale background is gone.

**Fix, step 2 (`1e8ab7e`).** The script was replaced with tmux formats (see Changes above). There is no cached job output
at all any more, so this class of residue cannot happen for the mark, and colour changes show up on the next redraw.

**Checked elsewhere.** The Powerline `#()` commands in `status-left` / `status-right` do not change when switching
windows, so they are not affected.

**Rule for future `#()` jobs in the status line.** Do not put values that differ per window state (active/inactive, tab
colour, ...) into the command's arguments, and do not print backgrounds from a job. Let the format decide those, or
compute the whole thing with formats when possible.

## Not changed (options for later)

- **Replace the Powerline status segments with native tmux formats.** Powerline is now almost all of the remaining
  cost. Date, time and user name are built into tmux; uptime and load average need one `uptime` call. This would cut the
  cost to a few ms, but the left/right status design would have to be rebuilt, so it was left for later.
- **`powerline-daemon`.** Makes the Powerline calls cheap, but adds a resident process, which this setup avoids
  (see [background-processes.md](background-processes.md)).
- **`continuum_save.sh`.** Part of the tmux-continuum plugin; left as is.

## How to check

```sh
tmux show -g status-interval          # 5
pgrep -fl agent-dot                   # nothing
# Agent mark for every window (tmux style codes; empty = no agent)
for w in $(tmux list-windows -a -F '#{window_id}'); do printf '%s %s\n' $w "$(tmux display -p -t $w '#{E:@agent_dot}')"; done
# CPU of one Powerline refresh
time (powerline tmux left >/dev/null; powerline tmux right >/dev/null)
```
