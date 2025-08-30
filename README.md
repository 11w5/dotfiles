# Dotfiles (Terminal Dev)

Minimal, navigation-first setup for Python (uv) and JS, tmux + Neovim.

## Contents
- bashrc.d/: shell aliases, navigation helpers, uv helpers
- tmux.conf: tmux with Ctrl-a prefix and TPM plugins; Prefix+e toggles Neovim tree
- nvim/: minimal Neovim config with file tree, Telescope, LSP, Treesitter
- ranger/: basic config (optional)
- scripts/: utility scripts (uv project, JS project, tmux IDE, specs, corepack)
- Dev/start-dev.sh: default tmux session launcher

## Quick start on a new machine

1) Clone the repo:
   git clone <your-repo-url> ~/dotfiles
   cd ~/dotfiles

2) Bootstrap:
   ./bootstrap.sh

3) Start working:
   source ~/.bashrc
   ~/Dev/start-dev.sh [project]

Python (uv):
- Create project: ~/scripts/new_python_uv_project.sh myproj
- Enter dir: cd ~/Dev/Projects/myproj
- Sync deps: uv sync; Test: uv run pytest

JavaScript:
- Create project: ~/scripts/new_js_project.sh myapp
- Install deps: pnpm install (or npm install)

tmux tips:
- Prefix is Ctrl-a; Prefix + e toggles file tree in current Neovim pane.
- Use ~/scripts/tmux_ide.sh <project> to open a project IDE.
