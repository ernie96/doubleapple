#!/usr/bin/env bash
#
# build.sh - Build DoubleTalkKit & iOS VoiceOver targets
#

set -euo pipefail

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$WORKSPACE_DIR"

echo "==> Building DoubleTalkKit Swift Package..."
swift build -c release

echo "==> Build complete!"
