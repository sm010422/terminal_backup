#!/bin/sh
# agent-dot.sh <window_id> <tab_bg>
# Merges the @pane_status written by tmux-agent-sidebar across all panes in a window and prints one mark.
# Priority: waiting/error (red ?) > idle (yellow ●) > running/background (green ●). No agent -> no output.
# The mark is drawn on the tab's own background; if the status color matches the tab color, the tab text color (colour233) is used instead.
statuses=$(tmux list-panes -t "$1" -F '#{@pane_status}' 2>/dev/null)
bg=${2:-colour233}
case "$statuses" in
  *waiting*|*error*)
    fg=colour196 glyph='?'
    case "$bg" in red|brightred|colour1|colour9|colour160|colour196|\#[Ff][Ff]0000) fg=colour233 ;; esac ;;
  *idle*)
    fg=colour220 glyph='●'
    case "$bg" in yellow|brightyellow|colour3|colour11|colour220|colour226|\#[Ff][Ff][Ff][Ff]00) fg=colour233 ;; esac ;;
  *running*|*background*)
    fg=colour46 glyph='●'
    case "$bg" in green|brightgreen|colour2|colour10|colour46|\#00[Ff][Ff]00) fg=colour233 ;; esac ;;
  *) exit 0 ;;
esac
printf '#[fg=%s,bg=%s,bold]%s#[nobold] ' "$fg" "$bg" "$glyph"
