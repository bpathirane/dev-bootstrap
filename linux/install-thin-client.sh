#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

echo "Linux thin-client installer: installing minimal host tools"
apt_update_if_stale
for pkg in git curl wget gh chezmoi; do
  apt_install_if_missing "$pkg" || true
done

echo "Thin-client install complete." 
