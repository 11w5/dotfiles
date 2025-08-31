#!/usr/bin/env bash
set -euo pipefail

DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
cd "$DIR"

echo "[dot-update] Pulling latest…"
git pull --rebase || true

echo "[dot-update] Restowing…"
stow -d "$DIR/stow" -t "$HOME" -R bash zsh tmux nvim ranger scripts dev git 2>/dev/null || true

echo "[dot-update] Done."

