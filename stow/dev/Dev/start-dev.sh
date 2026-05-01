#!/usr/bin/env bash
set -euo pipefail
# Start a general dev tmux or project IDE if provided: start-dev.sh [project-name|path]
if [ $# -gt 0 ]; then
  exec "$HOME/scripts/tmux_ide.sh" "$1"
fi
session="dev"
projects_dir="${DOTFILES_PROJECTS_DIR:-$HOME/dev}"
mkdir -p "$projects_dir"
if ! tmux has-session -t "$session" 2>/dev/null; then
  tmux new-session -d -s "$session" -n editor -c "$projects_dir" "${EDITOR:-nvim} -c 'NvimTreeOpen'"
  tmux new-window -t "$session":2 -n shell -c "$projects_dir"
  tmux select-window -t "$session":1
fi
tmux attach -t "$session"
