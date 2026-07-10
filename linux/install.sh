#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if is_wsl; then
  exec "$SCRIPT_DIR/install-wsl.sh"
else
  exec "$SCRIPT_DIR/install-vm.sh"
fi

# Tool installs
"$SCRIPT_DIR/azure-cli.sh"
"$SCRIPT_DIR/mssql-tools.sh"
"$SCRIPT_DIR/aws.sh"
"$SCRIPT_DIR/k8s.sh"
"$SCRIPT_DIR/github.sh"
"$SCRIPT_DIR/ssh.sh"
"$SCRIPT_DIR/win32yank.sh"
"$SCRIPT_DIR/fzf.sh"
"$SCRIPT_DIR/lazygit.sh"
"$SCRIPT_DIR/yazi.sh"
"$SCRIPT_DIR/tldr.sh"
"$SCRIPT_DIR/zoxide.sh"
"$SCRIPT_DIR/lazyvim.sh"
"$SCRIPT_DIR/bun.sh"
"$SCRIPT_DIR/claude.sh"
"$SCRIPT_DIR/powershell.sh"
"$SCRIPT_DIR/dotnet.sh"
"$SCRIPT_DIR/sops.sh"
"$SCRIPT_DIR/lefthook.sh"
"$SCRIPT_DIR/zellij.sh"
"$SCRIPT_DIR/chezmoi.sh"
"$SCRIPT_DIR/chromium.sh"

echo "Bootstrap complete."
