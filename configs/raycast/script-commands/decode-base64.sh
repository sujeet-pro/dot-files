#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Decode Base64
# @raycast.mode compact
# @raycast.packageName Developer

# Optional parameters:
# @raycast.icon 🔓
# @raycast.description Decode Base64 from clipboard, copy result back

decoded=$(pbpaste | base64 -d 2>&1)
if [ $? -eq 0 ]; then
  echo "$decoded" | pbcopy
  echo "Decoded and copied"
else
  echo "Invalid Base64"
  exit 1
fi
