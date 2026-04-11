#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open in Zed
# @raycast.mode silent
# @raycast.packageName Navigation

# Optional parameters:
# @raycast.icon 🟦
# @raycast.description Open the current Finder directory in Zed editor

dir=$(osascript -e 'tell application "Finder"
  if (count of windows) > 0 then
    return POSIX path of (target of front window as alias)
  else
    return POSIX path of (path to desktop folder)
  end if
end tell' 2>/dev/null)

if [ -z "$dir" ]; then
  dir="$HOME"
fi

open -a "Zed" "$dir"
