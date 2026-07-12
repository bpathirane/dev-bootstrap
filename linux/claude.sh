#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

if command_exists claude; then
  echo "Claude installed"
else
  curl -fsSL https://claude.ai/install.sh | bash
fi
