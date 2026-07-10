#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if ! is_wsl; then
  echo "install-wsl.sh should only be run inside WSL." >&2
  exit 2
fi

echo "Starting WSL profile install..."

# WSL-specific configuration
"$SCRIPT_DIR/wsl-config.sh" || true

apt_update_if_stale
"$SCRIPT_DIR/install-packages.sh"

# WSL clipboard helpers and win32yank
"$SCRIPT_DIR/win32yank.sh" || true

# Remaining toolchain (same as VM but WSL-appropriate)
"$SCRIPT_DIR/aws.sh" || true
"$SCRIPT_DIR/azure-cli.sh" || true
"$SCRIPT_DIR/github.sh" || true
"$SCRIPT_DIR/k8s.sh" || true
"$SCRIPT_DIR/sops.sh" || true
"$SCRIPT_DIR/uv.sh" || true
"$SCRIPT_DIR/ruff.sh" || true
"$SCRIPT_DIR/bun.sh" || true
"$SCRIPT_DIR/dotnet.sh" || true

echo "WSL profile install complete. Run ./linux/validate-wsl.sh to verify." 
