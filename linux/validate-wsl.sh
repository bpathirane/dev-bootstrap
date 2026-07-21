#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
source "$SCRIPT_DIR/profile-wsl.sh"

if ! is_wsl; then
  echo "validate-wsl.sh should only be run inside WSL." >&2
  exit 2
fi

MISSING=()
for cmd in "${WSL_REQUIRED_CMDS[@]}"; do
  command_exists "$cmd" || MISSING+=("$cmd")
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "Missing required tools: ${MISSING[*]}" >&2
  exit 1
fi

if [ ! -f /mnt/c/Windows/System32/reg.exe ]; then
  echo "/mnt/c is not mounted or accessible." >&2
  exit 1
fi

echo "WSL validation passed."
