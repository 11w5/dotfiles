#!/usr/bin/env bash
set -euo pipefail

SUDO=""
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  command -v sudo >/dev/null 2>&1 || { echo "sudo required for apt installs" >&2; exit 1; }
  SUDO=sudo
fi

$SUDO apt-get update
$SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y \
  tmux fzf zoxide ripgrep fd-find bat nnn ranger mc \
  neovim jq tree tldr python3-venv python3-pip
# fd alias on Ubuntu
if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
  echo "alias fd='fdfind'" >> "$HOME/.bashrc.d/10-dev-env.sh"
fi
command -v tldr >/dev/null 2>&1 && tldr -u || true
echo "APT packages installed. Restart shell or: source ~/.bashrc"
