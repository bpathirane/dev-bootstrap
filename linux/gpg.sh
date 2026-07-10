#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

# gnupg is in BASE_PACKAGES — already available by the time this runs.

# Resolve the email for the GPG UID. Preference order:
#   1. git global user.email (set by chezmoi dotfiles, which runs before this)
#   2. GITHUB_USER env var → GitHub no-reply format
#   3. prompt if interactive
GPG_NAME="$(git config --global user.name 2>/dev/null || echo "")"
GPG_EMAIL="$(git config --global user.email 2>/dev/null || echo "")"

if [ -z "$GPG_EMAIL" ] && [ -n "${GITHUB_USER:-}" ]; then
  GPG_EMAIL="${GITHUB_USER}@users.noreply.github.com"
fi

if [ -z "$GPG_EMAIL" ]; then
  if [ -t 0 ]; then
    read -rp "Enter email for GPG key: " GPG_EMAIL
  else
    echo "ERROR: cannot determine GPG email — set GITHUB_USER or git config user.email" >&2
    exit 1
  fi
fi

if [ -z "$GPG_NAME" ]; then
  GPG_NAME="$(git config --global user.name 2>/dev/null || echo "$USER")"
fi

# Check if a signing key is already configured and the key still exists
EXISTING_KEY="$(git config --global user.signingkey 2>/dev/null || echo "")"
if [ -n "$EXISTING_KEY" ] && gpg --list-secret-keys "$EXISTING_KEY" >/dev/null 2>&1; then
  echo "GPG signing already configured (key: $EXISTING_KEY)"
  exit 0
fi

# Check if any key exists for this email already
EXISTING_FP="$(gpg --list-secret-keys --with-colons 2>/dev/null \
  | awk -F: -v email="$GPG_EMAIL" '
      /^uid/ && $10 ~ email { found=1 }
      /^fpr/ && found       { print $10; found=0; exit }
    ')"

if [ -n "$EXISTING_FP" ]; then
  KEY_ID="${EXISTING_FP: -16}"
  echo "Found existing GPG key for $GPG_EMAIL: $KEY_ID"
else
  echo "Generating GPG key for $GPG_NAME <$GPG_EMAIL>..."
  gpg --batch --gen-key <<EOF
%no-protection
Key-Type: EdDSA
Key-Curve: ed25519
Subkey-Type: ECDH
Subkey-Curve: cv25519
Name-Real: ${GPG_NAME}
Name-Email: ${GPG_EMAIL}
Expire-Date: 0
%commit
EOF
  KEY_ID="$(gpg --list-secret-keys --keyid-format=long "$GPG_EMAIL" 2>/dev/null \
    | awk '/^sec/ { split($2, a, "/"); print a[2] }')"
  echo "GPG key generated: $KEY_ID"
fi

# Register the key globally so it's available when signing is active.
git config --global user.signingkey "$KEY_ID"

# Enable signing only for personal GitHub repos via gitdir conditional include —
# same concept as ~/.ssh/config per-host blocks.
PERSONAL_DIR="$HOME/source/github_personal"
PERSONAL_GITCONFIG="$HOME/.gitconfig-personal"

if [ ! -f "$PERSONAL_GITCONFIG" ]; then
  cat > "$PERSONAL_GITCONFIG" <<'GITCFG'
[commit]
    gpgsign = true
[tag]
    gpgsign = true
GITCFG
  echo "Created $PERSONAL_GITCONFIG"
fi

# Add the includeIf block to global gitconfig if not already present
if ! git config --global --get-all includeIf 2>/dev/null | grep -q "github_personal"; then
  git config --global "includeIf.gitdir:${PERSONAL_DIR}/.path" "$PERSONAL_GITCONFIG"
  echo "Registered gitdir conditional include for $PERSONAL_DIR"
fi

echo ""
echo "========================================"
echo "Add this GPG public key to GitHub:"
echo "  https://github.com/settings/gpg/new"
echo ""
gpg --armor --export "$KEY_ID"
echo "========================================"
echo ""
if [ -t 0 ]; then
  read -rp "Press ENTER after adding the key to GitHub..."
fi
