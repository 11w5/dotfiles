#!/usr/bin/env bash
set -euo pipefail

# Safely adopt existing files into the stow tree (with backup)
# Usage: stow_adopt.sh [package ...]

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STOW_DIR="$ROOT/stow"
BACKUP_DIR="$ROOT/.adopt_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

if ! command -v stow >/dev/null 2>&1; then
  echo "GNU Stow not available" >&2
  exit 1
fi

PKGS=("$@")
if [ ${#PKGS[@]} -eq 0 ]; then
  PKGS=(bash zsh tmux nvim ranger scripts dev git)
fi

echo "Adopting packages into stow tree: ${PKGS[*]}"
echo "Backup of moved files: $BACKUP_DIR"

STOW_DIR="$STOW_DIR" STOW_ADOPT=1 stow -d "$STOW_DIR" -t "$HOME" --adopt "${PKGS[@]}"

echo "If files were overwritten, check backups under $BACKUP_DIR"

