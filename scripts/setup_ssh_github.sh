#!/usr/bin/env bash
set -euo pipefail

# Generate an SSH key (ed25519), optionally upload to GitHub via gh,
# and switch this repo's origin to SSH.

EMAIL_DEFAULT="sloan@wombleco.com"
KEY_PATH_DEFAULT="$HOME/.ssh/id_ed25519"
LABEL_DEFAULT="$(hostname)-$(date +%Y%m%d)"

EMAIL="$EMAIL_DEFAULT"
KEY_PATH="$KEY_PATH_DEFAULT"
LABEL="$LABEL_DEFAULT"

usage() {
  cat <<USAGE
Usage: $0 [--email EMAIL] [--key-path PATH] [--label TITLE]

Examples:
  $0                          # use defaults, generate/upload, set remote
  $0 --email you@example.com  # override email for key comment
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0;;
    --email) EMAIL="$2"; shift 2;;
    --key-path) KEY_PATH="$2"; shift 2;;
    --label) LABEL="$2"; shift 2;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1;;
  esac
done

mkdir -p "$(dirname "$KEY_PATH")"
if [ ! -f "$KEY_PATH" ]; then
  echo "[ssh] Generating key: $KEY_PATH (ed25519)"
  ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY_PATH" -N ""
else
  echo "[ssh] Key exists: $KEY_PATH (skipping generation)"
fi

# Ensure ssh-agent and add key
if [ -z "${SSH_AUTH_SOCK:-}" ]; then
  eval "$(ssh-agent -s)" >/dev/null
fi
ssh-add "$KEY_PATH" 2>/dev/null || true

PUB_KEY_FILE="$KEY_PATH.pub"
if [ ! -f "$PUB_KEY_FILE" ]; then
  echo "Public key not found: $PUB_KEY_FILE" >&2
  exit 1
fi

# Upload key to GitHub using gh if available
if command -v gh >/dev/null 2>&1; then
  echo "[gh] Uploading SSH key to GitHub with title '$LABEL'"
  gh ssh-key add "$PUB_KEY_FILE" --title "$LABEL" || {
    echo "[gh] Failed to upload key automatically. You may need to add it manually." >&2
  }
else
  echo "[info] gh not found. Add this key to GitHub (Settings → SSH keys):"
  echo
  cat "$PUB_KEY_FILE"
  echo
fi

# Test SSH connection (accept new host key automatically once)
echo "[ssh] Testing GitHub SSH connectivity…"
ssh -T -o StrictHostKeyChecking=accept-new git@github.com || true

# Switch this repo's origin to SSH if we're inside the dotfiles repo
REPO_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
if [ -d "$REPO_DIR/.git" ]; then
  cd "$REPO_DIR"
  if git remote | grep -qx origin; then
    echo "[git] Setting origin to SSH"
    git remote set-url origin "git@github.com:11w5/dotfiles.git"
  else
    git remote add origin "git@github.com:11w5/dotfiles.git"
  fi
  echo "[git] Remote now: $(git remote get-url origin)"
fi

echo "[done] SSH key ready. Pushes via SSH are now enabled."

