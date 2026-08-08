#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# node is installed via install-packages.sh
if ! command_exists claude; then
  echo "Installing Claude Code CLI..."
  npm config set prefix "$HOME/.local"
  export PATH="$HOME/.local/bin:$PATH"
  npm install -g @anthropic-ai/claude-code
fi
