#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if command_exists pwsh; then
  echo "PowerShell already installed: $(pwsh --version)"
  exit 0
fi

echo "Installing PowerShell..."

# Install prerequisites
apt_install_if_missing wget
apt_install_if_missing apt-transport-https
apt_install_if_missing software-properties-common

# Always refresh Microsoft GPG key
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
  | sudo gpg --yes --dearmor -o /usr/share/keyrings/microsoft-prod.gpg

UBUNTU_VERSION="$(lsb_release -rs)"
SOURCE_LIST=/etc/apt/sources.list.d/microsoft-prod.list
if [ ! -f "$SOURCE_LIST" ]; then
  echo "deb [signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/${UBUNTU_VERSION}/prod $(lsb_release -cs) main" \
    | sudo tee "$SOURCE_LIST" > /dev/null
fi

sudo apt update
sudo apt install -y powershell

echo "PowerShell installed: $(pwsh --version)"
