#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

echo "Running identity setup..."

"$SCRIPT_DIR/ssh.sh" || true
"$SCRIPT_DIR/gpg.sh" || true

echo "Identity setup complete."
