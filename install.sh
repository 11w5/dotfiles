#!/usr/bin/env bash
set -euo pipefail

# Universal bootstrap for 11w5/dotfiles
# - Installs minimal deps (git, stow, curl, unzip)
# - Clones/updates repo to ~/dotfiles
# - Runs stow bootstrap + package installers + CSV tools
#
# Usage (recommended):
#   curl -fsSL https://raw.githubusercontent.com/11w5/dotfiles/main/install.sh | bash
#
# Options via environment or flags:
#   DOTFILES_REPO   (default: https://github.com/11w5/dotfiles.git)
#   DOTFILES_DIR    (default: $HOME/dotfiles)
#   DOTFILES_BRANCH (default: main)
#   NO_PKGS=1       (skip install_packages.sh)
#   NO_CSV=1        (skip install_csv_tools.sh)
#   --dir DIR, --repo URL, --branch BR   (override vars)

REPO_URL=${DOTFILES_REPO:-https://github.com/11w5/dotfiles.git}
TARGET_DIR=${DOTFILES_DIR:-$HOME/dotfiles}
BRANCH=${DOTFILES_BRANCH:-main}
PROFILE=${DOTFILES_PROFILE:-}
NO_PKGS=${NO_PKGS:-0}
NO_CSV=${NO_CSV:-0}

while [ $# -gt 0 ]; do
  case "$1" in
    --dir) TARGET_DIR="$2"; shift 2;;
    --repo) REPO_URL="$2"; shift 2;;
    --branch) BRANCH="$2"; shift 2;;
    --no-packages) NO_PKGS=1; shift;;
    --no-csv) NO_CSV=1; shift;;
    --profile) PROFILE="$2"; shift 2;;
    *) echo "Unknown arg: $1" >&2; exit 1;;
  esac
done

log() { printf "[dotfiles-install] %s\n" "$*"; }

detect_pm() {
  if command -v apt-get >/dev/null 2>&1; then echo apt; return; fi
  if command -v brew >/dev/null 2>&1; then echo brew; return; fi
  echo none
}

install_deps() {
  local pm; pm=$(detect_pm)
  case "$pm" in
    apt)
      log "Installing deps via apt (git stow curl unzip ca-certificates)…"
      sudo apt-get update -y || true
      sudo DEBIAN_FRONTEND=noninteractive apt-get install -y git stow curl unzip ca-certificates || true
      ;;
    brew)
      log "Installing deps via brew (git stow curl unzip)…"
      brew update || true
      brew install git stow curl unzip || true
      ;;
    none)
      log "No apt/brew detected. Please install git, stow, curl, unzip manually. Continuing without deps install."
      ;;
  esac
}

clone_or_update() {
  if [ -d "$TARGET_DIR/.git" ]; then
    log "Updating existing repo at $TARGET_DIR…"
    git -C "$TARGET_DIR" fetch --all --tags || true
    git -C "$TARGET_DIR" checkout "$BRANCH" || true
    git -C "$TARGET_DIR" pull --rebase || true
  else
    log "Cloning $REPO_URL into $TARGET_DIR…"
    mkdir -p "$(dirname "$TARGET_DIR")"
    git clone --branch "$BRANCH" --depth 1 "$REPO_URL" "$TARGET_DIR"
  fi
}

run_bootstrap() {
  cd "$TARGET_DIR"
  if [ -x ./scripts/bootstrap_stow.sh ]; then
    log "Running stow bootstrap…"
    if [ -n "$PROFILE" ]; then DOTFILES_PROFILE="$PROFILE" ./scripts/bootstrap_stow.sh; else ./scripts/bootstrap_stow.sh; fi
  elif [ -x ./bootstrap.sh ]; then
    log "Running legacy bootstrap…"
    ./bootstrap.sh
  else
    log "No bootstrap script found in repo."
  fi
}

run_installers() {
  cd "$TARGET_DIR"
  if [ "$NO_PKGS" -eq 0 ] && [ -x ./scripts/install_packages.sh ]; then
    log "Installing package sets (apt/brew + pipx/npm/cargo)…"
    if [ -n "$PROFILE" ]; then DOTFILES_PROFILE="$PROFILE" ./scripts/install_packages.sh || true; else ./scripts/install_packages.sh || true; fi
  else
    log "Skipping package sets (NO_PKGS=$NO_PKGS)."
  fi
  if [ "$NO_CSV" -eq 0 ] && [ -x ./scripts/install_csv_tools.sh ]; then
    log "Installing CSV tools (duckdb, xsv, csvview)…"
    ./scripts/install_csv_tools.sh || true
  else
    log "Skipping CSV tools (NO_CSV=$NO_CSV)."
  fi
}

post_notes() {
  log "Done. Open a new shell or run: source ~/.bashrc"
  printf "\nSuggested next steps:\n"
  printf "  - vd data.csv              # interactive CSV browser\n"
  printf "  - csvview data.csv         # pretty CSV table\n"
  printf "  - duckdb -c \"select * from read_csv_auto('data.csv') limit 20\"\n"
  printf "  - ~/Dev/start-dev.sh myproj\n"
}

install_deps
clone_or_update
run_bootstrap
run_installers
post_notes
