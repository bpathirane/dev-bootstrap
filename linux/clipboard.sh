#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

# X11 and Wayland clipboard providers for Neovim on non-WSL Linux.
# Both are lightweight; having both installed means Neovim picks the right
# one automatically depending on whether the session is X11 or Wayland.
apt_install_if_missing xclip
apt_install_if_missing wl-clipboard
