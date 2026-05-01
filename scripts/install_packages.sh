#!/usr/bin/env bash
set -euo pipefail
umask 077

# Installs packages from packages/*.txt:
# - apt.txt via apt-get
# - pipx.txt via pipx
# - npm.txt via npm -g
# - cargo.txt via cargo install

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROFILE="${DOTFILES_PROFILE:-full}"
ALLOW_REMOTE_INSTALLERS="${DOTFILES_ALLOW_REMOTE_INSTALLERS:-0}"

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

log() { printf '[install_packages] %s\n' "$*"; }

log "Using ROOT=$ROOT"
log "Profile=$PROFILE"

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
  mapfile -t pkgs_raw < <(sed -e 's/#.*$//' -e '/^\s*$/d' "$APT_LIST")
  # Filter out packages not available in current apt repos (avoid whole install failing)
  pkgs=()
  for p in "${pkgs_raw[@]}"; do
    if apt-cache show "$p" >/dev/null 2>&1; then
      pkgs+=("$p")
    else
      echo "[apt] Skipping unavailable package: $p"
    fi
  done
  if [ ${#pkgs[@]} -gt 0 ]; then
    echo "[apt] Installing: ${pkgs[*]}"
    DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y "${pkgs[@]}"
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
    brew update
    brew install "${pkgs[@]}"
  else
    echo "[brew] No packages listed."
  fi
}

ensure_pipx() {
  if command -v pipx >/dev/null 2>&1; then return 0; fi
  if command -v apt-get >/dev/null 2>&1; then
    $SUDO apt-get update -y
    $SUDO apt-get install -y pipx
  fi
  if ! command -v pipx >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
    if [ "$ALLOW_REMOTE_INSTALLERS" = "1" ]; then
      python3 -m pip install --user pipx
      python3 -m pipx ensurepath
    else
      echo "[pipx] pipx missing; skipping Python package installs."
      echo "[pipx] Install pipx with apt/brew or set DOTFILES_ALLOW_REMOTE_INSTALLERS=1."
    fi
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
  [ "$ALLOW_REMOTE_INSTALLERS" = "1" ] || {
    echo "[pipx] Skipping remote Python installs. Set DOTFILES_ALLOW_REMOTE_INSTALLERS=1 to allow."
    return 0
  }
  echo "[pipx] Installing: ${pkgs[*]}"
  for p in "${pkgs[@]}"; do
    pipx install "$p" || pipx upgrade "$p"
  done
}

install_npm() {
  [ -f "$NPM_LIST" ] || return 0
  mapfile -t pkgs < <(sed -e 's/#.*$//' -e '/^\s*$/d' "$NPM_LIST")
  [ ${#pkgs[@]} -gt 0 ] || { echo "[npm] No packages listed."; return 0; }
  if ! command -v npm >/dev/null 2>&1; then
    if command -v apt-get >/dev/null 2>&1; then
      $SUDO apt-get update -y
      $SUDO apt-get install -y npm
    fi
  fi
  if ! command -v npm >/dev/null 2>&1; then
    echo "[npm] npm not available; skipping."
    return 0
  fi
  [ "$ALLOW_REMOTE_INSTALLERS" = "1" ] || {
    echo "[npm] Skipping global npm installs. Set DOTFILES_ALLOW_REMOTE_INSTALLERS=1 to allow."
    return 0
  }
  echo "[npm] Installing globally: ${pkgs[*]}"
  npm -g install "${pkgs[@]}"
}

install_cargo() {
  [ -f "$CARGO_LIST" ] || return 0
  mapfile -t pkgs < <(sed -e 's/#.*$//' -e '/^\s*$/d' "$CARGO_LIST")
  [ ${#pkgs[@]} -gt 0 ] || { echo "[cargo] No packages listed."; return 0; }
  if ! command -v cargo >/dev/null 2>&1; then
    echo "[cargo] cargo not found; install Rust toolchain (https://rustup.rs). Skipping."
    return 0
  fi
  [ "$ALLOW_REMOTE_INSTALLERS" = "1" ] || {
    echo "[cargo] Skipping cargo installs. Set DOTFILES_ALLOW_REMOTE_INSTALLERS=1 to allow."
    return 0
  }
  echo "[cargo] Installing: ${pkgs[*]}"
  cargo install "${pkgs[@]}"
}

install_visual_extras() {
  local extras

  if ! command -v starship >/dev/null 2>&1; then
    if command -v curl >/dev/null 2>&1 && [ "$ALLOW_REMOTE_INSTALLERS" = "1" ]; then
      echo "[starship] Installing to $HOME/.local/bin"
      mkdir -p "$HOME/.local/bin"
      curl -fsSL https://starship.rs/install.sh | DOTFILES_ALLOW_REMOTE_INSTALLERS=1 sh -s -- -y -b "$HOME/.local/bin"
    else
      echo "[starship] Missing from package manager path; skipping remote installer."
      echo "[starship] Set DOTFILES_ALLOW_REMOTE_INSTALLERS=1 if you want the upstream install script."
    fi
  fi

  extras=()
  command -v eza >/dev/null 2>&1 || extras+=(eza)
  [ ${#extras[@]} -gt 0 ] || return 0

  if command -v brew >/dev/null 2>&1; then
    echo "[brew] Installing visual shell extras: ${extras[*]}"
    brew install "${extras[@]}"
    return 0
  fi

  if command -v cargo >/dev/null 2>&1 && [ "$ALLOW_REMOTE_INSTALLERS" = "1" ]; then
    echo "[cargo] Installing visual shell extras: ${extras[*]}"
    for p in "${extras[@]}"; do
      cargo install "$p" --locked
    done
    return 0
  fi

  echo "[extras] Missing optional visual tools: ${extras[*]}"
  echo "[extras] Install Homebrew or Rust/Cargo, then rerun this script for the full prompt setup."
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
install_visual_extras

echo "Done. You may need to restart your shell."
