#!/usr/bin/env bash
set -euo pipefail

# Bootstrap symlinks using GNU Stow with OS/host awareness and optional adopt
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STOW_DIR="$ROOT/stow"
PROFILE="${DOTFILES_PROFILE:-full}"
ADOPT="${STOW_ADOPT:-0}"

usage() {
  cat <<USAGE
Usage: $0 [--profile minimal|full|server] [--adopt]

Options:
  --profile   Set profile for selection hints (default: $PROFILE)
  --adopt     Move existing files into stow tree (stow --adopt)
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0;;
    --profile) PROFILE="$2"; shift 2;;
    --adopt) ADOPT=1; shift;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1;;
  esac
done

if [ ! -d "$STOW_DIR" ]; then
  echo "stow/ directory not found at $STOW_DIR" >&2
  exit 1
fi

# Ensure target directories exist
mkdir -p "$HOME/.bashrc.d" "$HOME/.config" "$HOME/scripts" "$HOME/Dev/Projects"

# Install stow if missing (best-effort)
if ! command -v stow >/dev/null 2>&1; then
  if command -v apt-get >/dev/null 2>&1; then
    echo "Installing stow via apt…"
    sudo apt-get update -y && sudo apt-get install -y stow || true
  fi
fi
command -v stow >/dev/null 2>&1 || { echo "GNU Stow not available. Install it and re-run."; exit 1; }

# Compute base packages
PKGS=(bash zsh tmux nvim ranger scripts dev git editor)

# OS-specific packages (optional)
UNAME_S=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$UNAME_S" in
  linux) [ -d "$STOW_DIR/os-linux" ] && PKGS+=(os-linux) ;;
  darwin) [ -d "$STOW_DIR/os-macos" ] && PKGS+=(os-macos) ;;
esac

# WSL detection
if grep -qi microsoft /proc/version 2>/dev/null; then
  [ -d "$STOW_DIR/os-wsl" ] && PKGS+=(os-wsl)
fi

# Host-specific
HOSTPKG="host-$(hostname)"
[ -d "$STOW_DIR/$HOSTPKG" ] && PKGS+=("$HOSTPKG")

echo "Profile: $PROFILE | Adopt: $ADOPT"
echo "Stowing packages: ${PKGS[*]}"

STOW_OPTS=( -d "$STOW_DIR" -t "$HOME" )
[ "$ADOPT" -eq 1 ] && STOW_OPTS+=( --adopt )

stow "${STOW_OPTS[@]}" "${PKGS[@]}"

# Ensure .bashrc sources ~/.bashrc.d/*.sh
if ! grep -q "bashrc.d" "$HOME/.bashrc" 2>/dev/null; then
  printf '\n# Load additional bash configs\nfor f in "$HOME"/.bashrc.d/*.sh; do [ -r "$f" ] && . "$f"; done\n' >> "$HOME/.bashrc"
fi

echo "Stow bootstrap complete. Open a new shell or run: source ~/.bashrc"
