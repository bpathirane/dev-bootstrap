#!/usr/bin/env bash
set -euo pipefail

MISSING=()
for cmd in brew wezterm code chezmoi git gh ssh; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    MISSING+=("$cmd")
  fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "Missing thin-client tools: ${MISSING[*]}" >&2
  exit 1
fi

echo "macOS thin-client validation passed."
exit 0
