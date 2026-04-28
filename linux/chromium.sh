#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

# Snap doesn't work in WSL2 — install Google Chrome stable from Google's apt repo instead.
# After install, set PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/google-chrome-stable
# so Playwright uses the system Chrome rather than downloading its own.

if command_exists google-chrome-stable; then
  echo "google-chrome-stable $(google-chrome-stable --version 2>/dev/null || echo '?') already installed"
  exit 0
fi

echo "Installing Google Chrome stable..."
curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
  | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] \
https://dl.google.com/linux/chrome/deb/ stable main" \
  | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null
sudo apt update -qq
sudo DEBIAN_FRONTEND=noninteractive apt install -y google-chrome-stable

echo "google-chrome-stable installed: $(google-chrome-stable --version)"
