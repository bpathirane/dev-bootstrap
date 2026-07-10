#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

# Install the PostgreSQL client from the official PGDG apt repo.
# Installs the latest stable client; override with PG_VERSION=15 ./postgres-client.sh
PG_VERSION="${PG_VERSION:-}"

if ! command_exists lsb_release; then
  sudo apt install -y lsb-release
fi

DISTRO="$(lsb_release -cs)"

# Add PGDG repo if not already present
# Always refresh the GPG key (guards against stale/corrupt keyring from prior runs)
echo "Adding PostgreSQL apt repository (pgdg)..."
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
  | sudo gpg --dearmor -o /usr/share/keyrings/postgresql.gpg

if [ ! -f /etc/apt/sources.list.d/pgdg.list ]; then
  echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] https://apt.postgresql.org/pub/repos/apt ${DISTRO}-pgdg main" \
    | sudo tee /etc/apt/sources.list.d/pgdg.list > /dev/null
fi
sudo apt update

if [ -n "$PG_VERSION" ]; then
  PKG="postgresql-client-${PG_VERSION}"
else
  PKG="postgresql-client"
fi

apt_install_if_missing "$PKG"

echo "PostgreSQL client installed: $(psql --version)"
