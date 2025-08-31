#!/usr/bin/env bash
set -euo pipefail

# Installs packages from packages/*.txt:
# - apt.txt via apt-get
# - pipx.txt via pipx
# - npm.txt via npm -g
# - cargo.txt via cargo install

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROFILE="${DOTFILES_PROFILE:-full}"

# Choose package lists by profile
APT_LIST="$ROOT/packages/apt.txt"
BREW_LIST="$ROOT/packages/brew.txt"
case "$PROFILE" in
  minimal|server)
    [ -f "$ROOT/packages/apt-minimal.txt" ] && APT_LIST="$ROOT/packages/apt-minimal.txt"
    [ -f "$ROOT/packages/brew-minimal.txt" ] && BREW_LIST="$ROOT/packages/brew-minimal.txt"
    ;;
  full|*) : ;;
esac
PIPX_LIST="$ROOT/packages/pipx.txt"
NPM_LIST="$ROOT/packages/npm.txt"
CARGO_LIST="$ROOT/packages/cargo.txt"

echo "[install_packages] Using ROOT=$ROOT"
echo "[install_packages] Profile=$PROFILE"

# sudo helper
SUDO=""
if [ "${EUID:-$(id -u)}" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
  SUDO=sudo
fi

install_apt() {
  [ -f "$APT_LIST" ] || return 0
  echo "[apt] Updating package index…"
  $SUDO apt-get update -y
  # Build a list ignoring comments/empty lines
  mapfile -t pkgs < <(sed -e 's/#.*$//' -e '/^\s*$/d' "$APT_LIST")
  if [ ${#pkgs[@]} -gt 0 ]; then
    echo "[apt] Installing: ${pkgs[*]}"
    DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y "${pkgs[@]}"
    # fd alias on Ubuntu, if needed
    if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
      echo "alias fd='fdfind'" >> "$HOME/.bashrc.d/10-dev-env.sh"
    fi
    command -v tldr >/dev/null 2>&1 && tldr -u || true
  else
    echo "[apt] No packages listed."
  fi
}

install_brew() {
  [ -f "$BREW_LIST" ] || return 0
  if ! command -v brew >/dev/null 2>&1; then
    echo "[brew] Homebrew not found; skipping."
    return 0
  fi
  mapfile -t pkgs < <(sed -e 's/#.*$//' -e '/^\s*$/d' "$BREW_LIST")
  if [ ${#pkgs[@]} -gt 0 ]; then
    echo "[brew] Installing: ${pkgs[*]}"
    brew update || true
    brew install "${pkgs[@]}" || true
  else
    echo "[brew] No packages listed."
  fi
}

ensure_pipx() {
  if command -v pipx >/dev/null 2>&1; then return 0; fi
  if command -v apt-get >/dev/null 2>&1; then
    $SUDO apt-get update -y
    $SUDO apt-get install -y pipx || true
  fi
  if ! command -v pipx >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
    python3 -m pip install --user pipx || true
    python3 -m pipx ensurepath || true
  fi
}

install_pipx() {
  [ -f "$PIPX_LIST" ] || return 0
  mapfile -t pkgs < <(sed -e 's/#.*$//' -e '/^\s*$/d' "$PIPX_LIST")
  [ ${#pkgs[@]} -gt 0 ] || { echo "[pipx] No packages listed."; return 0; }
  ensure_pipx
  if ! command -v pipx >/dev/null 2>&1; then
    echo "[pipx] pipx not available; skipping."
    return 0
  fi
  echo "[pipx] Installing: ${pkgs[*]}"
  for p in "${pkgs[@]}"; do
    pipx install "$p" || pipx upgrade "$p" || true
  done
}

install_npm() {
  [ -f "$NPM_LIST" ] || return 0
  mapfile -t pkgs < <(sed -e 's/#.*$//' -e '/^\s*$/d' "$NPM_LIST")
  [ ${#pkgs[@]} -gt 0 ] || { echo "[npm] No packages listed."; return 0; }
  if ! command -v npm >/dev/null 2>&1; then
    if command -v apt-get >/dev/null 2>&1; then
      $SUDO apt-get update -y
      $SUDO apt-get install -y npm || true
    fi
  fi
  if ! command -v npm >/dev/null 2>&1; then
    echo "[npm] npm not available; skipping."
    return 0
  fi
  echo "[npm] Installing globally: ${pkgs[*]}"
  npm -g install "${pkgs[@]}" || true
}

install_cargo() {
  [ -f "$CARGO_LIST" ] || return 0
  mapfile -t pkgs < <(sed -e 's/#.*$//' -e '/^\s*$/d' "$CARGO_LIST")
  [ ${#pkgs[@]} -gt 0 ] || { echo "[cargo] No packages listed."; return 0; }
  if ! command -v cargo >/dev/null 2>&1; then
    echo "[cargo] cargo not found; install Rust toolchain (https://rustup.rs). Skipping."
    return 0
  fi
  echo "[cargo] Installing: ${pkgs[*]}"
  cargo install ${pkgs[*]} || true
}

if command -v apt-get >/dev/null 2>&1; then
  install_apt
elif command -v brew >/dev/null 2>&1; then
  install_brew
else
  echo "No supported system package manager found (apt/brew). Skipping system packages."
fi
install_pipx
install_npm
install_cargo

echo "Done. You may need to restart your shell."
