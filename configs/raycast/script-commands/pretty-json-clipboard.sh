#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Pretty JSON (Clipboard)
# @raycast.mode compact
# @raycast.packageName Developer

# Optional parameters:
# @raycast.icon 📋
# @raycast.description Format JSON from clipboard and copy result back

json=$(pbpaste)
formatted=$(echo "$json" | python3 -m json.tool 2>&1)

if [ $? -eq 0 ]; then
  echo "$formatted" | pbcopy
  echo "JSON formatted and copied"
else
  echo "Invalid JSON"
  exit 1
fi
