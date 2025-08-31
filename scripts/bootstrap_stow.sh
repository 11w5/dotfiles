#!/usr/bin/env bash
set -euo pipefail

# Bootstrap symlinks using GNU Stow
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STOW_DIR="$ROOT/stow"

if [ ! -d "$STOW_DIR" ]; then
  echo "stow/ directory not found at $STOW_DIR" >&2
  exit 1
fi

# Ensure target directories exist
mkdir -p "$HOME/.bashrc.d" "$HOME/.config" "$HOME/scripts" "$HOME/Dev/Projects"

# Install stow if missing (best-effort)
if ! command -v stow >/dev/null 2>&1; then
  if command -v apt-get >/dev/null 2>&1; then
    echo "Installing stow via apt…"
    sudo apt-get update -y && sudo apt-get install -y stow || true
  fi
fi
command -v stow >/dev/null 2>&1 || { echo "GNU Stow not available. Install it and re-run."; exit 1; }

# Stow packages
PKGS=(bash zsh tmux nvim ranger scripts dev git)
echo "Stowing packages: ${PKGS[*]}"
stow -d "$STOW_DIR" -t "$HOME" "${PKGS[@]}"

# Ensure .bashrc sources ~/.bashrc.d/*.sh
if ! grep -q "bashrc.d" "$HOME/.bashrc" 2>/dev/null; then
  printf '\n# Load additional bash configs\nfor f in "$HOME"/.bashrc.d/*.sh; do [ -r "$f" ] && . "$f"; done\n' >> "$HOME/.bashrc"
fi

echo "Stow bootstrap complete. Open a new shell or run: source ~/.bashrc"
