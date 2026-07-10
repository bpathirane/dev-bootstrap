#!/usr/bin/env bash
# Single entry point for all platforms.
# Usage:
#   bootstrap [install|validate|extras|pull|status] [--profile <name>] [<extra>]
#
# One-liner (fresh machine):
#   curl -fsSL https://raw.githubusercontent.com/bpathirane/dev-bootstrap/main/bootstrap.sh | bash -s -- install --profile vm
set -euo pipefail

REPO_URL="https://github.com/bpathirane/dev-bootstrap.git"
REPO_DIR="$HOME/source/github_personal/dev-bootstrap"

# ── Extras registry ────────────────────────────────────────────────────────
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
    install|validate|extras|pull|status)
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
Usage: bootstrap [install|validate|extras|pull|status] [options]

Subcommands:
  install              Install a profile (default)
  validate             Validate an installed profile
  extras <name>        Install an extra on top of the current profile
  pull                 Pull latest changes from GitHub and report version change
  status               Show installed profile, version, extras, and last run

Options:
  --profile <name>     Profile: vm, wsl, desktop, minimal, thin-client
  --list               List available extras (with 'extras' subcommand)

Examples:
  bootstrap install --profile vm
  bootstrap validate --profile vm
  bootstrap extras dotfiles
  bootstrap extras --list
  bootstrap pull
  bootstrap status
EOF
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      exit 2
      ;;
    *)
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

# ── Repo helpers ───────────────────────────────────────────────────────────

_repo_ensure() {
  if ! command -v git >/dev/null 2>&1; then
    echo "Installing git..."
    sudo apt-get update -qq && sudo apt-get install -y -qq git
  fi
  if [ ! -d "$REPO_DIR/.git" ]; then
    mkdir -p "$(dirname "$REPO_DIR")"
    git clone "$REPO_URL" "$REPO_DIR"
  fi
}

_repo_pull() {
  _repo_ensure
  local before after
  before="$(git -C "$REPO_DIR" describe --tags --always 2>/dev/null || echo "unknown")"
  echo "Pulling from origin/main..."
  git -C "$REPO_DIR" pull
  after="$(git -C "$REPO_DIR" describe --tags --always 2>/dev/null || echo "unknown")"
  if [ "$before" != "$after" ]; then
    echo "Updated: $before → $after"
  else
    echo "Already up to date ($after)"
  fi
}

# ── Bootstrap: ensure repo, register globally, load state lib ─────────────
_repo_ensure

mkdir -p "$HOME/.local/bin"
ln -sf "$REPO_DIR/bootstrap.sh" "$HOME/.local/bin/bootstrap"
chmod +x "$REPO_DIR/bootstrap.sh"

# shellcheck source=linux/lib-state.sh
source "$REPO_DIR/linux/lib-state.sh"

VERSION="$(_state_version)"

# ── Subcommand dispatch ────────────────────────────────────────────────────
case "$SUBCOMMAND" in

  pull)
    before="$(git -C "$REPO_DIR" describe --tags --always 2>/dev/null || echo "unknown")"
    _repo_pull
    after="$(git -C "$REPO_DIR" describe --tags --always 2>/dev/null || echo "unknown")"
    # Record the pull in run history
    record_run "pull" "" 0
    # Advise if version changed and profile is installed
    if [ "$before" != "$after" ] && [ -f "$BOOTSTRAP_SETTINGS" ]; then
      installed_profile="$(jq -r '.profile // empty' "$BOOTSTRAP_SETTINGS" 2>/dev/null || true)"
      if [ -n "$installed_profile" ] && [ "$installed_profile" != "null" ]; then
        echo "Run 'bootstrap install --profile $installed_profile' to apply the update."
      fi
    fi
    ;;

  status)
    _state_init
    repo_version="$(_state_version)"

    # Read installed state
    installed_profile="$(jq -r '.profile  // "none"'      "$BOOTSTRAP_SETTINGS")"
    installed_version="$(jq -r '.version  // "none"'      "$BOOTSTRAP_SETTINGS")"
    installed_at="$(    jq -r '.installedAt // "-"'        "$BOOTSTRAP_SETTINGS")"

    # Repo version vs installed version
    if [ "$installed_version" = "$repo_version" ]; then
      version_line="$installed_version (up to date)"
    else
      version_line="$installed_version installed  →  $repo_version available  (run: bootstrap pull && bootstrap install --profile $installed_profile)"
    fi

    # Check if repo is behind origin (requires fetch — skip silently if offline)
    remote_version=""
    if git -C "$REPO_DIR" fetch --quiet origin 2>/dev/null; then
      remote_sha="$(git -C "$REPO_DIR" rev-parse origin/main 2>/dev/null || true)"
      local_sha="$(git -C "$REPO_DIR" rev-parse HEAD 2>/dev/null || true)"
      if [ -n "$remote_sha" ] && [ "$remote_sha" != "$local_sha" ]; then
        remote_version="$(git -C "$REPO_DIR" describe --tags --always origin/main 2>/dev/null || true)"
        if [ -n "$remote_version" ] && [ "$remote_version" != "$repo_version" ]; then
          version_line="$version_line  (GitHub: $remote_version — run: bootstrap pull)"
        else
          version_line="$version_line  (commits available on GitHub — run: bootstrap pull)"
        fi
      fi
    fi

    echo "Profile:   $installed_profile  (installed $installed_at)"
    echo "Version:   $version_line"

    echo ""
    echo "Extras:"
    extras_count="$(jq '.extras | length' "$BOOTSTRAP_SETTINGS")"
    if [ "$extras_count" = "0" ]; then
      echo "  (none)"
    else
      jq -r '.extras[] | "  \(.name)  v\(.version)  \(.installedAt)"' "$BOOTSTRAP_SETTINGS"
    fi

    echo ""
    echo "Last run:"
    last_run="$(jq -r '.runs[0] // empty' "$BOOTSTRAP_SETTINGS")"
    if [ -z "$last_run" ]; then
      echo "  (none)"
    else
      jq -r '.runs[0] | "  \(.at)  \(.command)  exit:\(.exitCode)\(if .log != "" then "  log:\(.log)" else "" end)"' "$BOOTSTRAP_SETTINGS"
    fi
    ;;

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
    _repo_pull

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

    # Reload VERSION after pull
    VERSION="$(_state_version)"

    run_with_log "install-${PROFILE}" "$script"
    exit_code=$?
    if [ $exit_code -eq 0 ]; then
      state_set_profile "$PROFILE" "$VERSION"
      echo "Profile '$PROFILE' v${VERSION} recorded in ~/.bootstrap/settings.json"
    fi
    exit $exit_code
    ;;

esac
