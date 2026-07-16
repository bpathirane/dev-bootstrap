#!/usr/bin/env bash
# Clamps the default route's MTU to work around a Path MTU black hole seen on
# some virtualized/NAT'd networks (e.g. Multipass/UTM VMs bridged through a
# hypervisor NAT). Symptom: small HTTPS requests succeed instantly, but any
# request with a body over ~1KB (e.g. a real `claude` prompt with system
# prompt + tool schemas) hangs forever with zero bytes returned.
#
# Root cause: some hop on the path has a real link MTU below 1500, so TCP
# segments that fill a full 1500-byte packet get silently dropped. Normally
# the sender would learn to shrink its packets via an ICMP "fragmentation
# needed" reply (Path MTU Discovery), but that ICMP message is being filtered
# somewhere on the route — so the connection just stalls with no error
# instead of negotiating a smaller size.
#
# Fix: lower the MTU on the default route so this host never sends a segment
# large enough to hit the black hole in the first place. This has to be done
# in netplan (not just `ip route`) so it survives reboots and DHCP renewals —
# a plain `ip route change ... mtu 1400` is only a live/in-memory override.
#
# NOTE: MSS clamping via iptables (`TCPMSS --set-mss`) looks like the "right"
# fix but only affects segment sizes the *other side* sends *to us* — it does
# nothing for large payloads *we* send *to them*, which is the direction that
# was actually failing here (uploading a big prompt). Lowering our own route
# MTU is what actually caps our outbound segment size.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

MTU="${MTU_FIX_VALUE:-1400}"
NETPLAN_DIR="/etc/netplan"
NETPLAN_FILE="$NETPLAN_DIR/99-mtu-fix.yaml"

if ! command_exists netplan; then
  echo "netplan not found — this fix is only wired up for netplan-managed Ubuntu hosts." >&2
  exit 1
fi

# The interface carrying the default route — detected rather than hardcoded,
# since VM NIC names vary (enp0s1, eth0, ens3, ...).
IFACE="$(ip route show default | awk '/default/ {print $5; exit}')"
if [ -z "$IFACE" ]; then
  echo "Could not determine the default route interface — is there a default route?" >&2
  exit 1
fi

if [ -f "$NETPLAN_FILE" ] && grep -q "mtu: $MTU" "$NETPLAN_FILE" 2>/dev/null; then
  echo "MTU fix already applied in $NETPLAN_FILE (mtu: $MTU on $IFACE), skipping."
else
  echo "Writing MTU fix for interface '$IFACE' (mtu: $MTU) to $NETPLAN_FILE..."
  sudo tee "$NETPLAN_FILE" > /dev/null <<EOF
# Written by linux/mtu-fix.sh — see that script for why this exists.
network:
  version: 2
  ethernets:
    $IFACE:
      mtu: $MTU
EOF
  # netplan requires config files to be root-only or it refuses to apply them.
  sudo chmod 600 "$NETPLAN_FILE"
  sudo netplan apply
  echo "Applied. Current default route:"
  ip route show default
fi
