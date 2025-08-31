#!/usr/bin/env bash
set -euo pipefail
# Usage: tmux_ide.sh <project-name-or-path>
if [ $# -eq 0 ]; then
  echo "Usage: $0 <project-name-or-path>" >&2
  exit 1
fi
proj="$1"
case "$proj" in
  /*) proj_dir="$proj" ;;
  *)  proj_dir="$HOME/Dev/Projects/$proj" ;;
esac
mkdir -p "$proj_dir"
session="proj_$(basename "$proj_dir" | tr ':/ ' '___')"
if ! tmux has-session -t "$session" 2>/dev/null; then
  tmux new-session -d -s "$session" -n editor -c "$proj_dir" "${EDITOR:-nvim} -c 'NvimTreeOpen'"
  tmux new-window -t "$session":2 -n shell -c "$proj_dir"
  tmux select-window -t "$session":1
fi
tmux attach -t "$session"

