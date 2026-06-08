#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if is_wsl; then
  echo "Starting bootstrap (WSL)..."
else
  echo "Starting bootstrap (Linux)..."
fi

# WSL-only: configure wsl.conf
if is_wsl; then
  "$SCRIPT_DIR/wsl-config.sh"
fi

# Install apt packages
"$SCRIPT_DIR/install-packages.sh"

# tmux from source (needs build-essential, libevent-dev, ncurses-dev from apt)
"$SCRIPT_DIR/tmux.sh"

# Starship prompt
if ! command_exists starship; then
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi
# Wire starship into bash login shells via profile.d.
# Zsh init (eval "$(starship init zsh)") should live in your chezmoi-managed .zshrc.
if command_exists starship && [ ! -f /etc/profile.d/starship.sh ]; then
  echo 'eval "$(starship init bash)"' | sudo tee /etc/profile.d/starship.sh > /dev/null
  sudo chmod +x /etc/profile.d/starship.sh
fi

# Set zsh as default shell
if [ "$SHELL" != "$(which zsh)" ]; then
  chsh -s "$(which zsh)"
fi

ensure_directory "$HOME/source/github_personal"

if ! command_exists docker; then
  if is_wsl; then
    echo "WARNING: docker CLI not found. Ensure Docker Desktop WSL integration is enabled."
  else
    echo "WARNING: docker CLI not found. Install Docker Engine for your platform."
  fi
fi

# Tool installs
"$SCRIPT_DIR/azure-cli.sh"
"$SCRIPT_DIR/mssql-tools.sh"
"$SCRIPT_DIR/aws.sh"
"$SCRIPT_DIR/k8s.sh"
"$SCRIPT_DIR/github.sh"
"$SCRIPT_DIR/ssh.sh"
# Clipboard bridge: win32yank on WSL, xclip+wl-clipboard everywhere else
if is_wsl; then
  "$SCRIPT_DIR/win32yank.sh"
else
  "$SCRIPT_DIR/clipboard.sh"
fi
"$SCRIPT_DIR/fzf.sh"
"$SCRIPT_DIR/lazygit.sh"
"$SCRIPT_DIR/yazi.sh"
"$SCRIPT_DIR/tldr.sh"
"$SCRIPT_DIR/zoxide.sh"
"$SCRIPT_DIR/lazyvim.sh"
"$SCRIPT_DIR/bun.sh"
"$SCRIPT_DIR/uv.sh"
"$SCRIPT_DIR/ruff.sh"
"$SCRIPT_DIR/just.sh"
"$SCRIPT_DIR/claude.sh"
"$SCRIPT_DIR/powershell.sh"
"$SCRIPT_DIR/dotnet.sh"
"$SCRIPT_DIR/sops.sh"
"$SCRIPT_DIR/lefthook.sh"
"$SCRIPT_DIR/zellij.sh"
"$SCRIPT_DIR/chezmoi.sh"
"$SCRIPT_DIR/gpg.sh"
"$SCRIPT_DIR/chromium.sh"
# WezTerm and fonts run on the desktop host — skip inside WSL
if ! is_wsl; then
  "$SCRIPT_DIR/wezterm.sh"
  "$SCRIPT_DIR/fonts.sh"
fi

echo "Bootstrap complete."
