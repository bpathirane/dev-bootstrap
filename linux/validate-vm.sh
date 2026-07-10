#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

MISSING=()
REQUIRED=(git curl wget jq ripgrep fzf tmux neovim)
for cmd in "${REQUIRED[@]}"; do
  if ! command_exists "$cmd"; then
    MISSING+=("$cmd")
  fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "Missing required tools: ${MISSING[*]}" >&2
  exit 1
else
  echo "All required VM tools are present." 
fi

echo "Optional tools (not required):"
for opt in lazygit kubectl helm kind gh; do
  if command_exists "$opt"; then
    echo " - $opt: $(command -v $opt)"
  else
    echo " - $opt: MISSING"
  fi
done

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
