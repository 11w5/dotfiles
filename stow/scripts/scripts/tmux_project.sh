#!/usr/bin/env bash
set -euo pipefail
if [ $# -lt 1 ]; then
  echo "Usage: tmux_project.sh <project-name>" >&2
  exit 1
fi
"$(dirname "$0")/tmux_ide.sh" "$1"

