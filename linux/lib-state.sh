#!/usr/bin/env bash
# State management for ~/.bootstrap/settings.json and run logs.
# Source this file — do not execute directly.

BOOTSTRAP_DIR="$HOME/.bootstrap"
BOOTSTRAP_SETTINGS="$BOOTSTRAP_DIR/settings.json"
BOOTSTRAP_LOGS="$BOOTSTRAP_DIR/logs"

_state_version() {
  local repo_dir
  repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  git -C "$repo_dir" describe --tags --always 2>/dev/null || echo "unknown"
}

_state_now() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

_state_init() {
  mkdir -p "$BOOTSTRAP_LOGS"
  if [ ! -f "$BOOTSTRAP_SETTINGS" ]; then
    cat > "$BOOTSTRAP_SETTINGS" <<'EOF'
{
  "profile": null,
  "version": null,
  "installedAt": null,
  "extras": [],
  "runs": []
}
EOF
  fi
}

# Returns a new timestamped log path (does not create the file).
new_log_file() {
  local label="$1"
  local ts
  ts="$(date -u +"%Y-%m-%dT%H%M%SZ")"
  echo "$BOOTSTRAP_LOGS/${ts}-${label}.log"
}

# state_set_profile <profile> <version>
# Sets profile, version, and installedAt (first install) or updates version on re-run.
state_set_profile() {
  local profile="$1" version="$2" now
  now="$(_state_now)"
  _state_init

  local existing
  existing="$(jq -r '.profile // empty' "$BOOTSTRAP_SETTINGS" 2>/dev/null || true)"

  if [ -z "$existing" ] || [ "$existing" = "null" ]; then
    # First install
    jq --arg p "$profile" --arg v "$version" --arg t "$now" \
      '.profile = $p | .version = $v | .installedAt = $t' \
      "$BOOTSTRAP_SETTINGS" > "${BOOTSTRAP_SETTINGS}.tmp" && mv "${BOOTSTRAP_SETTINGS}.tmp" "$BOOTSTRAP_SETTINGS"
  else
    # Re-run: update version only
    jq --arg v "$version" '.version = $v' \
      "$BOOTSTRAP_SETTINGS" > "${BOOTSTRAP_SETTINGS}.tmp" && mv "${BOOTSTRAP_SETTINGS}.tmp" "$BOOTSTRAP_SETTINGS"
  fi
}

# state_add_extra <name> <version>
# Adds or updates an extra entry (idempotent by name).
state_add_extra() {
  local name="$1" version="$2" now
  now="$(_state_now)"
  _state_init

  jq --arg n "$name" --arg v "$version" --arg t "$now" '
    .extras = (
      [.extras[] | select(.name != $n)] +
      [{"name": $n, "version": $v, "installedAt": $t}]
    )' \
    "$BOOTSTRAP_SETTINGS" > "${BOOTSTRAP_SETTINGS}.tmp" && mv "${BOOTSTRAP_SETTINGS}.tmp" "$BOOTSTRAP_SETTINGS"
}

# record_run <command_label> <log_file> <exit_code>
# Appends a run entry. Pass empty string for log_file when there is no log.
# Keeps only the 50 most recent runs.
record_run() {
  local label="$1" log_file="$2" exit_code="$3"
  local version now
  version="$(_state_version)"
  now="$(_state_now)"
  _state_init

  jq --arg cmd "$label" --arg v "$version" --arg t "$now" \
     --arg log "$log_file" --argjson rc "$exit_code" '
    .runs = (
      [{"at": $t, "command": $cmd, "version": $v, "exitCode": $rc,
        "log": (if $log == "" then null else $log end)}] + .runs
    ) | .runs = .runs[:50]' \
    "$BOOTSTRAP_SETTINGS" > "${BOOTSTRAP_SETTINGS}.tmp" && mv "${BOOTSTRAP_SETTINGS}.tmp" "$BOOTSTRAP_SETTINGS"
}

# run_with_log <label> <command> [args...]
# Runs a command, tees output to a timestamped log file, then records the run.
run_with_log() {
  local label="$1"; shift
  local log_file
  log_file="$(new_log_file "$label")"
  _state_init

  echo "Logging to $log_file"
  set +e
  "$@" 2>&1 | tee "$log_file"
  local exit_code="${PIPESTATUS[0]}"
  set -e

  record_run "$label" "$log_file" "$exit_code"
  return "$exit_code"
}
