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
curl -fsSL https://raw.githubusercontent.com/bpathirane/dev-bootstrap/main/bootstrap.sh | bash --profile vm
```

Or clone and run directly:

```bash
git clone https://github.com/bpathirane/dev-bootstrap.git ~/source/github_personal/dev-bootstrap
cd ~/source/github_personal/dev-bootstrap
./bootstrap.sh --profile vm       # Ubuntu VM
./bootstrap.sh --profile wsl      # WSL instance
./bootstrap.sh --profile desktop  # Linux desktop
./bootstrap.sh --profile minimal  # Minimal base only
```

Without `--profile`, the script auto-detects WSL vs plain Linux and picks `wsl` or `vm` accordingly.

### macOS (thin client)

```bash
./bootstrap.sh --profile thin-client
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
./linux/validate.sh --profile vm
./linux/validate.sh --profile wsl
./linux/validate.sh --profile thin-client
```

## Post-Install

```bash
# Apply dotfiles
./linux/install-dotfiles.sh

# Set up SSH/GPG identity
./linux/install-identity.sh

# Add a corporate CA certificate
./linux/install-ca-cert.sh path/to/cert.crt
```

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
