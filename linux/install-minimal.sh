#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

echo "Starting minimal profile install..."

apt_update_if_stale

MINIMAL_PKGS=(git curl wget ca-certificates)
for pkg in "${MINIMAL_PKGS[@]}"; do
  apt_install_if_missing "$pkg"
done

echo "Minimal profile install complete."
