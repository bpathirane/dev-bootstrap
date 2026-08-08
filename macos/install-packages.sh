#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

brew update --quiet

PACKAGES=(
  # Shell & navigation
  tmux
  zoxide
  starship
  # File & search tools
  bat
  fd
  ripgrep
  fzf
  jq
  # Terminal utilities
  tldr
  yazi
  just
  # Dev tools
  gh
  lazygit
  neovim
  node
  # Python & node tooling
  uv
  bun
  # Secrets & process management
  age
  gnupg
  sops
  lefthook
  zellij
  direnv
  htop
  # Source control utilities
  git
  # Cloud — Azure
  azure-cli
  # Cloud — AWS
  awscli
  # Kubernetes
  kubectl
  helm
  k9s
  kubectx
  kind
  # Dotfiles
  chezmoi
  # MSSQL (go-sqlcmd — native arm64, no EULA tap required)
  sqlcmd
)

CASKS=(
  # Docker / Linux VMs (personal use; for commercial use prefer docker or colima)
  orbstack
  # Microsoft tooling
  powershell
  dotnet-sdk
  # Terminal emulator (macOS host)
  wezterm
  # Browser (for Playwright / dev testing)
  google-chrome
)

for pkg in "${PACKAGES[@]}"; do
  brew_install_if_missing "$pkg"
done

for cask in "${CASKS[@]}"; do
  brew_cask_install_if_missing "$cask"
done
