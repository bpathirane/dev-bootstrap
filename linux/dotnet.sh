#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

DOTNET_HOME="$HOME/.dotnet"
DOTNET_INSTALL="$DOTNET_HOME/dotnet-install.sh"

install_dotnet_sdk() {
  local channel="$1"
  if dotnet --list-sdks 2>/dev/null | grep -q "^${channel%%.*}\."; then
    echo ".NET SDK ${channel} already installed"
    return
  fi
  echo "Installing .NET SDK ${channel}..."
  if [ ! -f "$DOTNET_INSTALL" ]; then
    apt_install_if_missing wget
    wget -q "https://dot.net/v1/dotnet-install.sh" -O "$DOTNET_INSTALL"
    chmod +x "$DOTNET_INSTALL"
  fi
  "$DOTNET_INSTALL" --channel "$channel" --install-dir "$DOTNET_HOME" --no-path
}

install_dotnet_sdk "8.0"
install_dotnet_sdk "10.0"

echo ".NET SDKs installed:"
"$DOTNET_HOME/dotnet" --list-sdks
