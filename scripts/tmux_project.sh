#!/usr/bin/env bash
set -euo pipefail
name=${1:-}
[ -n "$name" ] || { echo "Usage: tmux_project.sh <project-dir>"; exit 1; }
proj="$HOME/Dev/Projects/$name"
[ -d "$proj" ] || { echo "Project not found: $proj"; exit 1; }
session="proj-$name"
if ! tmux has-session -t "$session" 2>/dev/null; then
  tmux new-session -d -s "$session" -n editor -c "$proj"
  tmux send-keys -t "$session":1 "${EDITOR:-nvim}" C-m
  tmux new-window -t "$session":2 -n git -c "$proj"
  tmux send-keys -t "$session":2 'git status' C-m
fi
tmux attach -t "$session"
