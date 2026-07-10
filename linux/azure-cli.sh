#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

if command_exists az; then
  echo "Azure CLI $(az version --output tsv 2>/dev/null | head -1) already installed"
  exit 0
fi

echo "Installing Azure CLI..."

apt_install_if_missing ca-certificates curl apt-transport-https lsb-release gnupg

# Always refresh Microsoft GPG key
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
  | sudo gpg --yes --dearmor -o /usr/share/keyrings/microsoft-prod.gpg

CODENAME="$(lsb_release -cs)"

# Remove all pre-existing Microsoft repo files (both .list and .sources formats)
# to ensure only our signed-by entry remains
for f in /etc/apt/sources.list.d/azure-cli.list \
          /etc/apt/sources.list.d/azure-cli.sources \
          /etc/apt/sources.list.d/microsoft.list \
          /etc/apt/sources.list.d/microsoft.sources \
          /etc/apt/sources.list.d/microsoft-prod.list \
          /etc/apt/sources.list.d/microsoft-prod.sources; do
  if [ -f "$f" ]; then
    echo "Removing existing Microsoft repo file: $f"
    sudo rm -f "$f"
  fi
done

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/repos/azure-cli ${CODENAME} main" \
  | sudo tee /etc/apt/sources.list.d/azure-cli.list > /dev/null

sudo apt update
sudo apt install -y azure-cli

echo "Azure CLI installed: $(az version --output tsv 2>/dev/null | head -1)"
