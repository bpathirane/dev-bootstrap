#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
source "$SCRIPT_DIR/profile-vm.sh"

MISSING=()
for cmd in "${VM_BASE_CMDS[@]}"; do
  command_exists "$cmd" || MISSING+=("$cmd")
done
for entry in "${VM_BREW_TOOLS[@]}"; do
  cmd="${entry##*:}"
  command_exists "$cmd" || MISSING+=("$cmd")
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "Missing required tools: ${MISSING[*]}" >&2
  exit 1
else
  echo "All required VM tools are present."
fi

# ── Timezone check ─────────────────────────────────────────────────────────
tz="$(timedatectl show --property=Timezone --value 2>/dev/null || true)"
if [ "$tz" != "America/New_York" ]; then
  echo "Wrong timezone: ${tz:-unknown} (expected America/New_York). Run ./linux/nts.sh to fix." >&2
  exit 1
else
  echo "Timezone OK ($tz)"
fi

# ── Time sync check ────────────────────────────────────────────────────────
MAX_DRIFT_SECONDS=5
TIME_OK=true

if command_exists chronyc; then
  # chrony reports offset in seconds (may be negative)
  offset_raw="$(chronyc tracking 2>/dev/null | awk '/System time/ {print $4}')"
  offset="${offset_raw#-}"   # absolute value
  if [ -n "$offset" ]; then
    # compare using awk since bash can't do float comparison
    if awk "BEGIN { exit ($offset > $MAX_DRIFT_SECONDS) ? 0 : 1 }"; then
      echo "WARN: Clock drift ${offset}s exceeds ${MAX_DRIFT_SECONDS}s threshold (chrony)" >&2
      TIME_OK=false
    else
      echo "Time sync OK via chrony (drift: ${offset}s)"
    fi
  else
    echo "WARN: chrony is installed but not tracking any server" >&2
    TIME_OK=false
  fi
elif command_exists timedatectl; then
  sync_status="$(timedatectl show --property=NTPSynchronized --value 2>/dev/null || true)"
  if [ "$sync_status" = "yes" ]; then
    echo "Time sync OK via systemd-timesyncd (NTPSynchronized=yes)"
    echo "NOTE: systemd-timesyncd does not support NTS. Run ./linux/nts.sh to upgrade to chrony+NTS."
  else
    echo "WARN: NTP not synchronized (timedatectl NTPSynchronized=no)" >&2
    TIME_OK=false
  fi
else
  echo "WARN: No time sync client found (chrony or systemd-timesyncd). Run ./linux/nts.sh to set up NTS." >&2
  TIME_OK=false
fi

if [ "$TIME_OK" = false ]; then
  echo "To fix: run ./linux/nts.sh" >&2
  exit 1
fi

exit 0
