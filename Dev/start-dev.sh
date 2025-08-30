#!/usr/bin/env bash
set -euo pipefail
# Start a general dev tmux or project IDE if provided: start-dev.sh [project-name|path]
if [ $# -gt 0 ]; then
  exec "$HOME/scripts/tmux_ide.sh" "$1"
fi
session="dev"
if ! tmux has-session -t "$session" 2>/dev/null; then
  tmux new-session -d -s "$session" -n editor -c "$HOME/Dev/Projects" "${EDITOR:-nvim} -c 'NvimTreeOpen'"
  tmux new-window -t "$session":2 -n shell -c "$HOME/Dev/Projects"
  tmux select-window -t "$session":1
fi
tmux attach -t "$session"
