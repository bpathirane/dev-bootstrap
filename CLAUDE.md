# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Does

Provisions a full developer environment on Ubuntu VMs, WSL2, Linux desktops, macOS thin clients, and bare metal Linux. A single entry point detects the platform and routes to the appropriate profile installer.

## Running and Testing

All scripts are idempotent — safe to rerun. There are no automated tests; validation is done by running the validate scripts on a real machine.

```bash
# Run a profile install
bootstrap install --profile vm
bootstrap install --profile wsl

# Validate an installed profile
bootstrap validate --profile vm
bootstrap validate --profile wsl

# Install extras
bootstrap extras dotfiles
bootstrap extras nts
bootstrap extras --list

# Check installed state vs repo
bootstrap status
bootstrap pull
```

The `bootstrap` command is a symlink to `bootstrap.sh` registered at `~/.local/bin/bootstrap` on first run. During development, invoke directly:

```bash
./bootstrap.sh install --profile vm
```

To test a single tool script in isolation:

```bash
./linux/sops.sh
./linux/nts.sh
NTS_SERVER=time.cloudflare.com ./linux/nts.sh
```

The verbose validate script (`linux/validate.sh`) has `--fix` and `--interactive` modes:

```bash
./linux/validate.sh --fix
./linux/validate.sh --interactive
```

## Architecture

### Entry point and dispatch

`bootstrap.sh` is the only script users need to know. It:
1. Ensures git is present, then clones/pulls the repo to `~/source/github_personal/dev-bootstrap`
2. Self-registers as `~/.local/bin/bootstrap`
3. Sources `linux/lib-state.sh` for state management
4. Dispatches to `linux/install-<profile>.sh` or `linux/validate-<profile>.sh` based on subcommand and profile

### Shared libraries

- **`linux/lib.sh`** — low-level helpers sourced by all `linux/` scripts: `command_exists`, `is_wsl`, `get_arch`, `apt_install_if_missing`, `brew_install_if_missing`, `apt_update_if_stale`
- **`linux/lib-state.sh`** — state management sourced only by `bootstrap.sh`: reads version via `git describe --tags --always`, writes `~/.bootstrap/settings.json`, manages per-run log files in `~/.bootstrap/logs/`

### Profile installers

Each profile is self-contained:
- `linux/install-vm.sh` — installs base apt packages, then Homebrew, then a fixed `BREW_TOOLS` array, then optional runtime scripts (`aws.sh`, `azure-cli.sh`, `k8s.sh`, etc.)
- `linux/install-wsl.sh` — runs `wsl-config.sh`, `install-packages.sh`, `win32yank.sh`, then the same runtime scripts
- `linux/install-desktop.sh`, `install-minimal.sh`, `install-thin-client.sh` — profile variants
- `macos/install-thin-client.sh` — macOS thin-client via Homebrew + `macos/Brewfile.thin-client`

### Tool scripts

`linux/*.sh` tool scripts (e.g. `sops.sh`, `nts.sh`, `bun.sh`) are:
- Standalone — each sources `lib.sh` and runs independently
- Idempotent — guarded by `command_exists` or version checks before installing
- Called by profile installers with `|| true` so one failure doesn't abort the whole install

### Extras system

Extras are optional post-install steps registered in the `EXTRAS` associative array in `bootstrap.sh`. Adding a new extra is one line in that map. Each extra is a `linux/*.sh` script that runs via `run_with_log`, with its name and version recorded to `settings.json` on success.

### State tracking

`~/.bootstrap/settings.json` tracks:
- `profile` and `version` (git describe output) of the last successful install
- `extras[]` — each extra with its version and install timestamp
- `runs[]` — last 50 runs with command, version, exit code, and log path

Version is always `git describe --tags --always` — no manual VERSION file to bump. Tag a commit to attach a human-readable label (`git tag v1.0.0`).

### Validators

- `linux/validate-vm.sh` — checks required tools, optional tools, and time sync (chrony drift or timedatectl NTPSynchronized)
- `linux/validate.sh` — comprehensive validator with fix/interactive modes; checks tool versions, Neovim install source, Kubernetes tools, shell, WSL integration, and git/SSH authentication
- `linux/validate-wsl.sh`, `linux/validate-thin-client.sh` — profile-specific subsets

## Key Conventions

- All `linux/` scripts must `source "$(dirname "$0")/lib.sh"` at the top
- Use `brew_install_if_missing` for fast-moving dev tools; use `apt_install_if_missing` for base OS packages only
- WSL-only code must be guarded with `is_wsl`; never call `wsl-config.sh` or `win32yank.sh` outside WSL
- Platform-conditional scripts: `clipboard.sh` and `wezterm.sh` are non-WSL Linux only; `win32yank.sh` and `wsl-config.sh` are WSL only
- `GITHUB_USER` env var is read by `chezmoi.sh` to init dotfiles from `git@github.com:<user>/dotfiles.git`
