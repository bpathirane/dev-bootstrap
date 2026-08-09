#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# macOS ships bash 3.2 (no associative arrays) — keep this script 3.2-compatible.
bin_for_package() {
  case "$1" in
    ripgrep) echo "rg" ;;
    neovim) echo "nvim" ;;
    azure-cli) echo "az" ;;
    gnupg) echo "gpg" ;;
    awscli) echo "aws" ;;
    *) echo "$1" ;;
  esac
}

PACKAGES=(
  tmux zoxide starship bat fd ripgrep fzf jq tldr yazi just gh lazygit neovim
  node uv bun age gnupg sops lefthook zellij direnv htop git azure-cli awscli
  kubectl helm k9s kubectx kind chezmoi sqlcmd
)

CASKS=(orbstack powershell dotnet-sdk wezterm google-chrome)

MISSING=()
for pkg in "${PACKAGES[@]}"; do
  bin="$(bin_for_package "$pkg")"
  command_exists "$bin" || MISSING+=("$pkg")
done

MISSING_CASKS=()
for cask in "${CASKS[@]}"; do
  brew list --cask "$cask" &>/dev/null || MISSING_CASKS+=("$cask")
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "Missing required tools: ${MISSING[*]}" >&2
fi
if [ ${#MISSING_CASKS[@]} -gt 0 ]; then
  echo "Missing casks: ${MISSING_CASKS[*]}" >&2
fi

if ! command_exists tree-sitter; then
  echo "Missing tree-sitter CLI (nvim-treesitter requires it) — run macos/lazyvim.sh" >&2
  MISSING+=("tree-sitter")
fi

if [ ${#MISSING[@]} -eq 0 ] && [ ${#MISSING_CASKS[@]} -eq 0 ]; then
  echo "All required macOS full-profile tools are present."
else
  exit 1
fi
