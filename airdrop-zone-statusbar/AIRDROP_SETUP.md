# AirDrop Share Setup Guide

## Quick Start

Run the setup script:
```bash
./setup-airdrop.sh
```

## If You Get "Operation not permitted" Error

This usually means macOS security restrictions are blocking access. Try these solutions:

### Solution 1: Grant Full Disk Access (Recommended)

1. Open **System Settings** → **Privacy & Security** → **Full Disk Access**
2. Click the **+** button
3. Navigate to `/usr/bin/swift` and add it
4. Restart the LaunchAgent:
   ```bash
   ./setup-airdrop.sh
   ```

### Solution 2: Use the App Bundle Instead

1. Double-click `AirDropShare.app` to run it manually
2. To make it auto-start:
   - Open **System Settings** → **General** → **Login Items**
   - Click **+** and add `AirDropShare.app`
   - Enable "Open at Login"

### Solution 3: Run Manually

You can always run it manually:
```bash
swift airdrop-share.swift
```

Or use the wrapper:
```bash
./run-airdrop.sh
```

## Managing the Service

**Check if it's running:**
```bash
launchctl print gui/$(id -u)/com.jamcry.airdropshare
```

**Stop (uninstall) the service:**
```bash
./uninstall-airdrop.sh
```

**Start the service:**
```bash
./setup-airdrop.sh
```

**Restart after a crash without reinstalling:**
```bash
launchctl kickstart gui/$(id -u)/com.jamcry.airdropshare
```

**View logs:**
```bash
tail -f /tmp/airdrop-share.log
tail -f /tmp/airdrop-share.error.log
```

**Uninstall:**
```bash
./uninstall-airdrop.sh
```

## Why this can't death-loop

The old agent used `KeepAlive: true`, which restarts the job on every exit,
forever, ignoring the exit code — a deleted project folder meant 56,000+
failed launches. The installed plist now uses:

- `KeepAlive` → `Crashed: true` — relaunch only after a real crash (signal),
  never on a clean exit. Missing targets and config errors exit cleanly, so
  the job stays down instead of retry-looping.
- `ThrottleInterval: 30` — even in the worst case, one attempt per 30s.
- The wrapper (`run-airdrop.sh`) self-uninstalls the LaunchAgent if the
  project folder is gone, so it disappears from Login Items on its own.
- Quitting the app from its own menu now keeps it quit; `KeepAlive: true`
  used to respawn it immediately. Use `launchctl kickstart` to start it again.


