# Background & resident processes

What this terminal setup (tmux + Claude Code) runs on its own, when, and what it costs.
Everything here runs locally; the only item that uses model tokens is the `kg-sync` hook (see below).

Korean version: [background-processes.ko.md](background-processes.ko.md)

Last reviewed: 2026-11-07

## Summary

| Kind | What | When | Cost |
|---|---|---|---|
| Resident | tmux server | while any tmux session exists | — |
| Resident | tmux-agent-sidebar TUI (one per window) | only while a sidebar pane is open (`prefix + e` / `prefix + E`) | refreshes every 1s, runs a `ps` sweep per tick |
| Periodic | Powerline status left/right (`powerline` Python) | every `status-interval` (2s), 2 processes | heaviest periodic item (Python start-up each time) |
| Periodic | `tmux-continuum` `continuum_save.sh` | every 2s via status-right; actually saves every 15 min | tiny check, resurrect save every 15 min |
| Periodic | `~/.tmux/scripts/agent-dot.sh` | every 2s, once per window | one `tmux list-panes` call |
| Event | tmux hooks | new window / pane focus / pane exit / resurrect save & restore | short-lived |
| Event | Claude Code hooks | tool use, prompt submit, session start/end, compaction | short-lived; `kg-sync` spawns a detached headless Claude |
| On demand | key bindings (`prefix + T`, `prefix + E`, ...) | only when pressed | — |

There is **no** always-on helper daemon started by `.tmux.conf` (no `run-shell -b` loop, no `powerline-daemon`).

## Periodic: tmux status bar (`status-interval 2`)

tmux re-runs every `#(...)` in the status line each interval. Each one is a short-lived process.

- **Powerline** (`status-left`, `status-right`): runs `powerline tmux left|right` — a new Python process each time, twice every 2s.
  Starting `powerline-daemon -q` would make these calls cheap, or raise `status-interval` if CPU matters.
- **continuum_save.sh** (prepended to `status-right` by tmux-continuum): checks the timestamp every tick and triggers a
  tmux-resurrect save every `@continuum-save-interval` (15 min). The post-save hook writes `~/.tmux/window-colors.txt`
  and keeps the 5 newest resurrect files.
- **agent-dot.sh** (`@agent_dot` in every window-status format): one `tmux list-panes` per window, prints the agent mark.

## Event-driven: tmux hooks and bindings

| Trigger | Runs | Source |
|---|---|---|
| `after-new-window[90]` | `sidebar-all.sh new-window` — creates a sidebar only if `prefix + E` mode is on | `.tmux.conf` |
| `after-select-pane`, `after-select-window` | sends `SIGUSR1` to open sidebars so they redraw | tmux-agent-sidebar |
| `pane-exited` | `tmux-agent-sidebar auto-close` — closes a window left with only its sidebar | tmux-agent-sidebar |
| resurrect post-save / post-restore | save / re-apply per-window tab colours | `.tmux.conf` |
| `prefix + T` | `sesh` session picker (fzf popup) | `.tmux.conf` |
| `prefix + E` / `prefix + e` | toggle sidebars in all windows / this window | `.tmux.conf` / plugin |

## Event-driven: Claude Code hooks

Hooks run as child processes of the Claude Code session that fired them.

| Event | Hook | Notes |
|---|---|---|
| most events | tmux-agent-sidebar `hook.sh` (plugin) | writes `@pane_status`, `@pane_subagents`, ... to the tmux pane |
| PreToolUse / PostToolUse / UserPromptSubmit / SessionStart / PreCompact | `~/.tmux/scripts/agent-phase.sh` | writes `@pane_phase`; wired in `claude/settings.json` (applies to sessions started after the change) |
| PreToolUse (Grep, Glob, Bash) / PostToolUse (Bash) | GitNexus `gitnexus-hook.cjs` | Node process per matching tool call |
| SessionStart | `herdr-agent-state.sh session` | |
| SessionEnd | `~/.claude/hooks/kg-sync.sh` | **detached headless `claude -p`** that reads the finished transcript and writes to personal-kg; outlives the session briefly and **uses model tokens**. Log: `~/.claude/kg-sync.log` |

## Removed on purpose

- **TokenEater tmux watcher** (`~/Library/Application Support/com.tokeneater.shared/tmux-watcher.sh`): a bash loop that
  polls a trigger file every 0.3s so a click in TokenEater can jump to the right tmux pane. The app did not start it by
  itself, and keeping a resident loop only for this was not worth it, so it is not started and the
  `update-environment TERM_PROGRAM` line was dropped as well. Clicking a session in TokenEater therefore does not
  switch tmux panes.

## Checking what is running

```sh
# Everything the tmux server has spawned right now (panes' shells excluded)
srv=$(tmux display -p '#{pid}'); ps -Ao pid,ppid,etime,command | awk -v p=$srv '$2==p' | grep -v -E 'zsh$'

# Long-running helpers that should NOT be there
pgrep -fl 'tmux-watcher|powerline-daemon'

# Hooks currently registered in tmux
tmux show-hooks -g
```
