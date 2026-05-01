#!/usr/bin/env bash
set -euo pipefail
if command -v corepack >/dev/null 2>&1; then
  corepack enable
  if [ "${DOTFILES_ALLOW_REMOTE_INSTALLERS:-0}" = "1" ]; then
    corepack prepare yarn@stable --activate
    corepack prepare pnpm@latest --activate
  else
    echo "Skipped corepack package-manager downloads."
    echo "Set DOTFILES_ALLOW_REMOTE_INSTALLERS=1 to prepare yarn/pnpm."
  fi
  echo "Corepack enabled for yarn and pnpm."
else
  echo "corepack not found (requires Node 16+)."
fi
