#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

MISSING=()
for cmd in brew git gh chezmoi ssh; do
  if ! command_exists "$cmd"; then
    MISSING+=("$cmd")
  fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "Missing thin-client tools: ${MISSING[*]}" >&2
  exit 1
fi

echo "Thin-client tools present:"
for cmd in brew git gh chezmoi ssh; do
  echo " - $cmd: $(command -v $cmd)"
done

exit 0
