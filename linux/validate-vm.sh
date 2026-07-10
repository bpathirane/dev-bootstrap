#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

MISSING=()
REQUIRED=(git curl wget jq ripgrep fzf tmux neovim)
for cmd in "${REQUIRED[@]}"; do
  if ! command_exists "$cmd"; then
    MISSING+=("$cmd")
  fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "Missing required tools: ${MISSING[*]}" >&2
  exit 1
else
  echo "All required VM tools are present." 
fi

echo "Optional tools (not required):"
for opt in lazygit kubectl helm kind gh; do
  if command_exists "$opt"; then
    echo " - $opt: $(command -v $opt)"
  else
    echo " - $opt: MISSING"
  fi
done

exit 0
