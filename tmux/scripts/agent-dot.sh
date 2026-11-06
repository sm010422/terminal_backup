#!/bin/sh
# agent-dot.sh <window_id> <tab_bg>
# tmux-agent-sidebar 가 기록한 @pane_status 를 윈도우 안 모든 pane 에 대해 합쳐 기호 하나를 출력한다.
# 우선순위: waiting/error (빨강 ?) > idle (노랑 ●) > running/background (초록 ●). 에이전트 없으면 출력 없음.
# 기호는 탭 배경색 위에 그대로 그린다. 상태색이 탭 배경과 같은 계열이면 탭 글자색(colour233)으로 대신 그린다.
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
