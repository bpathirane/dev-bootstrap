macOS Full profile
===================

The full profile installs a complete native developer environment directly on macOS —
for machines doing actual development locally rather than through a remote devbox VM
(see the thin-client profile for that case).

Installs via Homebrew:
- Shell & navigation: tmux, zoxide, starship
- File & search: bat, fd, ripgrep, fzf, jq
- Terminal utilities: tldr, yazi, just
- Dev tools: gh, lazygit, neovim (+ LazyVim config, tree-sitter CLI), node
- Python & node tooling: uv, bun
- Secrets & process management: age, gnupg, sops, lefthook, zellij, direnv, htop
- Cloud: azure-cli, awscli, kubectl, helm, k9s, kubectx, kind
- Dotfiles: chezmoi
- MSSQL: sqlcmd (go-sqlcmd)
- Casks: OrbStack, PowerShell, .NET SDK, WezTerm, Google Chrome

Also configures: SSH keys/config for GitHub + Azure DevOps, Claude Code CLI, and
applies chezmoi dotfiles (prompts for `GITHUB_USER` if not already set).

Deliberately excludes Kerberos (`krb5`) — install it manually if a given machine
needs `INTERNAL.DEFHC.COM` auth; it's not part of the default macOS tool list.

Usage:
- `./bootstrap.sh install --profile full` (also the default when no `--profile` is given)
- `./bootstrap.sh validate --profile full`
