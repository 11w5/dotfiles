#!/usr/bin/env bash
set -euo pipefail
# Usage: tmux_ide.sh <path-or-project-name>
arg=${1:-}
[ -n "$arg" ] || { echo "Usage: tmux_ide.sh <path-or-project-name>"; exit 1; }
case "$arg" in
  /*|.~*) proj=$(readlink -f "$arg") ;;
  *) proj="$HOME/Dev/Projects/$arg" ;;
esac
[ -d "$proj" ] || { echo "Directory not found: $proj"; exit 1; }
name="ide-$(basename "$proj")"

if ! command -v tmux >/dev/null 2>&1; then
  echo "tmux not installed"
  exit 1
fi

if ! tmux has-session -t "$name" 2>/dev/null; then
  tmux new-session -d -s "$name" -n code -c "$proj" "${EDITOR:-nvim} -c 'NvimTreeOpen'"
  tmux split-window -v -t "$name":1 -c "$proj"
  tmux select-pane -t "$name":1.1
fi

tmux attach -t "$name"
