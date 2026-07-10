#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

if command_exists docker; then
  echo "Docker already installed: $(docker --version)"
else
  echo "Installing Docker Engine..."

  ARCH="$(get_arch)"
  DISTRO="$(. /etc/os-release && echo "$ID")"
  CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"

  # Always refresh GPG key
  curl -fsSL "https://download.docker.com/linux/${DISTRO}/gpg" \
    | sudo gpg --yes --dearmor -o /usr/share/keyrings/docker.gpg

  # Remove all pre-existing Microsoft repo files (both .list and .sources formats)
  # to prevent unsigned entries from breaking apt update
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

  if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
    echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/${DISTRO} ${CODENAME} stable" \
      | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  fi

  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  echo "Docker Engine installed: $(docker --version)"
fi

# Add current user to docker group (avoids sudo docker)
if ! groups "$USER" | grep -qw docker; then
  echo "Adding $USER to docker group..."
  sudo usermod -aG docker "$USER"
  echo "NOTE: Log out and back in (or run 'newgrp docker') for group membership to take effect."
fi

# Enable and start Docker daemon
if command_exists systemctl; then
  sudo systemctl enable docker
  sudo systemctl start docker
fi

echo "Docker Compose: $(docker compose version)"
