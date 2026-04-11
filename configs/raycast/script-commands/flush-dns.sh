#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Flush DNS
# @raycast.mode compact
# @raycast.packageName System

# Optional parameters:
# @raycast.icon 🌐
# @raycast.needsConfirmation true
# @raycast.description Flush macOS DNS cache

sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
echo "DNS cache flushed"
