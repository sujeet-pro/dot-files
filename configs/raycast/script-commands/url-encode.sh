#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title URL Encode Clipboard
# @raycast.mode compact
# @raycast.packageName Developer

# Optional parameters:
# @raycast.icon 🔗
# @raycast.description URL-encode clipboard contents and copy result back

encoded=$(pbpaste | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read().strip(), safe=''))")
if [ $? -eq 0 ]; then
  echo "$encoded" | pbcopy
  echo "URL encoded and copied"
else
  echo "Failed to encode"
  exit 1
fi
