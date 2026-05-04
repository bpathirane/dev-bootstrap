#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if command_exists sqlcmd; then
  echo "mssql-tools already installed: $(sqlcmd -? 2>&1 | head -1)"
  exit 0
fi

echo "Installing mssql-tools18..."

# Add Microsoft GPG key and prod repo only if not already present
if [ ! -f /etc/apt/sources.list.d/microsoft-prod.list ] && [ ! -f /etc/apt/sources.list.d/mssql-release.list ]; then
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
  curl -fsSL "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list" \
    | sudo tee /etc/apt/sources.list.d/mssql-release.list > /dev/null
  sudo apt update
fi
sudo ACCEPT_EULA=Y apt install -y mssql-tools18 unixodbc-dev

# Add sqlcmd/bcp to PATH for all shells
if [ ! -f /etc/profile.d/mssql-tools.sh ]; then
  echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' | sudo tee /etc/profile.d/mssql-tools.sh > /dev/null
fi

export PATH="$PATH:/opt/mssql-tools18/bin"
echo "mssql-tools18 installed: $(sqlcmd -? 2>&1 | head -1)"
