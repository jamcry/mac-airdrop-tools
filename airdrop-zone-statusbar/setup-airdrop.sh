#!/bin/bash
# Setup script for the AirDrop Share status bar app.
# Installs the com.jamcry.airdropshare LaunchAgent.

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOMAIN="gui/$(id -u)"
LABEL="com.jamcry.airdropshare"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
TARGET_PLIST="$LAUNCH_AGENTS_DIR/$LABEL.plist"
BINARY="$SCRIPT_DIR/airdrop-share-bin"
WRAPPER="$SCRIPT_DIR/run-airdrop.sh"

echo "Setting up AirDrop Share..."
echo ""

# Build the binary if possible (avoids needing Full Disk Access for swift).
if [ ! -x "$BINARY" ] && [ -f "$SCRIPT_DIR/build-airdrop.sh" ]; then
    echo "Binary not found. Building..."
    bash "$SCRIPT_DIR/build-airdrop.sh" || echo "⚠️  Build failed — will fall back to swift."
    echo ""
fi

if [ -x "$BINARY" ]; then
    echo "✅ Will use the compiled binary (no Full Disk Access needed)"
else
    echo "⚠️  Will use the swift fallback (may require Full Disk Access)"
fi
echo ""

# Install the plist. Robustness settings:
#   KeepAlive/Crashed — relaunch only after a real crash (signal), never on a
#     clean exit, so a deleted or moved project can't cause a respawn loop.
#   ThrottleInterval — at most one launch attempt per 30s even in the worst case.
# The wrapper (run-airdrop.sh) self-uninstalls the agent if the project disappears.
mkdir -p "$LAUNCH_AGENTS_DIR"
cat > "$TARGET_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$WRAPPER</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
        <key>Crashed</key>
        <true/>
    </dict>
    <key>ThrottleInterval</key>
    <integer>30</integer>
    <key>StandardOutPath</key>
    <string>/tmp/airdrop-share.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/airdrop-share.error.log</string>
    <key>WorkingDirectory</key>
    <string>$SCRIPT_DIR</string>
</dict>
</plist>
EOF

echo "✅ LaunchAgent installed to: $TARGET_PLIST"
echo ""

# Replace any previous instance. 'enable' also reverses the agent's
# self-disable if it uninstalled itself earlier.
launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
launchctl enable "$DOMAIN/$LABEL" 2>/dev/null || true
launchctl bootstrap "$DOMAIN" "$TARGET_PLIST"

sleep 2
if launchctl print "$DOMAIN/$LABEL" >/dev/null 2>&1; then
    echo "✅ AirDrop Share is running — the status bar icon should appear."
else
    echo "⚠️  Service may not have started. Check with:"
    echo "     launchctl print $DOMAIN/$LABEL"
    echo "     tail /tmp/airdrop-share.error.log"
fi
echo ""
echo "Uninstall:  bash $SCRIPT_DIR/uninstall-airdrop.sh"
echo "Restart:    launchctl kickstart $DOMAIN/$LABEL"
