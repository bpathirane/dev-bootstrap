#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

echo "Installing optional AI tooling..."
"$SCRIPT_DIR/claude.sh" || true

echo "AI tooling install complete."
