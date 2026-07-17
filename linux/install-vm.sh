#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

echo "Starting VM profile install..."

apt_update_if_stale

BASE_PKGS=(
  age bat bison build-essential ca-certificates cifs-utils curl direnv fd-find
  git gnupg htop jq krb5-user libevent-dev libxml2-utils lsb-release ncurses-dev
  pkg-config ripgrep unzip wget zsh
)
for pkg in "${BASE_PKGS[@]}"; do
  apt_install_if_missing "$pkg"
done

# Prefer Homebrew for fast-moving dev tools.
"$SCRIPT_DIR/install-brew.sh" || true

BREW_TOOLS=(neovim tmux lazygit yazi fzf fd ripgrep gh azure-cli awscli kubectl helm k9s zoxide starship just uv tldr sops fnm node)
for tool in "${BREW_TOOLS[@]}"; do
  if command_exists brew; then
    brew_install_if_missing "$tool" || true
  fi
done

# Optional runtime and cloud tooling
"$SCRIPT_DIR/aws.sh" || true
"$SCRIPT_DIR/azure-cli.sh" || true
"$SCRIPT_DIR/github.sh" || true
"$SCRIPT_DIR/k8s.sh" || true
"$SCRIPT_DIR/uv.sh" || true
"$SCRIPT_DIR/ruff.sh" || true
"$SCRIPT_DIR/bun.sh" || true
"$SCRIPT_DIR/dotnet.sh" || true

cat <<'EOF'
VM profile install complete.
Run ./linux/validate-vm.sh to verify.
Optional follow-up steps:
  ./linux/install-dotfiles.sh
  ./linux/install-identity.sh
  ./linux/install-ai.sh
  ./linux/nts.sh              # set up chrony + NTS for authenticated time sync
EOF
