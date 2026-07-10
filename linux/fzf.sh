#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

if command_exists fzf; then
  echo "fzf $(fzf --version) already installed"
  exit 0
fi

GIT_TAG=$(curl -s "https://api.github.com/repos/junegunn/fzf/releases/latest" | grep -o '"tag_name": "[^"]*"' | head -1 | cut -d'"' -f4)
FZF_URL="https://github.com/junegunn/fzf/releases/download/${GIT_TAG}/fzf-${GIT_TAG}-linux_$(get_arch).tar.gz"

curl -fL "$FZF_URL" | tar -xz -C /tmp
sudo mv /tmp/fzf /usr/local/bin/

echo "fzf installed"
