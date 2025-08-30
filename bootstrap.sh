#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$HOME/.bashrc.d" "$HOME/.config/nvim" "$HOME/.config/ranger" "$HOME/scripts" "$HOME/Dev"

# Symlink configs
ln -sf "$ROOT/bashrc.d/10-dev-env.sh" "$HOME/.bashrc.d/10-dev-env.sh"
[ -f "$ROOT/bashrc.d/20-brew-extras.sh" ] && ln -sf "$ROOT/bashrc.d/20-brew-extras.sh" "$HOME/.bashrc.d/20-brew-extras.sh"
ln -sf "$ROOT/tmux.conf" "$HOME/.tmux.conf"
ln -sf "$ROOT/nvim/init.lua" "$HOME/.config/nvim/init.lua"
[ -f "$ROOT/ranger/rc.conf" ] && ln -sf "$ROOT/ranger/rc.conf" "$HOME/.config/ranger/rc.conf"

# Symlink scripts
for f in "$ROOT"/scripts/*.sh; do
  [ -f "$f" ] && ln -sf "$f" "$HOME/scripts/$(basename "$f")"
done
chmod +x "$HOME"/scripts/*.sh 2>/dev/null || true

# Dev launcher
[ -f "$ROOT/Dev/start-dev.sh" ] && ln -sf "$ROOT/Dev/start-dev.sh" "$HOME/Dev/start-dev.sh" && chmod +x "$HOME/Dev/start-dev.sh"

# Ensure .bashrc sources ~/.bashrc.d/*.sh
if ! grep -q "bashrc.d" "$HOME/.bashrc" 2>/dev/null; then
  printf '\n# Load additional bash configs\nfor f in "$HOME"/.bashrc.d/*.sh; do [ -r "$f" ] && . "$f"; done\n' >> "$HOME/.bashrc"
fi

# Install uv (user-local)
if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Install Neovim (user-local minimal)
mkdir -p "$HOME/.local/bin"
if ! command -v nvim >/dev/null 2>&1; then
  curl -fsSL https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.tar.gz -o /tmp/nvim-linux64.tar.gz
  tar -xzf /tmp/nvim-linux64.tar.gz -C /tmp/
  cp -f /tmp/nvim-linux64/bin/nvim "$HOME/.local/bin/nvim"
  chmod +x "$HOME/.local/bin/nvim"
fi

# tmux plugins (TPM)
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# Install tmux plugins headless
if command -v tmux >/dev/null 2>&1; then
  tmux -f "$HOME/.tmux.conf" new-session -d -s _tpm_boot -n _tpm || true
  TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins" tmux run-shell "$HOME/.tmux/plugins/tpm/bin/install_plugins" || true
  tmux kill-session -t _tpm_boot || true
fi

echo "Bootstrap complete. Open a new shell or run: source ~/.bashrc"
