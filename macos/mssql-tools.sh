#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# go-sqlcmd: native arm64/amd64, no EULA tap required.
# Replaces the legacy mssql-tools18 sqlcmd for most use cases (excluding bcp).
if command_exists sqlcmd; then
  echo "sqlcmd already installed: $(sqlcmd --version 2>&1 | head -1)"
  exit 0
fi

echo "Installing sqlcmd (go-sqlcmd)..."
brew_install_if_missing sqlcmd
echo "sqlcmd installed: $(sqlcmd --version 2>&1 | head -1)"
