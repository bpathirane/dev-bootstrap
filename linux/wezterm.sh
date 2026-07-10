#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# WezTerm is a desktop terminal emulator — skip inside WSL (it runs on the Windows host)
# and skip on macOS (homebrew handles it there, once macOS support is added).
if is_wsl; then
  echo "Skipping WezTerm install inside WSL (run WezTerm on the Windows host instead)."
  exit 0
fi

if command_exists wezterm; then
  echo "wezterm already installed: $(wezterm --version 2>/dev/null)"
  exit 0
fi

echo "Installing WezTerm..."

curl -fsSL https://apt.fury.io/wez/gpg.key \
  | sudo gpg --dearmor -o /usr/share/keyrings/wezterm-fury.gpg

echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' \
  | sudo tee /etc/apt/sources.list.d/wezterm.list > /dev/null

sudo apt update -qq
sudo DEBIAN_FRONTEND=noninteractive apt install -y wezterm

echo "wezterm installed: $(wezterm --version 2>/dev/null)"
