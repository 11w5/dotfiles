#!/usr/bin/env bash
set -euo pipefail

# Adopt existing files into the stow tree. This is intentionally gated because
# stow --adopt can replace tracked repo content with local machine files.
# Usage: stow_adopt.sh [package ...]

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STOW_DIR="$ROOT/stow"

if [ "${DOTFILES_ALLOW_ADOPT:-0}" != "1" ]; then
  echo "Refusing stow --adopt by default." >&2
  echo "It can overwrite tracked config with local machine files." >&2
  echo "Set DOTFILES_ALLOW_ADOPT=1 after reviewing git status and SECURITY.md." >&2
  exit 1
fi

if [ -n "$(git -C "$ROOT" status --porcelain)" ]; then
  echo "Refusing adopt with a dirty working tree." >&2
  exit 1
fi

if ! command -v stow >/dev/null 2>&1; then
  echo "GNU Stow not available" >&2
  exit 1
fi

PKGS=("$@")
if [ ${#PKGS[@]} -eq 0 ]; then
  PKGS=(bash zsh tmux nvim ranger scripts dev git)
fi

echo "Adopting packages into stow tree: ${PKGS[*]}"
echo "Review the resulting git diff before committing."

STOW_DIR="$STOW_DIR" STOW_ADOPT=1 stow -d "$STOW_DIR" -t "$HOME" --adopt "${PKGS[@]}"

echo "Adopt complete. Review with: git diff -- stow/"
