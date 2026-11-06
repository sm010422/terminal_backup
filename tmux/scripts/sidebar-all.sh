#!/bin/sh
# sidebar-all.sh toggle | new-window <window_id> <pane_path>
# Remembers whether prefix+E turned tmux-agent-sidebar on for all windows (@sidebar_all),
# so new windows get a sidebar only while that mode is on.
bin=$(tmux show -gv @agent_sidebar_bin)
has_sidebar() { tmux list-panes -a -F '#{@pane_role}' | grep -qx sidebar; }
case "$1" in
  toggle)
    "$bin" toggle-all
    if has_sidebar; then tmux set -g @sidebar_all on; else tmux set -g @sidebar_all off; fi ;;
  new-window)
    [ "$(tmux show -gv @sidebar_all 2>/dev/null)" = on ] || exit 0
    # All sidebars were closed by hand (prefix+e): treat the mode as off
    has_sidebar || { tmux set -g @sidebar_all off; exit 0; }
    "$bin" toggle --create-only "$2" "${3:-$HOME}" ;;
esac
