#!/bin/sh
# active-tab-shape.sh [preset]
# Switches the end caps of the active window tab at runtime (tmux options only, .tmux.conf untouched).
# Without an argument, lists the presets. Caps are Nerd Font powerline-extra glyphs.
#   left cap  : drawn with @active_cap_l_style (default: tab colour on the dark status background)
#   right cap : drawn as tab colour on the dark status background
preset=$1
notch_style='fg=colour233,bg=colour31'
cap_style='fg=colour31,bg=colour233'
case "$preset" in
  notch)     l='' r='' ls=$notch_style ;;  # original look (dark notch on the left)
  arrow)     l='' r='' ls=$cap_style ;;    # < tab >
  round)     l='' r='' ls=$cap_style ;;    # ( tab )
  triangle)  l='' r='' ls=$cap_style ;;    # / tab \  (trapezoid, wide bottom)
  triangle2) l='' r='' ls=$cap_style ;;    # \ tab /  (wide top)
  slant)     l='' r='' ls=$cap_style ;;    # / tab /  (parallelogram)
  flame)     l='' r='' ls=$cap_style ;;
  pixel)     l='' r='' ls=$cap_style ;;
  wave)      l='' r='' ls=$cap_style ;;
  trapezoid) l='' r='' ls=$cap_style ;;
  *) echo "usage: $0 {notch|arrow|round|triangle|triangle2|slant|flame|pixel|wave|trapezoid}"; exit 1 ;;
esac
tmux set -g @active_cap_l "$(printf "$l")" \; \
     set -g @active_cap_r "$(printf "$r")" \; \
     set -g @active_cap_l_style "$ls" \; \
     refresh-client -S
