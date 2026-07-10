#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

echo "Starting desktop profile install..."

apt_update_if_stale
"$SCRIPT_DIR/install-vm.sh"

# Desktop extras
for pkg in gnome-shell gnome-terminal firefox; do
  apt_install_if_missing "$pkg"
done

# WezTerm and fonts may be useful on desktop hosts
"$SCRIPT_DIR/wezterm.sh" || true
"$SCRIPT_DIR/fonts.sh" || true

echo "Desktop profile install complete."
