#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

if command_exists uv; then
  echo "uv $(uv --version) already installed"
  exit 0
fi

curl -LsSf https://astral.sh/uv/install.sh | sh

echo "uv installed"
