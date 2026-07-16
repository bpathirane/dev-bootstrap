# dev-bootstrap

Reproducible developer environment bootstrap for Ubuntu VMs, WSL, Linux desktops, and thin clients.

## Profiles

| Profile | Platform | Description |
|---|---|---|
| `vm` | Ubuntu VM / bare metal | Full developer workstation (headless) |
| `wsl` | Windows WSL2 | Developer workstation inside WSL |
| `desktop` | Linux GUI | Full workstation with desktop apps |
| `thin-client` | macOS / Linux | Minimal host tools for remote devbox access |
| `minimal` | Any Linux | Base dependencies only |

## Quick Start

### Linux / WSL

```bash
curl -fsSL https://raw.githubusercontent.com/bpathirane/dev-bootstrap/main/bootstrap.sh | bash -s -- install --profile vm
```

After the first run, `bootstrap` is registered as a global command (`~/.local/bin/bootstrap`). Subsequent runs from anywhere:

```bash
bootstrap install --profile vm
bootstrap validate --profile vm
bootstrap pull          # fetch latest from GitHub
bootstrap status        # show installed profile, version, extras, and last run
```

Or clone and run directly:

```bash
git clone https://github.com/bpathirane/dev-bootstrap.git ~/source/github_personal/dev-bootstrap
cd ~/source/github_personal/dev-bootstrap
./bootstrap.sh install --profile vm       # Ubuntu VM
./bootstrap.sh install --profile wsl      # WSL instance
./bootstrap.sh install --profile desktop  # Linux desktop
./bootstrap.sh install --profile minimal  # Minimal base only
```

Without `--profile`, the script auto-detects WSL vs plain Linux and picks `wsl` or `vm` accordingly. The `install` subcommand is the default and can be omitted.

### macOS (thin client)

```bash
./bootstrap.sh install --profile thin-client
```

Installs WezTerm, VS Code, chezmoi, git, gh, and SSH — lightweight host tools for connecting to a remote devbox. Does not install runtimes, Docker, or Kubernetes.

### Windows (new WSL instance)

```powershell
$url = "https://raw.githubusercontent.com/bpathirane/dev-bootstrap/main/setup-wsl.ps1"
Invoke-WebRequest $url -OutFile "$env:TEMP\setup-wsl.ps1"
powershell -ExecutionPolicy Bypass -File "$env:TEMP\setup-wsl.ps1"
```

Creates a WSL instance named `Ubuntu-Dev` and runs the `wsl` profile inside it. See [WSL setup](#wsl-setup-windows) for options.

## What Gets Installed

All Linux profiles share a common base (zsh, starship, fzf, lazygit, yazi, zoxide, LazyVim, GitHub CLI, SSH, chezmoi). Profile-specific additions:

- **vm / wsl / desktop**: AWS CLI, Azure CLI, kubectl/k9s, .NET SDK, Bun, uv, Claude CLI, Zellij, WezTerm (desktop/WSL only)
- **thin-client**: Homebrew, WezTerm, VS Code, chezmoi, git, gh, ssh
- **minimal**: Core apt packages and shell only

All scripts are idempotent — safe to rerun.

## Validation

After setup, verify the installation:

```bash
bootstrap validate --profile vm
bootstrap validate --profile wsl
bootstrap validate --profile thin-client
```

## Post-Install

After `bootstrap install`, run extras individually:

```bash
bootstrap extras dotfiles   # apply chezmoi dotfiles
bootstrap extras identity   # SSH/GPG keys
bootstrap extras nts        # chrony + NTS time sync
bootstrap extras ai         # Claude CLI and AI tools
bootstrap extras mtu-fix    # clamp default route MTU (fixes Path MTU black holes, e.g. Multipass/UTM VMs)
bootstrap extras --list     # show all available extras
```

Or directly via the scripts:
```bash
./linux/install-ca-cert.sh path/to/cert.crt   # add a corporate CA certificate
```

## State

Bootstrap tracks installed profile, version, and extras in `~/.bootstrap/settings.json`:

```json
{
  "profile": "vm",
  "version": "0.1.0",
  "installedAt": "2026-07-10T12:00:00Z",
  "extras": [
    { "name": "dotfiles", "version": "0.1.0", "installedAt": "2026-07-10T12:10:00Z" }
  ],
  "runs": [
    { "at": "2026-07-10T12:00:00Z", "command": "install-vm", "version": "0.1.0", "exitCode": 0, "log": "~/.bootstrap/logs/2026-07-10T120000Z-install-vm.log" }
  ]
}
```

Logs for every run are stored in `~/.bootstrap/logs/`.

## Profile Docs

- [Ubuntu VM](docs/ubuntu-vm.md)
- [Thin Client](docs/thin-client.md)

---

## WSL Setup (Windows)

### Custom instance

```powershell
powershell -ExecutionPolicy Bypass -File setup-wsl.ps1 `
  -DistroName "Dev" `
  -VhdPath "D:\WSL\Dev" `
  -VhdSizeGB 512
```

Parameters:

| Parameter | Default | Description |
|---|---|---|
| `-DistroName` | `Ubuntu-Dev` | WSL instance name |
| `-VhdPath` | `%LOCALAPPDATA%\WSL\<name>` | VHD file location |
| `-VhdSizeGB` | `256` | Maximum VHD size |
| `-DisableWindowsPath` | `$true` | Exclude Windows PATH from WSL |
| `-DisableAutoMount` | `$true` | Don't auto-mount Windows drives |
| `-Rebuild` | — | Destroy and recreate the instance |
| `-GitHubUsername` | — | Used for chezmoi dotfiles init |

### VHD management

```powershell
.\manage-vhd.ps1 -DistroName "Ubuntu-Dev" -Action Info     # disk usage
.\manage-vhd.ps1 -DistroName "Ubuntu-Dev" -Action Compact  # reclaim space
.\manage-vhd.ps1 -DistroName "Ubuntu-Dev" -Action Resize -NewSizeGB 512
.\manage-vhd.ps1 -DistroName "Ubuntu-Dev" -Action Move -NewPath "D:\WSL\Ubuntu-Dev"
```

### Common WSL commands

```powershell
wsl --list --verbose        # list instances
wsl -d Ubuntu-Dev           # open instance
wsl --shutdown              # stop all instances
wsl --set-default Ubuntu-Dev
wsl --update
```
