#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"

cat >&2 <<'NOTE'
[dotfiles] bootstrap.sh is now a compatibility wrapper.
[dotfiles] The secure canonical path is scripts/bootstrap_stow.sh.
NOTE

exec "$ROOT/scripts/bootstrap_stow.sh" "$@"
