#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

BREW_PREFIX="/home/linuxbrew/.linuxbrew"
if command_exists brew; then
  echo "Homebrew already installed."
else
  echo "Installing Homebrew (Linuxbrew) to $BREW_PREFIX"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [ -x "$BREW_PREFIX/bin/brew" ]; then
  eval "$("$BREW_PREFIX/bin/brew" shellenv)"
fi

if ! command_exists brew; then
  echo "Homebrew installation failed or brew not available." >&2
  exit 1
fi

if ! grep -q 'linuxbrew/.linuxbrew' "$HOME/.profile" 2>/dev/null; then
  echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.profile"
fi

BREW_FORMULAS=(neovim tmux lazygit yazi fzf fd ripgrep gh kubectl helm k9s zoxide starship just uv)
for formula in "${BREW_FORMULAS[@]}"; do
  echo "Ensuring brew formula: $formula"
  brew_install_if_missing "$formula" || true
done

