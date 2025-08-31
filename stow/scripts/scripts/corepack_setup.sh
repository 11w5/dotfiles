#!/usr/bin/env bash
set -euo pipefail
if command -v corepack >/dev/null 2>&1; then
  corepack enable
  corepack prepare yarn@stable --activate || true
  corepack prepare pnpm@latest --activate || true
  echo "Corepack enabled for yarn and pnpm."
else
  echo "corepack not found (requires Node 16+)."
fi

