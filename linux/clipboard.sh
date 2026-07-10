#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

# Clipboard tools for Neovim on non-WSL Linux (headless or desktop)
if is_wsl; then
  echo "Skipping clipboard setup on WSL (use win32yank.sh instead)"
  exit 0
fi

apt_install_if_missing xclip
apt_install_if_missing wl-clipboard

echo "Clipboard tools installed"
