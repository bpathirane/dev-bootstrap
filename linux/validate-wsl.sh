#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if ! is_wsl; then
  echo "validate-wsl.sh should only be run inside WSL." >&2
  exit 2
fi

MISSING=()
for cmd in wslview win32yank wslu; do
  if ! command_exists "$cmd"; then
    MISSING+=("$cmd")
  fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "Missing WSL conveniences: ${MISSING[*]}" >&2
  exit 1
fi

if [ ! -f /mnt/c/Windows/System32/reg.exe ]; then
  echo "/mnt/c is not mounted or accessible." >&2
  exit 1
fi

echo "WSL validation passed."
