You are modifying `dev-bootstrap` to support a long-lived Ubuntu VM developer workstation on macOS/UTM, while preserving WSL support.

Goal:
Refactor the project so Ubuntu VM setup is first-class, repeatable, and does not install WSL/Windows-specific tooling unless running inside WSL.

Requirements:

1. Add explicit profiles:

   * `linux/install-vm.sh` for normal Ubuntu VM / server installs.
   * `linux/install-wsl.sh` for WSL-specific extras.
   * `linux/install-desktop.sh` for Linux desktop GUI extras.
   * Keep existing `bootstrap.sh`, but route Linux users into the correct profile based on environment detection.

2. Fix WSL-only package bug:

   * `wslu` must not be installed in a normal Ubuntu VM.
   * Install `wslu`, `wslview`, `/mnt/c` checks, Windows clipboard tools, and `win32yank` only under WSL.
   * Ensure `wsl-config.sh` is never called outside WSL.

3. Make Ubuntu VM profile headless/server-friendly:
   Install core packages and CLI tools for:

   * git, curl, wget, ca-certificates, build-essential, unzip, jq, yq, ripgrep, fd, fzf, bat, direnv, zoxide, starship, tmux, neovim, lazygit, yazi, tldr, just
   * dotnet SDK
   * Python tooling: uv, ruff
   * Node/Bun tooling
   * AWS CLI, Azure CLI, GitHub CLI
   * Kubernetes tooling: kubectl, helm, kind, k9s, kubectx/kubens
   * sops, age, gnupg
   * optional zellij

4. Introduce Linuxbrew/Homebrew-on-Linux support:

   * Add `linux/install-brew.sh`.
   * Install Homebrew under `/home/linuxbrew/.linuxbrew` when missing.
   * Add brew shellenv initialization safely.
   * Prefer brew for fast-moving developer tools where appropriate: neovim, tmux, lazygit, yazi, fzf, fd, ripgrep, gh, kubectl, helm, k9s, zoxide, starship, just, uv if available.
   * Keep apt for base OS/system packages only.
   * Make this idempotent.

5. Make sensitive or identity-mutating steps opt-in:
   These should not run in default VM setup:

   * SSH key generation
   * GPG key generation/signing setup
   * chezmoi dotfiles apply
   * Claude Code / AI tools
     Add flags or separate scripts for these, such as:
   * `linux/install-identity.sh`
   * `linux/install-dotfiles.sh`
   * `linux/install-ai.sh`

6. Add corporate certificate helper:

   * Add `linux/install-ca-cert.sh <path-to-cert.crt>`.
   * Copy cert to `/usr/local/share/ca-certificates/`.
   * Convert DER to PEM if needed.
   * Run `sudo update-ca-certificates`.
   * Print validation guidance for curl/openssl.

7. Add VM validation script:

   * Create `linux/validate-vm.sh`.
   * Check presence and versions for all VM tools.
   * Do not check WSL-only items.
   * Return non-zero if required tools are missing.
   * Show optional tools separately.

8. Keep WSL validation separate:

   * Rename or split existing validation into `validate-wsl.sh` if needed.
   * WSL checks may include `wslview`, `/mnt/c`, Windows clipboard integration, and win32yank.

9. Improve idempotency:

   * Every install script should be safe to run multiple times.
   * Use helper functions like `command_exists`, `apt_install_if_missing`, `brew_install_if_missing`.
   * Do not reinstall tools unnecessarily.
   * Avoid appending duplicate lines to shell startup files.

10. Improve `bootstrap.sh` behavior:

* Detect:

  * macOS/Darwin
  * Linux VM
  * WSL
* On macOS, print guidance to use Brewfile / host setup, not Linux scripts.
* On Linux VM, run `linux/install-vm.sh`.
* On WSL, run `linux/install-wsl.sh`.
* Provide `--profile vm|wsl|desktop|minimal` override.

11. Add docs:

* `docs/ubuntu-vm.md`
  Include:
* UTM Ubuntu Server ARM64 setup assumptions.
* SSH-first workflow.
* Why WSL-specific tools are skipped.
* Optional Avahi setup for `devbox.local`.
* Corporate CA install example.
* Recommended order:

  1. base VM
  2. brew/dev tools
  3. validate
  4. dotfiles
  5. identity
  6. AI tools

12. Do not break existing WSL behavior.

* Existing WSL users should still get WSL conveniences.
* Normal Ubuntu VM users should not hit missing `wslu` errors.

Deliverables:

* Updated scripts.
* New validation script.
* New docs.
* Clear summary of changed files.
* Commands to test:

  * `./bootstrap.sh --profile vm`
  * `./linux/validate-vm.sh`
  * `./bootstrap.sh --profile wsl`
  * `./linux/validate-wsl.sh`

13. Add a `thin-client` profile.

Purpose:
Set up a host machine, such as macOS, whose main job is to connect to a Linux VM or remote server rather than host the full development toolchain locally.

Add:

* `macos/install-thin-client.sh`
* `macos/Brewfile.thin-client`
* optionally `linux/install-thin-client.sh` for lightweight Linux laptops/desktops

The thin-client profile should install only host-side tools:

* Homebrew, if missing or documented as prerequisite
* WezTerm
* VS Code
* chezmoi
* git
* gh
* openssh/client utilities
* tmux only if useful locally
* jq
* yq
* curl
* wget
* Nerd Font used by terminal
* browser/auth helper utilities if applicable

It should not install:

* Docker
* local Kubernetes tools unless explicitly requested
* .NET SDK
* Python runtimes beyond system/default needs
* Node/Bun
* databases
* heavy compiler/build toolchains
* cloud CLIs unless explicitly enabled
* AI tools by default

Add profile routing:

* `./bootstrap.sh --profile thin-client`
* On macOS, this should use `macos/install-thin-client.sh`.
* On Linux, this should use `linux/install-thin-client.sh` if implemented.
* On WSL, thin-client should normally be rejected or documented as unnecessary.

Add docs:

* `docs/thin-client.md`

Document the intended architecture:

```text
Host thin client:
  WezTerm
  VS Code
  browser
  SSH config
  chezmoi-managed terminal config

Remote/VM devbox:
  tmux
  neovim
  source repos
  Docker
  Kubernetes
  language runtimes
  cloud CLIs
```

Add SSH config guidance:

* Example `~/.ssh/config` entries for `devbox`, `homelab`, and remote servers.
* Recommend `ServerAliveInterval 30`.
* Recommend connecting to VM by hostname where possible, e.g. `devbox.local`.

Add validation:

* `macos/validate-thin-client.sh`
* Check `brew`, `wezterm`, `code`, `chezmoi`, `git`, `gh`, `ssh`, font availability if practical.
* Do not validate developer runtimes in thin-client mode.

Update README:

* Explain profiles:

  * `vm`: full Ubuntu VM developer workstation
  * `wsl`: Windows WSL developer workstation
  * `desktop`: Linux GUI workstation
  * `thin-client`: host machine used mostly to SSH into a devbox
  * `minimal`: minimum dependencies only
