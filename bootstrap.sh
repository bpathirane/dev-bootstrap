#!/usr/bin/env bash
# Single entry point for all platforms.
# Usage (fresh machine, one-liner):
#   curl -fsSL https://raw.githubusercontent.com/bpathirane/dev-bootstrap/main/bootstrap.sh | bash
set -euo pipefail

REPO_URL="https://github.com/bpathirane/dev-bootstrap.git"
REPO_DIR="$HOME/source/github_personal/dev-bootstrap"

PROFILE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      PROFILE="${2:-}"
      shift 2
      ;;
    --profile=*)
      PROFILE="${1#*=}"
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [--profile vm|wsl|desktop|minimal|thin-client]"
      exit 0
      ;;
    *)
      shift
      ;;
  esac
 done

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

    # Default behavior: route to profile-specific installers
    case "${PROFILE:-}" in
      vm|desktop|minimal|wsl|thin-client)
        if [ "${PROFILE}" = "thin-client" ] && [ "$(uname -s)" = "Darwin" ]; then
          exec "$REPO_DIR/macos/install-thin-client.sh"
        elif [ -x "$REPO_DIR/linux/install-${PROFILE}.sh" ]; then
          exec "$REPO_DIR/linux/install-${PROFILE}.sh"
        else
          exec "$REPO_DIR/linux/install.sh"
        fi
        ;;
      "")
        if grep -qi microsoft /proc/version 2>/dev/null; then
          exec "$REPO_DIR/linux/install-wsl.sh"
        else
          exec "$REPO_DIR/linux/install-vm.sh"
        fi
        ;;
      *)
        echo "Unknown profile: $PROFILE" >&2
        exit 2
        ;;
    esac
    ;;

  Darwin)
    if [ "${PROFILE:-}" = "thin-client" ]; then
      if [ -x "$REPO_DIR/macos/install-thin-client.sh" ]; then
        exec "$REPO_DIR/macos/install-thin-client.sh"
      fi
    fi
    echo "macOS support is not yet implemented for full Linux bootstrap." >&2
    echo "Use the thin-client profile or Homebrew on macOS instead." >&2
    echo "Track progress: https://github.com/bpathirane/dev-bootstrap" >&2
    exit 1
    ;;

  *)
    echo "Unsupported OS: $OS" >&2
    exit 1
    ;;
esac
