#!/usr/bin/env bash
# Single entry point for all platforms.
# Usage (fresh machine, one-liner):
#   curl -fsSL https://raw.githubusercontent.com/bpathirane/dev-bootstrap/main/bootstrap.sh | bash
set -euo pipefail

REPO_URL="https://github.com/bpathirane/dev-bootstrap.git"
REPO_DIR="$HOME/source/github_personal/dev-bootstrap"

OS="$(uname -s)"

case "$OS" in
  Linux)
    if ! command -v git >/dev/null 2>&1; then
      echo "Installing git..."
      sudo apt-get update -qq && sudo apt-get install -y -qq git
    fi

    if [ ! -d "$REPO_DIR/.git" ]; then
      mkdir -p "$(dirname "$REPO_DIR")"
      git clone "$REPO_URL" "$REPO_DIR"
    else
      git -C "$REPO_DIR" pull
    fi

    exec "$REPO_DIR/linux/install.sh"
    ;;

  Darwin)
    echo "macOS support is not yet implemented." >&2
    echo "Track progress: https://github.com/bpathirane/dev-bootstrap" >&2
    exit 1
    ;;

  *)
    echo "Unsupported OS: $OS" >&2
    exit 1
    ;;
esac
