# mac-airdrop-tools

A collection of macOS tools for sharing files via AirDrop — from the terminal or by drag & drop.

## 📂 What's inside

- **`airdrop-zone-statusbar/`** — a menu bar app. Drag any file onto the ✈ icon to share it via AirDrop instantly.
- **`airdrop-share-commandline/`** — a CLI tool (`airdrop-file`) that opens the native AirDrop sharing dialog from your terminal.

## 📸 Screenshots

<!-- TODO: add a menu bar screenshot of the status bar app, e.g. docs/statusbar.png -->

## 📋 Requirements

- macOS with AirDrop support
- Xcode Command Line Tools (`xcode-select --install`)

## 🚀 CLI Tool: `airdrop-file`

Share a specific file:

```bash
airdrop-file ./myfile.txt
```

Share the newest file in a folder:

```bash
airdrop-file --newest ~/Downloads/
```

Share the newest `.md` file in a folder:

```bash
airdrop-file --newest --extension=md ~/Documents/
```

### Installation

```bash
cd airdrop-share-commandline
./build.sh
sudo mv airdrop-file /usr/local/bin/
```

## ✈️ Status Bar App: AirDrop Zone

A small utility that lives in your macOS menu bar. Just drag any file onto the "✈ AirDrop" icon to share it.

### Installation

```bash
cd airdrop-zone-statusbar
./setup-airdrop.sh
```

This installs a LaunchAgent (`com.jamcry.airdropshare`) that starts the app at login and keeps it running. See [airdrop-zone-statusbar/AIRDROP_SETUP.md](airdrop-zone-statusbar/AIRDROP_SETUP.md) for troubleshooting, including the Full Disk Access steps if the swift fallback reports "Operation not permitted".

### Uninstall

```bash
cd airdrop-zone-statusbar
./uninstall-airdrop.sh
```

## 📄 License

MIT — see [LICENSE](LICENSE).
