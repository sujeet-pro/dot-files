#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Toggle Dark Mode
# @raycast.mode silent
# @raycast.packageName System

# Optional parameters:
# @raycast.icon 🌗
# @raycast.description Toggle macOS dark/light appearance

tell application "System Events"
  tell appearance preferences
    set dark mode to not dark mode
  end tell
end tell
