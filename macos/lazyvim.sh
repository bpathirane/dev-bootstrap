#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# node is installed via install-packages.sh; tree-sitter and npm are available

# tree-sitter CLI — used by nvim-treesitter to compile parsers
if ! command_exists tree-sitter; then
  npm config set prefix "$HOME/.local"
  export PATH="$HOME/.local/bin:$PATH"
  npm install -g tree-sitter-cli
fi

# LazyVim starter config
if [ ! -d "$HOME/.config/nvim" ]; then
  echo "Installing LazyVim starter..."
  git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
  rm -rf "$HOME/.config/nvim/.git"
else
  echo "Neovim config already exists, skipping LazyVim starter."
fi
