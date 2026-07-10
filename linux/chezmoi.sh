#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

if command_exists chezmoi; then
  echo "chezmoi $(chezmoi version) already installed"
else
  echo "Installing chezmoi..."
  curl -fsSL https://git.io/chezmoi | sh -s -- -b "$HOME/.local/bin"
fi

if [ -z "${GITHUB_USER:-}" ]; then
  echo "WARNING: GITHUB_USER not set, skipping dotfiles init"
  exit 0
fi

if [ -d "$HOME/.local/share/chezmoi/.git" ]; then
  echo "chezmoi already initialized"
  exit 0
fi

echo "Initializing chezmoi from github.com/$GITHUB_USER/dotfiles.git"
"$HOME"/.local/bin/chezmoi init --apply "git@github.com:$GITHUB_USER/dotfiles.git" || echo "WARNING: chezmoi init failed"
