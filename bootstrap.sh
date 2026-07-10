#!/usr/bin/env bash
# Single entry point for all platforms.
# Usage:
#   bootstrap [install|validate|extras] [--profile vm|wsl|desktop|minimal|thin-client] [<extra>]
#
# One-liner (fresh machine):
#   curl -fsSL https://raw.githubusercontent.com/bpathirane/dev-bootstrap/main/bootstrap.sh | bash -s -- install --profile vm
set -euo pipefail

REPO_URL="https://github.com/bpathirane/dev-bootstrap.git"
REPO_DIR="$HOME/source/github_personal/dev-bootstrap"

# ── Extras registry ────────────────────────────────────────────────────────
# Maps extra name → script path relative to linux/
declare -A EXTRAS=(
  [dotfiles]="install-dotfiles.sh"
  [identity]="install-identity.sh"
  [nts]="nts.sh"
  [ai]="install-ai.sh"
)

_extras_list() {
  for name in $(echo "${!EXTRAS[@]}" | tr ' ' '\n' | sort); do
    echo "  $name"
  done
}

# ── Argument parsing ───────────────────────────────────────────────────────
SUBCOMMAND="install"
PROFILE=""
EXTRA=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    install|validate|extras)
      SUBCOMMAND="$1"
      shift
      ;;
    --profile)
      PROFILE="${2:-}"
      shift 2
      ;;
    --profile=*)
      PROFILE="${1#*=}"
      shift
      ;;
    --list)
      echo "Available extras:"
      _extras_list
      exit 0
      ;;
    -h|--help)
      cat <<'EOF'
Usage: bootstrap [install|validate|extras] [options]

Subcommands:
  install              Install a profile (default)
  validate             Validate an installed profile
  extras <name>        Install an extra on top of the current profile

Options:
  --profile <name>     Profile: vm, wsl, desktop, minimal, thin-client
  --list               List available extras (with 'extras' subcommand)

Examples:
  bootstrap install --profile vm
  bootstrap validate --profile vm
  bootstrap extras dotfiles
  bootstrap extras --list
EOF
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      exit 2
      ;;
    *)
      # Positional after subcommand — treat as extra name
      if [ "$SUBCOMMAND" = "extras" ] && [ -z "$EXTRA" ]; then
        EXTRA="$1"
        shift
      else
        echo "Unknown argument: $1" >&2
        exit 2
      fi
      ;;
  esac
done

# ── OS gate ────────────────────────────────────────────────────────────────
OS="$(uname -s)"

if [ "$OS" = "Darwin" ]; then
  if [ "${PROFILE:-}" = "thin-client" ] && [ -x "$REPO_DIR/macos/install-thin-client.sh" ]; then
    exec "$REPO_DIR/macos/install-thin-client.sh"
  fi
  echo "macOS support is not yet implemented for full Linux bootstrap." >&2
  echo "Use the thin-client profile or Homebrew on macOS instead." >&2
  exit 1
elif [ "$OS" != "Linux" ]; then
  echo "Unsupported OS: $OS" >&2
  exit 1
fi

# ── Clone / update repo ────────────────────────────────────────────────────
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

# Self-register as a global command
mkdir -p "$HOME/.local/bin"
ln -sf "$REPO_DIR/bootstrap.sh" "$HOME/.local/bin/bootstrap"
chmod +x "$REPO_DIR/bootstrap.sh"

# Source state library (requires repo to be present)
# shellcheck source=linux/lib-state.sh
source "$REPO_DIR/linux/lib-state.sh"

VERSION="$(_state_version)"

# ── Subcommand dispatch ────────────────────────────────────────────────────
case "$SUBCOMMAND" in

  validate)
    if [ -z "${PROFILE:-}" ]; then
      if grep -qi microsoft /proc/version 2>/dev/null; then PROFILE="wsl"; else PROFILE="vm"; fi
    fi
    case "$PROFILE" in
      vm|wsl|desktop) exec "$REPO_DIR/linux/validate-${PROFILE}.sh" ;;
      thin-client)    exec "$REPO_DIR/linux/validate-thin-client.sh" ;;
      *)  echo "No validator for profile: $PROFILE" >&2; exit 2 ;;
    esac
    ;;

  extras)
    if [ -z "$EXTRA" ]; then
      echo "Usage: bootstrap extras <name>" >&2
      echo "Available extras:"
      _extras_list
      exit 2
    fi
    if [ "${EXTRAS[$EXTRA]+_}" ]; then
      script="$REPO_DIR/linux/${EXTRAS[$EXTRA]}"
      run_with_log "extras-${EXTRA}" "$script"
      exit_code=$?
      if [ $exit_code -eq 0 ]; then
        state_add_extra "$EXTRA" "$VERSION"
        echo "Extra '$EXTRA' recorded in ~/.bootstrap/settings.json"
      fi
      exit $exit_code
    else
      echo "Unknown extra: $EXTRA" >&2
      echo "Available extras:"
      _extras_list
      exit 2
    fi
    ;;

  install)
    if [ -z "${PROFILE:-}" ]; then
      if grep -qi microsoft /proc/version 2>/dev/null; then PROFILE="wsl"; else PROFILE="vm"; fi
    fi

    case "$PROFILE" in
      vm|desktop|minimal|wsl)
        script="$REPO_DIR/linux/install-${PROFILE}.sh"
        ;;
      thin-client)
        if [ "$(uname -s)" = "Darwin" ]; then
          script="$REPO_DIR/macos/install-thin-client.sh"
        else
          script="$REPO_DIR/linux/install-thin-client.sh"
        fi
        ;;
      *)
        echo "Unknown profile: $PROFILE" >&2
        exit 2
        ;;
    esac

    run_with_log "install-${PROFILE}" "$script"
    exit_code=$?
    if [ $exit_code -eq 0 ]; then
      state_set_profile "$PROFILE" "$VERSION"
      echo "Profile '$PROFILE' v${VERSION} recorded in ~/.bootstrap/settings.json"
    fi
    exit $exit_code
    ;;

esac
