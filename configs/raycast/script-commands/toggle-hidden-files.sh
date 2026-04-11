#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Toggle Hidden Files
# @raycast.mode silent
# @raycast.packageName System

# Optional parameters:
# @raycast.icon 👓
# @raycast.description Show/hide dotfiles in Finder

current=$(defaults read com.apple.finder AppleShowAllFiles 2>/dev/null)

if [ "$current" = "1" ] || [ "$current" = "TRUE" ]; then
  defaults write com.apple.finder AppleShowAllFiles -bool false
else
  defaults write com.apple.finder AppleShowAllFiles -bool true
fi

killall Finder
