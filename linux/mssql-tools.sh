#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if command_exists sqlcmd; then
  echo "mssql-tools already installed: $(sqlcmd -? 2>&1 | head -1)"
  exit 0
fi

echo "Installing mssql-tools18..."

# Always refresh the GPG key
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
  | sudo gpg --yes --dearmor -o /usr/share/keyrings/microsoft-prod.gpg

UBUNTU_VERSION="$(lsb_release -rs)"

# Known Ubuntu versions with Microsoft package support
MSFT_SUPPORTED_VERSIONS=("20.04" "22.04" "24.04")
MSFT_UBUNTU_VERSION="$UBUNTU_VERSION"

supported=false
for v in "${MSFT_SUPPORTED_VERSIONS[@]}"; do
  [ "$UBUNTU_VERSION" = "$v" ] && supported=true && break
done

if [ "$supported" = false ]; then
  MSFT_UBUNTU_VERSION="24.04"
  echo "NOTE: Ubuntu ${UBUNTU_VERSION} not yet supported by Microsoft packages, using ${MSFT_UBUNTU_VERSION}"
fi

# Always rewrite the source list so it reflects the correct (possibly fallback) version
sudo rm -f /etc/apt/sources.list.d/mssql-release.list
curl -fsSL "https://packages.microsoft.com/config/ubuntu/${MSFT_UBUNTU_VERSION}/prod.list" \
  | sudo tee /etc/apt/sources.list.d/mssql-release.list > /dev/null

sudo apt update
sudo ACCEPT_EULA=Y apt install -y mssql-tools18 unixodbc-dev

# Add sqlcmd/bcp to PATH for all shells
if [ ! -f /etc/profile.d/mssql-tools.sh ]; then
  echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' | sudo tee /etc/profile.d/mssql-tools.sh > /dev/null
fi

export PATH="$PATH:/opt/mssql-tools18/bin"
echo "mssql-tools18 installed: $(sqlcmd -? 2>&1 | head -1)"
