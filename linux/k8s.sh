#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

K9S_VERSION="0.32.7"
KIND_VERSION="0.27.0"
HELM_VERSION="3.17.3"

ARCH="$(get_arch)"

if ! command_exists kubectl; then
  KUBECTL_VERSION="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
  curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl" -o /tmp/kubectl
  chmod +x /tmp/kubectl
  sudo mv /tmp/kubectl /usr/local/bin/kubectl
fi

if [ ! -d "/opt/kubectx" ]; then
  sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
  sudo ln -sf /opt/kubectx/kubectx /usr/local/bin/kctx
  sudo ln -sf /opt/kubectx/kubens /usr/local/bin/kns
fi

if ! command_exists k9s; then
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  case "$ARCH" in
    amd64) K9S_ARCH="amd64" ;;
    arm64) K9S_ARCH="arm64" ;;
  esac
  curl -fsSL "https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_Linux_${K9S_ARCH}.tar.gz" -o "$TMP/k9s.tar.gz"
  tar -xzf "$TMP/k9s.tar.gz" -C "$TMP"
  sudo install -m 755 "$TMP/k9s" /usr/local/bin/k9s
fi

if ! command_exists helm; then
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  curl -fsSL "https://get.helm.sh/helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz" -o "$TMP/helm.tar.gz"
  tar -xzf "$TMP/helm.tar.gz" -C "$TMP"
  sudo install -m 755 "$TMP/linux-${ARCH}/helm" /usr/local/bin/helm
fi

if ! command_exists kind; then
  curl -fsSL "https://kind.sigs.k8s.io/dl/v${KIND_VERSION}/kind-linux-${ARCH}" -o /tmp/kind
  sudo install -m 755 /tmp/kind /usr/local/bin/kind
  rm /tmp/kind
fi
