#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

if command_exists az; then
  echo "Azure CLI $(az version --output tsv | head -1) already installed"
  exit 0
fi

curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

echo "Azure CLI installed"
