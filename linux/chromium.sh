#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

if command_exists chromium || command_exists google-chrome; then
  if command_exists chromium; then
    echo "Chromium $(chromium --version) already installed"
  else
    echo "Chrome $(google-chrome --version) already installed"
  fi
  exit 0
fi

# Add Google Chrome PPA
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null

apt_update_if_stale
apt_install_if_missing google-chrome-stable

echo "Chrome installed"
