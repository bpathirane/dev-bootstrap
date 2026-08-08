#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

echo "Starting macOS full profile install..."

# Ensure Homebrew is installed
if ! command_exists brew; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -f /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# Install all packages and casks via brew
"$SCRIPT_DIR/install-packages.sh"

# Confirm zsh is the default shell (macOS sets this since Catalina; guard for edge cases)
if [ "$SHELL" != "$(which zsh)" ]; then
  chsh -s "$(which zsh)"
fi

# Ensure project directory exists
ensure_directory "$HOME/source/github_personal"

# Docker check — OrbStack is installed as a cask; warn if docker CLI not yet available
# (OrbStack registers the CLI on first app launch, so the user must open it once)
if ! command_exists docker; then
  echo "WARNING: docker CLI not found. Open OrbStack.app once to register the CLI, or install Docker Desktop / Colima."
fi

# Cloud tooling — installed via brew in install-packages.sh; no post-install config needed
# azure-cli, awscli, kubectl, helm, k9s, kubectx (kubectx+kubens), kind

# MSSQL tools
"$SCRIPT_DIR/mssql-tools.sh"

# SSH keys, config, and known_hosts for GitHub + Azure DevOps
"$SCRIPT_DIR/ssh.sh"

# LazyVim config + tree-sitter CLI (node installed via install-packages.sh)
"$SCRIPT_DIR/lazyvim.sh"

# Claude Code CLI (node installed via install-packages.sh)
"$SCRIPT_DIR/claude.sh"

# chezmoi — only initializes if not already set up; safe to rerun
"$SCRIPT_DIR/chezmoi.sh"

echo "macOS full profile install complete."
