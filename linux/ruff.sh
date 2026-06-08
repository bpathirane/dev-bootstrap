#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

if command_exists ruff; then
  echo "ruff $(ruff --version) already installed"
  exit 0
fi

if ! command_exists uv; then
  echo "ERROR: uv not found — install uv before ruff" >&2
  exit 1
fi

uv tool install ruff

echo "ruff $(ruff --version) installed"
