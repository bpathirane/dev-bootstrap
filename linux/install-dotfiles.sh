#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if [ -z "${GITHUB_USER:-}" ]; then
  if [ -t 0 ]; then
    read -rp "Enter your GitHub username for chezmoi: " GITHUB_USER
  else
    echo "ERROR: GITHUB_USER must be set for chezmoi." >&2
    exit 1
  fi
fi

export GITHUB_USER
"$SCRIPT_DIR/chezmoi.sh"

echo "Dotfiles install complete."
