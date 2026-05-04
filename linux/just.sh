#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

JUST_VERSION="1.50.0"

if command_exists just; then
  current="$(just --version | grep -oP '\d+\.\d+\.\d+')"
  if [ "$current" = "$JUST_VERSION" ]; then
    echo "just $JUST_VERSION already installed"
    exit 0
  fi
  echo "Upgrading just from $current to $JUST_VERSION"
fi

case "$(get_arch)" in
  amd64) ARCH="x86_64-unknown-linux-musl" ;;
  arm64) ARCH="aarch64-unknown-linux-musl" ;;
esac

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

curl -fsSL "https://github.com/casey/just/releases/download/${JUST_VERSION}/just-${JUST_VERSION}-${ARCH}.tar.gz" \
  -o "$TMP/just.tar.gz"
tar -xzf "$TMP/just.tar.gz" -C "$TMP"
sudo install -m 755 "$TMP/just" /usr/local/bin/just

echo "just $JUST_VERSION installed"
