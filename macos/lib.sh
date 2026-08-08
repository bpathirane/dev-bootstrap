#!/usr/bin/env bash

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

get_arch() {
  case "$(uname -m)" in
    x86_64)          echo "amd64" ;;
    arm64 | aarch64) echo "arm64" ;;
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
  esac
}

brew_install_if_missing() {
  if brew list "$1" &>/dev/null; then
    echo "$1 already installed, skipping"
  else
    brew install "$1"
  fi
}

brew_cask_install_if_missing() {
  if brew list --cask "$1" &>/dev/null; then
    echo "$1 (cask) already installed, skipping"
  else
    brew install --cask "$1"
  fi
}

ensure_directory() {
  mkdir -p "$1"
}
