#!/usr/bin/env bash
set -euo pipefail
umask 077

# Configure GitHub SSH without creating weak local identity material.
#
# Default behavior:
# - Prefer an existing agent-backed key.
# - Upload an existing public key with gh when requested.
# - Set this repo's origin to SSH.
#
# Key generation is opt-in and prompts for a passphrase unless explicitly
# overridden. Passphrase-less keys are not allowed by this repo policy.

EMAIL_DEFAULT="$(git config --global user.email 2>/dev/null || printf 'git@localhost')"
KEY_PATH_DEFAULT="$HOME/.ssh/id_ed25519"
LABEL_DEFAULT="$(hostname)-$(date +%Y%m%d)"

EMAIL="$EMAIL_DEFAULT"
KEY_PATH="$KEY_PATH_DEFAULT"
LABEL="$LABEL_DEFAULT"
GENERATE=0
UPLOAD=0
SET_REMOTE=1

usage() {
  cat <<USAGE
Usage: $0 [--generate] [--upload] [--email EMAIL] [--key-path PATH] [--label TITLE] [--no-remote]

Examples:
  $0                          # use existing SSH agent/key, test GitHub, set remote
  $0 --upload                  # upload existing public key with gh
  $0 --generate --upload       # generate a passphrase-protected key, upload it
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0;;
    --email) EMAIL="$2"; shift 2;;
    --key-path) KEY_PATH="$2"; shift 2;;
    --label) LABEL="$2"; shift 2;;
    --generate) GENERATE=1; shift;;
    --upload) UPLOAD=1; shift;;
    --no-remote) SET_REMOTE=0; shift;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1;;
  esac
done

mkdir -p -m 700 "$(dirname "$KEY_PATH")"

if [ "$GENERATE" -eq 1 ]; then
  if [ -f "$KEY_PATH" ]; then
    echo "[ssh] Key exists: $KEY_PATH (skipping generation)"
  else
    echo "[ssh] Generating encrypted ed25519 key: $KEY_PATH"
    echo "[ssh] Enter a real passphrase when prompted. Empty passphrases are blocked."
    ssh-keygen -t ed25519 -a 64 -C "$EMAIL" -f "$KEY_PATH"
    chmod 600 "$KEY_PATH"
    chmod 644 "$KEY_PATH.pub"
  fi
fi

if [ -n "${SSH_AUTH_SOCK:-}" ] && ssh-add -l >/dev/null 2>&1; then
  echo "[ssh] Existing agent has keys loaded."
elif [ -f "$KEY_PATH" ]; then
  if [ -z "${SSH_AUTH_SOCK:-}" ]; then
    eval "$(ssh-agent -s)" >/dev/null
  fi
  echo "[ssh] Adding key to agent: $KEY_PATH"
  ssh-add "$KEY_PATH"
else
  echo "[ssh] No loaded SSH agent key and no key at $KEY_PATH." >&2
  echo "[ssh] Load a 1Password/agent-backed key, or rerun with --generate." >&2
  exit 1
fi

PUB_KEY_FILE="$KEY_PATH.pub"
if [ "$UPLOAD" -eq 1 ] && [ ! -f "$PUB_KEY_FILE" ]; then
  echo "Public key not found: $PUB_KEY_FILE" >&2
  exit 1
fi

if [ "$UPLOAD" -eq 1 ] && command -v gh >/dev/null 2>&1; then
  echo "[gh] Uploading SSH key to GitHub with title '$LABEL'"
  gh ssh-key add "$PUB_KEY_FILE" --title "$LABEL"
elif [ "$UPLOAD" -eq 1 ]; then
  echo "[gh] gh not found; cannot upload key automatically." >&2
  echo "[gh] Install/auth gh or add the public key manually." >&2
  exit 1
fi

echo "[ssh] Testing GitHub SSH connectivity"
ssh_output="$(ssh -T -o StrictHostKeyChecking=yes git@github.com 2>&1)" || ssh_rc=$?
ssh_rc="${ssh_rc:-0}"
if [ "$ssh_rc" -ne 0 ] && ! printf '%s\n' "$ssh_output" | grep -qi 'successfully authenticated'; then
  printf '%s\n' "$ssh_output" >&2
  echo "[ssh] GitHub SSH test failed." >&2
  echo "[ssh] If this is a new machine, add GitHub to known_hosts after verifying the host key fingerprint." >&2
  exit "$ssh_rc"
fi
printf '%s\n' "$ssh_output"

REPO_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
if [ "$SET_REMOTE" -eq 1 ] && [ -d "$REPO_DIR/.git" ]; then
  cd "$REPO_DIR"
  if git remote | grep -qx origin; then
    echo "[git] Setting origin to SSH"
    git remote set-url origin "git@github.com:11w5/dotfiles.git"
  else
    git remote add origin "git@github.com:11w5/dotfiles.git"
  fi
  echo "[git] Remote now: $(git remote get-url origin)"
fi

echo "[done] GitHub SSH path is ready."
