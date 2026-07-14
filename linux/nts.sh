#!/usr/bin/env bash
# Sets up chrony with NTS (Network Time Security) for authenticated time sync.
# Replaces or supplements the default systemd-timesyncd configuration.
# Safe to rerun — idempotent.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

NTS_SERVER="${NTS_SERVER:-time.cloudflare.com}"

# chrony supports NTS; timesyncd does not
if ! command_exists chronyd; then
  echo "Installing chrony..."
  sudo DEBIAN_FRONTEND=noninteractive apt install -y chrony
fi

# Disable timesyncd to avoid conflicts with chrony
if systemctl is-active --quiet systemd-timesyncd 2>/dev/null; then
  echo "Disabling systemd-timesyncd..."
  sudo systemctl disable --now systemd-timesyncd
fi

CHRONY_CONF=/etc/chrony/chrony.conf
MARKER="# nts-setup"

if grep -qF "$MARKER" "$CHRONY_CONF" 2>/dev/null; then
  echo "NTS already configured in $CHRONY_CONF"
else
  echo "Configuring NTS server: $NTS_SERVER"
  sudo tee -a "$CHRONY_CONF" > /dev/null <<EOF

$MARKER
server $NTS_SERVER iburst nts
# Fall back to unsigned pool if NTS server is unreachable
pool ntp.ubuntu.com iburst maxsources 4
makestep 1.0 -1
rtcsync
EOF
fi

sudo systemctl enable --now chrony

# Give chrony a moment to contact the time server
sleep 2

echo "Time sync status:"
chronyc tracking | grep -E "Reference|System time|Stratum|NTP"

echo "NTS associations:"
sudo chronyc authdata 2>/dev/null || echo "(authdata not available — may need chrony >= 4.0)"
