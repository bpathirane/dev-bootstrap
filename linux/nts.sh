#!/usr/bin/env bash
# Sets up chrony with NTS (Network Time Security) for authenticated time sync.
# Replaces or supplements the default systemd-timesyncd configuration.
# Safe to rerun — idempotent.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

NTS_SERVER="${NTS_SERVER:-time.cloudflare.com}"
TIMEZONE="${TIMEZONE:-America/New_York}"

# Set system timezone
current_tz="$(timedatectl show --property=Timezone --value 2>/dev/null || true)"
if [ "$current_tz" != "$TIMEZONE" ]; then
  echo "Setting timezone to $TIMEZONE..."
  sudo timedatectl set-timezone "$TIMEZONE"
else
  echo "Timezone already set to $TIMEZONE"
fi

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
  # Ensure makestep allows stepping always (-1), not just first N updates
  sudo sed -i 's/^makestep 1\.0 [0-9]\+$/makestep 1.0 -1/' "$CHRONY_CONF"
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

# Force immediate step to correct any existing drift
sudo chronyc makestep

# ── Resume-from-suspend hook ───────────────────────────────────────────────
# Fires within seconds of VM resume (e.g. MacBook lid open), stepping the
# clock before any cron jobs or SSH sessions become active.
RESUME_UNIT=/etc/systemd/system/chrony-resume.service
if [ ! -f "$RESUME_UNIT" ]; then
  echo "Installing chrony-resume.service..."
  sudo tee "$RESUME_UNIT" > /dev/null <<'EOF'
[Unit]
Description=Force chrony clock step on resume from suspend
After=suspend.target hibernate.target hybrid-sleep.target

[Service]
Type=oneshot
ExecStart=/usr/bin/chronyc makestep

[Install]
WantedBy=suspend.target hibernate.target hybrid-sleep.target
EOF
  sudo systemctl daemon-reload
  sudo systemctl enable chrony-resume.service
else
  echo "chrony-resume.service already installed"
fi

# Give chrony a moment to contact the time server
sleep 2

echo "Time sync status:"
chronyc tracking | grep -E "Reference|System time|Stratum|NTP"

echo "NTS associations:"
sudo chronyc authdata 2>/dev/null || echo "(authdata not available — may need chrony >= 4.0)"
