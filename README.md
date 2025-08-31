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

2) Option A — Stow-based bootstrap (recommended):
   # Creates symlinks to your home with GNU Stow
   ./scripts/bootstrap_stow.sh

   Option B — Legacy bootstrap (simple symlinks):
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

## System packages and CLI tools

There are two options depending on how much you want installed:

- Minimal essentials (apt):
  ./scripts/install_apt_minimal.sh

- Curated package sets + CSV tools:
  ./scripts/install_packages.sh          # installs from packages/ lists (apt/pipx/npm/cargo)
  ./scripts/install_csv_tools.sh         # installs duckdb, xsv, and a csvview helper

Customize the lists under packages/:
- packages/apt.txt   — apt packages (Ubuntu/Debian)
- packages/pipx.txt  — Python CLIs installed with pipx (user-local)
- packages/npm.txt   — global npm packages (optional)
- packages/cargo.txt — Rust cargo installs (optional)

One-liner (Ubuntu/Mac):
  ./scripts/bootstrap_stow.sh && ./scripts/install_packages.sh && ./scripts/install_csv_tools.sh

CSV exploration tips:
- Interactive: vd data.csv (arrow keys, / search, , filter, s sort)
- Pretty table: csvview data.csv (aligned columns; left/right to scroll)
- SQL on CSV: duckdb -c "select * from read_csv_auto('data.csv') limit 50"

## Stow layout

Packages live under stow/ and mirror their destinations under $HOME:
- stow/bash/.bashrc.d/*            -> ~/.bashrc.d/*
- stow/tmux/.tmux.conf             -> ~/.tmux.conf
- stow/nvim/.config/nvim/init.lua  -> ~/.config/nvim/init.lua
- stow/ranger/.config/ranger/*     -> ~/.config/ranger/*
- stow/scripts/scripts/*           -> ~/scripts/*
- stow/dev/Dev/start-dev.sh        -> ~/Dev/start-dev.sh

Add or remove packages by editing the stow/* trees, then rerun:
  stow -d stow -t "$HOME" <pkg1> <pkg2> ...

## Philosophy

- Light: small, fast configs; lazy-load heavy tools; no frameworks required.
- Efficient: short, memorable aliases; project pickers (pp); auto-venv.
- Interoperable: works on Ubuntu, macOS, WSL; both Bash and Zsh.
- Portable: single stow/ layout; installers read package lists.

Cross-platform specifics:
- Shell: Zsh sources the same ~/.bashrc.d scripts for shared behavior.
- Package install: apt on Ubuntu, brew on macOS/Linuxbrew; pipx/npm/cargo optional.
- Clipboard: tmux uses OSC52, which works over SSH and tmux.
