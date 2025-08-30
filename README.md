# Dotfiles (Terminal Dev)

Minimal, navigation-first setup for Python (uv) and JS, tmux + Neovim.

## Contents
- bashrc.d/: shell aliases, navigation helpers, uv helpers (mkpy/mkjs)
- tmux.conf: tmux with Ctrl-a prefix and TPM plugins; Prefix+e toggles Neovim tree
- nvim/: minimal Neovim config with file tree, Telescope, LSP, Treesitter
- ranger/: basic config (optional)
- scripts/: tmux IDE helpers, specs updater, corepack setup
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

Project helpers (optional):
- mkpy myproj  # Create a Python project with uv init + venv
- mkjs myapp   # Create a JS project with pnpm (via corepack) or npm

tmux tips:
- Prefix is Ctrl-a; Prefix + e toggles file tree in current Neovim pane.
- Use ~/scripts/tmux_ide.sh <project> to open a project IDE.

Optional: install common CLI tools via apt (sudo required):
  ./scripts/install_apt_minimal.sh
