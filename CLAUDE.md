# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Does

Provisions a full developer environment on WSL2 (Windows), Ubuntu VMs, and bare metal Linux. A single entry point detects the platform and runs the appropriate bootstrap. macOS support is stubbed and not yet implemented.

## Entry Points

- **`bootstrap.sh`** — Universal Linux entry point. Detects OS, clones the repo if absent, then delegates to `linux/install.sh`. One-liner for a fresh machine: `curl -fsSL https://raw.githubusercontent.com/bpathirane/dev-bootstrap/main/bootstrap.sh | bash`
- **`setup-wsl.ps1`** — Windows/WSL entry point. Accepts params: `-DistroName`, `-VhdPath`, `-VhdSizeGB`, `-DisableWindowsPath`, `-DisableAutoMount`, `-Rebuild`, `-GitHubUsername`, `-BootstrapRepoName`. Clones this repo inside the new WSL instance and calls `linux/install.sh`.
- **`linux/install.sh`** — Linux orchestrator. Detects WSL vs plain Linux and runs WSL-only steps conditionally. Sequence: `wsl-config.sh` (WSL only) → `install-packages.sh` → starship/zsh → `azure-cli.sh` → `aws.sh` → `k8s.sh` → `github.sh` → `ssh.sh` → clipboard (`win32yank.sh` on WSL, `clipboard.sh` elsewhere) → `fzf.sh` → `lazygit.sh` → `yazi.sh` → `tldr.sh` → `zoxide.sh` → `lazyvim.sh` → `bun.sh` → `claude.sh` → `powershell.sh` → `dotnet.sh` → `sops.sh` → `lefthook.sh` → `zellij.sh` → `chezmoi.sh` → `chromium.sh` → `wezterm.sh` (non-WSL only).
- **`linux/install-packages.sh`** — Apt package installs only. Called by `install.sh` and can be run standalone by `/dev-install` for adding individual packages.
- **`manage-vhd.ps1`** — Standalone VHD management utility. Actions: `Info`, `Compact`, `Resize`, `Move`.

## Linux Script Architecture

All `linux/` scripts source `lib.sh` for shared helpers:
- `command_exists <cmd>` — checks if a binary is on PATH
- `is_wsl` — returns true when running inside WSL
- `get_arch` — returns `amd64` or `arm64` based on `uname -m` (replaces `dpkg --print-architecture`)
- `apt_install_if_missing <pkg>` — skips install if already installed (idempotency)
- `ensure_directory <path>` — mkdir -p wrapper

Each tool script uses `command_exists` guards to make all installs idempotent — safe to rerun without re-installing.

## Platform-Conditional Scripts

- `wsl-config.sh` — WSL only (sets `/etc/wsl.conf`)
- `win32yank.sh` — WSL only (Windows clipboard bridge for Neovim)
- `clipboard.sh` — Non-WSL Linux only (installs `xclip` + `wl-clipboard` for Neovim)
- `wezterm.sh` — Non-WSL Linux only (WezTerm runs on the Windows/macOS host; skipped inside WSL)

## Environment Variables (PowerShell → Linux)

`setup-wsl.ps1` passes configuration to `install.sh` via env vars:
- `DISABLE_WINDOWS_PATH` — read by `wsl-config.sh` to set `appendWindowsPath` in `/etc/wsl.conf`
- `DISABLE_AUTO_MOUNT` — read by `wsl-config.sh` to set automount in `/etc/wsl.conf`
- `GITHUB_USER` — read by `chezmoi.sh` to init dotfiles from `git@github.com:<user>/dotfiles.git`

## Default WSL Behavior

- Instance name: `Ubuntu-Dev`
- Base distro: `Ubuntu-24.04`
- VHD location: `%LOCALAPPDATA%\WSL\<DistroName>`
- VHD max size: 256 GB
- Windows PATH injection: **disabled** (isolated environment)
- Windows drive auto-mount: **disabled**
- systemd: enabled in `/etc/wsl.conf`

## Running the Scripts

```bash
# Fresh Ubuntu box (one-liner)
curl -fsSL https://raw.githubusercontent.com/bpathirane/dev-bootstrap/main/bootstrap.sh | bash

# Re-run bootstrap manually (all scripts are idempotent)
cd ~/source/github_personal/dev-bootstrap/linux && chmod +x *.sh && ./install.sh
```

```powershell
# Basic WSL setup (from PowerShell as Administrator)
powershell -ExecutionPolicy Bypass -File setup-wsl.ps1

# Custom instance on D: drive
powershell -ExecutionPolicy Bypass -File setup-wsl.ps1 -DistroName "Dev" -BaseDistro "Ubuntu-24.04" -VhdPath "D:\WSL\Dev" -VhdSizeGB 512

# Rebuild (destroys all data in instance)
powershell -ExecutionPolicy Bypass -File setup-wsl.ps1 -DistroName "Ubuntu-Dev" -Rebuild

# VHD management
.\manage-vhd.ps1 -DistroName "Ubuntu-Dev" -Action Compact
.\manage-vhd.ps1 -DistroName "Ubuntu-Dev" -Action Resize -NewSizeGB 512
.\manage-vhd.ps1 -DistroName "Ubuntu-Dev" -Action Move -NewPath "D:\WSL\Ubuntu-Dev"
```

## Custom WSL Instance Creation

`setup-wsl.ps1` queries `wsl --list --online` at runtime to discover directly installable distros. If `$DistroName` matches a known online distro, it installs it with `wsl --install -d` directly. Otherwise it treats the name as a custom instance: it installs `$BaseDistro` if not already present locally, exports it as a `.tar`, then imports it under `$DistroName`. This is the mechanism that enables multiple named instances from any available base distro.
