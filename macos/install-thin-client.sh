#!/usr/bin/env bash
set -euo pipefail

if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew for macOS..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew installation failed." >&2
  exit 1
fi

echo "Installing thin-client packages via Brewfile..."
brew bundle --file "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/Brewfile.thin-client"

echo "macOS thin-client install complete."
