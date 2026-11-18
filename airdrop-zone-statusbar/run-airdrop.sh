#!/bin/bash
# Launcher for the AirDrop Share status bar app.
# Started by launchd via the com.jamcry.airdropshare LaunchAgent.

LABEL="com.jamcry.airdropshare"
DOMAIN="gui/$(id -u)"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SWIFT_SCRIPT="$SCRIPT_DIR/airdrop-share.swift"
BINARY="$SCRIPT_DIR/airdrop-share-bin"
ERROR_LOG="/tmp/airdrop-share.error.log"

# If the project is gone or moved, uninstall the LaunchAgent instead of
# leaving launchd in an infinite respawn loop against a dead target.
if [ ! -f "$SWIFT_SCRIPT" ] && [ ! -x "$BINARY" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') airdrop-share target missing — uninstalling $LABEL" >> "$ERROR_LOG"
    launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null
    launchctl disable "$DOMAIN/$LABEL" 2>/dev/null
    rm -f "$HOME/Library/LaunchAgents/$LABEL.plist"
    exit 0
fi

cd "$SCRIPT_DIR"

# Prefer the compiled binary (no Full Disk Access needed); fall back to swift.
if [ -x "$BINARY" ]; then
    exec "$BINARY"
fi

exec /usr/bin/swift "$SWIFT_SCRIPT"
