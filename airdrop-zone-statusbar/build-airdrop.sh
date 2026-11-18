#!/bin/bash
# Build script to compile Swift script into a standalone binary

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SWIFT_SCRIPT="$SCRIPT_DIR/airdrop-share.swift"
BINARY="$SCRIPT_DIR/airdrop-share-bin"

echo "Compiling AirDrop Share..."
echo ""

# Compile the Swift script
swiftc -o "$BINARY" "$SWIFT_SCRIPT" -framework Cocoa -framework Foundation

if [ $? -eq 0 ]; then
    echo "✅ Successfully compiled to: $BINARY"
    chmod +x "$BINARY"
    echo ""
    echo "You can now run it with: ./airdrop-share-bin"
    echo ""
    echo "To test it:"
    echo "  ./airdrop-share-bin"
    echo ""
    echo "The binary doesn't require Full Disk Access!"
else
    echo "❌ Compilation failed"
    echo ""
    echo "If you see permission errors, you may need to:"
    echo "  1. Allow Terminal/your IDE to access the file"
    echo "  2. Or compile it manually:"
    echo "     swiftc -o airdrop-share-bin airdrop-share.swift -framework Cocoa -framework Foundation"
    exit 1
fi


