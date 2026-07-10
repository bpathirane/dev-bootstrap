#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

if command_exists dotnet; then
  echo "dotnet $(dotnet --version) already installed"
  exit 0
fi

wget https://dot.net/v1/dotnet-install.sh -O /tmp/dotnet-install.sh
chmod +x /tmp/dotnet-install.sh
/tmp/dotnet-install.sh --version latest

# Add dotnet to PATH (sourced by shell profile on next login)
echo 'export PATH=$PATH:$HOME/.dotnet' >> "$HOME/.bashrc"
echo 'export PATH=$PATH:$HOME/.dotnet' >> "$HOME/.zshrc"

echo "dotnet installed"
