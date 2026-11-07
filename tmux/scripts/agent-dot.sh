#!/bin/sh
# agent-dot.sh <window_id> <tab_bg>
# Merges the agent state of every pane in a window (tmux-agent-sidebar's @pane_status / @pane_subagents
# plus @pane_phase from agent-phase.sh) and prints one tmux-styled mark. No agent -> no output.
# Priority (high -> low): error (red ✕) > waiting (purple ?) > idle/background (green ●)
#   > subagent (teal ●) > executing (blue ●) > thinking (orange ●) > compacting (grey ●)
# background = turn ended with a bg shell left; the plugin only clears it while a sidebar is open, so it counts as idle.
# The mark is drawn on the tab's own background; if the state colour is in the same family as the tab colour,
# the tab text colour (colour233) is used instead.
bg=${2:-colour233}
best=0
for p in $(tmux list-panes -t "$1" -F '#{@pane_status}|#{@pane_phase}|#{?@pane_subagents,sub,}' 2>/dev/null); do
  case "$p" in
    error\|*)              r=7 ;;
    waiting\|*)            r=6 ;;
    idle\|*|background\|*) r=5 ;;
    running\|*\|sub)       r=4 ;;
    running\|executing\|*) r=3 ;;
    running\|compacting\|*) r=1 ;;
    running\|*)            r=2 ;;
    *)                     r=0 ;;
  esac
  [ "$r" -gt "$best" ] && best=$r
done
case $best in
  7) fg=colour196 fam=red    glyph='✕' ;;
  6) fg=colour141 fam=purple glyph='?' ;;
  5) fg=colour46  fam=green  glyph='●' ;;
  4) fg=colour44  fam=teal   glyph='●' ;;
  3) fg=colour33  fam=blue   glyph='●' ;;
  2) fg=colour208 fam=orange glyph='●' ;;
  1) fg=colour245 fam=grey   glyph='●' ;;
  *) exit 0 ;;
esac
case "$bg" in
  red|brightred|colour1|colour9|colour160|colour196|\#[Ff][Ff]0000)                 bgfam=red ;;
  purple|magenta|brightmagenta|colour5|colour13|colour129|colour135|colour141)      bgfam=purple ;;
  green|brightgreen|colour2|colour10|colour46|\#00[Ff][Ff]00)                       bgfam=green ;;
  cyan|brightcyan|colour6|colour14|colour44)                                        bgfam=teal ;;
  blue|brightblue|skyblue|colour4|colour12|colour27|colour31|colour33|\#0064[Ff][Ff]) bgfam=blue ;;
  orange|colour202|colour208|colour214)                                             bgfam=orange ;;
  grey|gray|colour8|colour244|colour245)                                            bgfam=grey ;;
  *)                                                                                bgfam= ;;
esac
[ "$fam" = "$bgfam" ] && fg=colour233
printf '#[fg=%s,bg=%s,bold]%s#[nobold] ' "$fg" "$bg" "$glyph"
