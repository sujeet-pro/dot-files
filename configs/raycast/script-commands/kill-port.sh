#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Kill Port
# @raycast.mode compact
# @raycast.packageName Developer

# Optional parameters:
# @raycast.icon 🚫
# @raycast.argument1 { "type": "text", "placeholder": "Port (e.g. 3000)" }
# @raycast.description Kill the process running on a given port

pid=$(lsof -ti tcp:"$1")
if [ -n "$pid" ]; then
  kill -9 "$pid"
  echo "Killed PID $pid on port $1"
else
  echo "Nothing on port $1"
fi
