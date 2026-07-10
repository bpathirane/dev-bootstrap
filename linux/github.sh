#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

if command_exists gh; then
  echo "GitHub CLI $(gh --version | head -1) already installed"
  exit 0
fi

curl -fsSL https://cli.github.com/install.sh | sudo bash

echo "GitHub CLI installed"
