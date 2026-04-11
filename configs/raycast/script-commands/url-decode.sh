#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title URL Decode Clipboard
# @raycast.mode compact
# @raycast.packageName Developer

# Optional parameters:
# @raycast.icon 🔗
# @raycast.description URL-decode clipboard contents and copy result back

decoded=$(pbpaste | python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))")
if [ $? -eq 0 ]; then
  echo "$decoded" | pbcopy
  echo "URL decoded and copied"
else
  echo "Failed to decode"
  exit 1
fi
