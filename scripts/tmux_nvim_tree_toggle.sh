#!/usr/bin/env bash
set -euo pipefail
# If current tmux pane runs nvim, toggle NvimTree; else start nvim with tree
cmd=$(tmux display-message -p '#{pane_current_command}' | tr 'A-Z' 'a-z')
if [[ "$cmd" == nvim ]]; then
  tmux send-keys Escape ':NvimTreeToggle' Enter
else
  tmux send-keys 'nvim -c "NvimTreeOpen"' C-m
fi
