#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# Fonts are consumed by the desktop terminal emulator.
# On WSL, WezTerm runs on the Windows host and uses Windows fonts — skip.
if is_wsl; then
  echo "Skipping font install inside WSL (fonts live on the Windows host)."
  exit 0
fi

FONT_DIR="$HOME/.local/share/fonts/BitstromWera"

if fc-list | grep -qi "BitstromWera"; then
  echo "BitstromWera Nerd Font already installed"
  exit 0
fi

echo "Installing BitstromWera Nerd Font..."

ensure_directory "$FONT_DIR"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

curl -fL --progress-bar \
  "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/BitstreamVeraSansMono.zip" \
  -o "$TMP/BitstreamVeraSansMono.zip"

unzip -q "$TMP/BitstreamVeraSansMono.zip" -d "$FONT_DIR"

# Remove Windows-compatible variants (not needed on Linux)
rm -f "$FONT_DIR"/*Windows*

fc-cache -fv "$FONT_DIR" > /dev/null

echo "BitstromWera Nerd Font installed"
