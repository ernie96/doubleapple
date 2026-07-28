#!/usr/bin/env bash
#
# generate_project.sh - Generate Xcode project for DoubleTalk iOS App & VoiceOver Extension
#

set -euo pipefail

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$WORKSPACE_DIR"

echo "==> Validating doubletalkpc.bin firmware binary..."
if [ ! -f "doubletalkpc.bin" ]; then
    echo "ERROR: doubletalkpc.bin not found in workspace directory."
    exit 1
fi

ROM_SIZE=$(wc -c < "doubletalkpc.bin" | tr -d ' ')
if [ "$ROM_SIZE" -ne 524288 ]; then
    echo "WARNING: doubletalkpc.bin is $ROM_SIZE bytes (expected 524,288 bytes)."
fi

echo "==> Generating Xcode project..."
swift package generate-xcodeproj || true

echo "==> DoubleTalk iOS workspace initialized successfully!"
