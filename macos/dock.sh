#!/usr/bin/env bash
# Restore macOS Dock settings.
# Usage: ./macos/dock.sh

set -euo pipefail

TILE_SIZE=35        # icon size (16-128)
MAGNIFICATION=false # enlarge icons on hover
AUTOHIDE=true       # auto-hide the Dock

defaults write com.apple.dock tilesize -int "$TILE_SIZE"
defaults write com.apple.dock magnification -bool "$MAGNIFICATION"
defaults write com.apple.dock autohide -bool "$AUTOHIDE"

# Lock size so it can't be changed by dragging the Dock divider.
# Unlock: defaults delete com.apple.dock size-immutable && killall Dock
defaults write com.apple.dock size-immutable -bool true

killall Dock

echo "Dock restored: tilesize=$TILE_SIZE, size locked"
