#!/bin/bash
# Completely removes the AirDrop Share LaunchAgent:
# stops it, disables it, and deletes its plist.

set -euo pipefail

DOMAIN="gui/$(id -u)"
LABEL="com.jamcry.airdropshare"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
launchctl disable "$DOMAIN/$LABEL" 2>/dev/null || true
rm -f "$PLIST"

echo "✅ $LABEL removed. It disappears from Login Items automatically."
