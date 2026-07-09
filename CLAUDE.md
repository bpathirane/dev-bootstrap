# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Does

Provisions a full developer environment on Ubuntu VMs, WSL2 (Windows), Linux desktops, macOS thin clients, and bare metal Linux. A single entry point detects the platform and routes to the appropriate profile installer.

## Profiles

- `vm` — Full Ubuntu VM / bare metal developer workstation (headless)
- `wsl` — Developer workstation inside WSL2
- `desktop` — Linux GUI workstation
- `thin-client` — Minimal host-side tools for connecting to a remote devbox (macOS or Linux)
- `minimal` — Base apt packages and shell only

## Entry Points

- **`bootstrap.sh`** — Universal entry point. Detects OS, clones the repo if absent, then routes to the profile installer. Pass `--profile <name>` to select a profile; without it, auto-detects WSL vs plain Linux. One-liner: `curl -fsSL https://raw.githubusercontent.com/bpathirane/dev-bootstrap/main/bootstrap.sh | bash --profile vm`
- **`setup-wsl.ps1`** — Windows/WSL entry point. Creates a WSL instance and runs the `wsl` profile inside it. Params: `-DistroName`, `-VhdPath`, `-VhdSizeGB`, `-DisableWindowsPath`, `-DisableAutoMount`, `-Rebuild`, `-GitHubUsername`.
- **`linux/install.sh`** — Thin redirector: detects WSL vs plain Linux and execs `install-wsl.sh` or `install-vm.sh`.
- **`linux/install-vm.sh`** — VM profile orchestrator. Installs Homebrew, then dev tools via brew (neovim, lazygit, yazi, fzf, gh, kubectl, k9s, starship, uv, etc.), then runs optional runtime scripts: `aws.sh`, `azure-cli.sh`, `k8s.sh`, `sops.sh`, `uv.sh`, `bun.sh`, `dotnet.sh`.
- **`linux/install-wsl.sh`** — WSL profile orchestrator. Runs `wsl-config.sh`, `install-packages.sh`, `win32yank.sh`, then the same runtime scripts as vm.
- **`linux/install-thin-client.sh`** — Linux thin-client profile. Installs git, curl, gh, chezmoi via apt.
- **`linux/install-desktop.sh`** — Desktop profile (GUI workstation).
- **`linux/install-minimal.sh`** — Minimal profile. Base packages and shell only.
- **`linux/install-packages.sh`** — Apt package installs. Called by WSL installer; can be run standalone via `/dev-install`.
- **`macos/install-thin-client.sh`** — macOS thin-client profile. Installs Homebrew, then packages from `macos/Brewfile.thin-client`.
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
- `macos/install-thin-client.sh` — macOS only; uses Homebrew and `macos/Brewfile.thin-client`
- `macos/validate-thin-client.sh` — macOS thin-client validation

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
# Fresh machine (one-liner, auto-detects platform)
curl -fsSL https://raw.githubusercontent.com/bpathirane/dev-bootstrap/main/bootstrap.sh | bash --profile vm

# Re-run bootstrap manually (all scripts are idempotent)
cd ~/source/github_personal/dev-bootstrap
./bootstrap.sh --profile vm        # or wsl, desktop, minimal, thin-client

# Validate after install
./linux/validate.sh --profile vm
```

```powershell
# Basic WSL setup (from PowerShell as Administrator)
powershell -ExecutionPolicy Bypass -File setup-wsl.ps1

# Custom instance on D: drive
powershell -ExecutionPolicy Bypass -File setup-wsl.ps1 -DistroName "Dev" -VhdPath "D:\WSL\Dev" -VhdSizeGB 512

# Rebuild (destroys all data in instance)
powershell -ExecutionPolicy Bypass -File setup-wsl.ps1 -DistroName "Ubuntu-Dev" -Rebuild

# VHD management
.\manage-vhd.ps1 -DistroName "Ubuntu-Dev" -Action Compact
.\manage-vhd.ps1 -DistroName "Ubuntu-Dev" -Action Resize -NewSizeGB 512
.\manage-vhd.ps1 -DistroName "Ubuntu-Dev" -Action Move -NewPath "D:\WSL\Ubuntu-Dev"
```

## Custom WSL Instance Creation

`setup-wsl.ps1` queries `wsl --list --online` at runtime to discover directly installable distros. If `$DistroName` matches a known online distro, it installs it with `wsl --install -d` directly. Otherwise it treats the name as a custom instance: it installs `$BaseDistro` if not already present locally, exports it as a `.tar`, then imports it under `$DistroName`. This is the mechanism that enables multiple named instances from any available base distro.
