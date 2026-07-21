# Shared WSL profile definition — sourced by install-wsl.sh and validate-wsl.sh.

# Commands installed via apt / cloud CLI scripts that must be present after install
WSL_REQUIRED_CMDS=(
  # apt base packages
  git curl jq rg fd bat zsh
  # cloud CLIs
  az aws
  # WSL-specific helpers
  wslview win32yank wslu
)
