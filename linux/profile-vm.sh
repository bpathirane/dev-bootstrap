# Shared VM profile definition — sourced by install-vm.sh and validate-vm.sh.
# Format: "formula:cmd"  (brew installs formula; validator checks cmd)

VM_BREW_TOOLS=(
  "neovim:nvim"
  "tmux:tmux"
  "lazygit:lazygit"
  "yazi:ya"
  "fzf:fzf"
  "fd:fd"
  "ripgrep:rg"
  "gh:gh"
  "azure-cli:az"
  "awscli:aws"
  "kubectl:kubectl"
  "helm:helm"
  "k9s:k9s"
  "zoxide:zoxide"
  "starship:starship"
  "just:just"
  "uv:uv"
  "tldr:tldr"
  "sops:sops"
  "fnm:fnm"
  "node:node"
)

# Commands that must be present regardless of how they were installed
VM_BASE_CMDS=(git curl wget jq)
