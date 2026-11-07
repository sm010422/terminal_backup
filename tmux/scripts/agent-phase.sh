#!/bin/sh
# agent-phase.sh <thinking|executing|compacting>
# Claude Code hook: records what a running agent is doing in the pane option @pane_phase,
# which agent-dot.sh uses to colour the window tab. Local tmux call only; no-op outside tmux.
[ -n "$TMUX_PANE" ] || exit 0
tmux set -p -t "$TMUX_PANE" @pane_phase "$1" >/dev/null 2>&1
exit 0
