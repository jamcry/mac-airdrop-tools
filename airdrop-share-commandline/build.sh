#!/bin/bash

# Exit on error
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SOURCE_FILE="$SCRIPT_DIR/airdrop-file.swift"
BINARY_NAME="airdrop-file"
OUTPUT_PATH="$SCRIPT_DIR/$BINARY_NAME"

echo "🔨 Compiling $BINARY_NAME..."

# Compile the Swift script into a standalone binary
swiftc -O "$SOURCE_FILE" -o "$OUTPUT_PATH"

echo "✅ Compiled successfully: $OUTPUT_PATH"
echo ""
echo "To install system-wide, run:"
echo "  sudo mv \"$OUTPUT_PATH\" /usr/local/bin/"
echo ""
echo "Then you can use it anywhere:"
echo "  airdrop-file ./somefile.txt"
echo "  airdrop-file --newest --extension=md ~/Documents/"

























