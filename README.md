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

Zero‑thought install (recommended)
  curl -fsSL https://raw.githubusercontent.com/11w5/dotfiles/main/install.sh | bash

The installer will:
- Install minimal deps (git, stow, curl, unzip) via apt/brew when available.
- Clone/update to ~/dotfiles.
- Stow configs and install curated packages + CSV tools.
- Respect profiles (DOTFILES_PROFILE=minimal|server|full) for package selection.

1) Clone the repo:
   # HTTPS
   git clone https://github.com/11w5/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   # Or SSH (after adding an SSH key to GitHub)
   # git clone git@github.com:11w5/dotfiles.git ~/dotfiles && cd ~/dotfiles

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

## Install Across OSes

Ubuntu/Debian (fresh machine)
```
sudo apt-get update && sudo apt-get install -y git stow curl unzip ca-certificates
git clone https://github.com/11w5/dotfiles.git ~/dotfiles && cd ~/dotfiles
./scripts/bootstrap_stow.sh
./scripts/install_packages.sh
./scripts/install_csv_tools.sh
```

macOS (Homebrew)
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"  # if brew missing
brew install git stow
git clone https://github.com/11w5/dotfiles.git ~/dotfiles && cd ~/dotfiles
./scripts/bootstrap_stow.sh
./scripts/install_packages.sh
./scripts/install_csv_tools.sh
```

WSL / Remote Ubuntu
```
sudo apt-get update && sudo apt-get install -y git stow
git clone https://github.com/11w5/dotfiles.git ~/dotfiles && cd ~/dotfiles
./scripts/bootstrap_stow.sh
./scripts/install_packages.sh
./scripts/install_csv_tools.sh
```

No sudo / no stow available
- Use the legacy bootstrap: `./bootstrap.sh` (creates direct symlinks without stow)
- You can still run: `./scripts/install_csv_tools.sh` (writes to ~/.local/bin if needed)

Installer options
- Set environment variables before running the installer:
  - `DOTFILES_DIR=~/mydot curl -fsSL https://raw.githubusercontent.com/11w5/dotfiles/main/install.sh | bash`
  - `NO_PKGS=1 NO_CSV=1 curl -fsSL https://raw.githubusercontent.com/11w5/dotfiles/main/install.sh | bash`
  - `DOTFILES_PROFILE=minimal curl -fsSL https://raw.githubusercontent.com/11w5/dotfiles/main/install.sh | bash`
- Or pass flags when running locally:
  - `./install.sh --dir ~/mydot --branch main --no-packages --no-csv --profile minimal`

## Make targets

Shortcuts for common flows:
- `make bootstrap`  — stow link all packages
- `make packages`   — install apt/brew + pipx/npm/cargo from packages/*
- `make csv`        — install duckdb, xsv (best‑effort) and csvview
- `make full`       — bootstrap + packages + csv
- `make ssh`        — generate SSH key, upload via gh, set origin to SSH
- `make publish`    — publish/push to GitHub (token flow fallback)
- `make update`     — git pull + restow
- `make uninstall`  — destow all packages

## Stow layout

Packages live under stow/ and mirror their destinations under $HOME:
- stow/bash/.bashrc.d/*            -> ~/.bashrc.d/*
- stow/tmux/.tmux.conf             -> ~/.tmux.conf
- stow/nvim/.config/nvim/init.lua  -> ~/.config/nvim/init.lua
- stow/ranger/.config/ranger/*     -> ~/.config/ranger/*
- stow/scripts/scripts/*           -> ~/scripts/*
- stow/dev/Dev/start-dev.sh        -> ~/Dev/start-dev.sh
 - stow/editor/.editorconfig       -> ~/.editorconfig
 - stow/git/.gitignore_global      -> ~/.gitignore_global

Optional OS/host overrides (create dirs if needed):
- stow/os-linux, stow/os-macos, stow/os-wsl
- stow/host-<your-hostname>

Add or remove packages by editing the stow/* trees, then rerun:
  stow -d stow -t "$HOME" <pkg1> <pkg2> ...

Update on an existing machine
```
cd ~/dotfiles && git pull
stow -d stow -t "$HOME" -R bash zsh tmux nvim ranger scripts dev git editor
```

Unstow (remove symlinks)
```
stow -d stow -t "$HOME" -D <pkg>
```

Adopt existing files into the repo
```
# Moves your current dotfiles into the stow tree and links them back.
# Creates a timestamped backup folder under the repo.
./scripts/stow_adopt.sh
```

## Philosophy

- Light: small, fast configs; lazy-load heavy tools; no frameworks required.
- Efficient: short, memorable aliases; project pickers (pp); auto-venv.
- Interoperable: works on Ubuntu, macOS, WSL; both Bash and Zsh.
- Portable: single stow/ layout; installers read package lists.

Cross-platform specifics:
- Shell: Zsh sources the same ~/.bashrc.d scripts for shared behavior.
- Package install: apt on Ubuntu, brew on macOS/Linuxbrew; pipx/npm/cargo optional.
- Clipboard: tmux uses OSC52, which works over SSH and tmux.

## Commands Cheat Sheet

- proj: jump to `~/Dev/Projects`
- pp: project picker (fzf + fd/fdfind)
- mkpy <name>: Python project with uv (init + venv + sync)
- mkjs <name>: JS project (pnpm via corepack if available; else npm)
- v: open `$EDITOR` (nvim)
- o <path>: open in system file browser (macOS open, WSL wslview, Linux xdg-open/gio)
- csv <file.csv>: quick aligned table (uses csvview/column)
- vd data.csv: interactive CSV exploration
- csvview data.csv: pretty table with horizontal scroll
- duckdb -c "select * from read_csv_auto('data.csv') limit 50": SQL on CSV

## Troubleshooting

- stow: command not found
  - Install with your package manager (Ubuntu: `sudo apt-get install stow`, macOS: `brew install stow`).
  - Or run the legacy `./bootstrap.sh` to create symlinks without stow.

- `fd` not found on Ubuntu
  - Package is `fd-find` on Ubuntu; an alias is added automatically to map `fd` → `fdfind`.

- `xsv` download fails in install_csv_tools.sh
  - The script falls back to `csvlook` (csvkit) or `column` if `xsv` cannot be fetched.

- PATH doesn’t include `~/.local/bin`
  - `bootstrap_stow.sh` and the installers append it to `~/.bashrc` when needed. Restart shell or: `export PATH="$HOME/.local/bin:$PATH"`.
 
 - Use a different profile (fewer packages)
   - `DOTFILES_PROFILE=minimal ./install.sh` or set in your shell: `export DOTFILES_PROFILE=minimal`

## Publish/Sync (optional)

First publish to GitHub (if not already):
```
# Using gh CLI with token (no browser):
~/scripts/github_publish_token.sh

# If remote exists but push failed earlier:
~/scripts/github_fix_remote_push.sh
```

On a new machine:
```
git clone https://github.com/11w5/dotfiles.git ~/dotfiles && cd ~/dotfiles
./scripts/bootstrap_stow.sh && ./scripts/install_packages.sh && ./scripts/install_csv_tools.sh
```

## CI

This repo includes a minimal CI that:
- Runs shellcheck on scripts.
- Executes `install.sh` with `--no-packages --no-csv` to validate stow linking.
