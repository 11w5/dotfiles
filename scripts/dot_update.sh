#!/usr/bin/env bash
set -euo pipefail

DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
cd "$DIR"

echo "[dot-update] Pulling latest…"
if [ -n "$(git status --porcelain)" ]; then
  echo "[dot-update] Refusing to update dirty repo: $DIR" >&2
  exit 1
fi
git pull --ff-only

echo "[dot-update] Restowing…"
stow -d "$DIR/stow" -t "$HOME" -R bash zsh starship tmux nvim ranger scripts dev git editor

echo "[dot-update] Done."
