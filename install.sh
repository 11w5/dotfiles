#!/usr/bin/env bash
set -euo pipefail
umask 077

# Universal bootstrap for 11w5/dotfiles
# - Installs minimal deps (git, stow, curl, unzip)
# - Clones/updates repo to ~/dotfiles
# - Runs stow bootstrap
#
# Security posture:
#   Default install links dotfiles only. Package installs, CSV binary downloads,
#   and remote installer execution are explicit opt-ins.
#
# Options via environment or flags:
#   DOTFILES_REPO   (default: https://github.com/11w5/dotfiles.git)
#   DOTFILES_DIR    (default: $HOME/dotfiles)
#   DOTFILES_BRANCH (default: main)
#   DOTFILES_INSTALL_PACKAGES=1
#   DOTFILES_INSTALL_CSV=1
#   --dir DIR, --repo URL, --branch BR   (override vars)

REPO_URL=${DOTFILES_REPO:-https://github.com/11w5/dotfiles.git}
TARGET_DIR=${DOTFILES_DIR:-$HOME/dotfiles}
BRANCH=${DOTFILES_BRANCH:-main}
PROFILE=${DOTFILES_PROFILE:-}
INSTALL_PACKAGES=${DOTFILES_INSTALL_PACKAGES:-0}
INSTALL_CSV=${DOTFILES_INSTALL_CSV:-0}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

while [ $# -gt 0 ]; do
  case "$1" in
    --dir) TARGET_DIR="${2:?missing dir}"; shift 2;;
    --repo) REPO_URL="${2:?missing repo}"; shift 2;;
    --branch) BRANCH="${2:?missing branch}"; shift 2;;
    --packages|--install-packages) INSTALL_PACKAGES=1; shift;;
    --csv|--install-csv) INSTALL_CSV=1; shift;;
    --no-packages) INSTALL_PACKAGES=0; shift;;
    --no-csv) INSTALL_CSV=0; shift;;
    --profile) PROFILE="${2:?missing profile}"; shift 2;;
    *) echo "Unknown arg: $1" >&2; exit 1;;
  esac
done

log() { printf "[dotfiles-install] %s\n" "$*"; }

require_safe_inputs() {
  case "$TARGET_DIR" in
    "$HOME"|"${HOME}/"|"/"|"" )
      echo "Refusing unsafe DOTFILES_DIR: $TARGET_DIR" >&2
      exit 1
      ;;
  esac

  case "$REPO_URL" in
    https://github.com/11w5/dotfiles.git|git@github.com:11w5/dotfiles.git) : ;;
    *)
      echo "Refusing non-canonical repo URL by default: $REPO_URL" >&2
      echo "Set DOTFILES_ALLOW_ALT_REPO=1 if this is intentional." >&2
      [ "${DOTFILES_ALLOW_ALT_REPO:-0}" = "1" ] || exit 1
      ;;
  esac

  case "$BRANCH" in
    *[!A-Za-z0-9._/-]*|"") echo "Refusing unsafe branch name: $BRANCH" >&2; exit 1;;
  esac
}

detect_pm() {
  if command -v apt-get >/dev/null 2>&1; then echo apt; return; fi
  if command -v brew >/dev/null 2>&1; then echo brew; return; fi
  echo none
}

install_deps() {
  local pm; pm=$(detect_pm)
  case "$pm" in
    apt)
      command -v sudo >/dev/null 2>&1 || { log "sudo not found; skipping apt deps."; return 0; }
      sudo -n true 2>/dev/null || { log "sudo requires interaction; skipping apt deps."; return 0; }
      log "Installing deps via apt (git stow curl unzip ca-certificates)"
      sudo apt-get update -y
      sudo DEBIAN_FRONTEND=noninteractive apt-get install -y git stow curl unzip ca-certificates
      ;;
    brew)
      log "Installing deps via brew (git stow curl unzip)"
      brew update
      brew install git stow curl unzip
      ;;
    none)
      log "No apt/brew detected. Please install git, stow, curl, unzip manually. Continuing without deps install."
      ;;
  esac
}

clone_or_update() {
  if [ -d "$TARGET_DIR/.git" ]; then
    log "Updating existing repo at $TARGET_DIR"
    if [ "$(git -C "$TARGET_DIR" rev-parse --show-toplevel)" = "$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$SCRIPT_DIR")" ]; then
      log "Target is the current checkout; skipping git update."
      return 0
    fi
    if [ -n "$(git -C "$TARGET_DIR" status --porcelain)" ]; then
      echo "Refusing to update dirty repo: $TARGET_DIR" >&2
      echo "Commit/stash local changes or run scripts/bootstrap_stow.sh directly." >&2
      exit 1
    fi
    git -C "$TARGET_DIR" fetch origin "$BRANCH"
    git -C "$TARGET_DIR" checkout "$BRANCH"
    git -C "$TARGET_DIR" pull --ff-only origin "$BRANCH"
  else
    log "Cloning $REPO_URL into $TARGET_DIR"
    mkdir -p "$(dirname "$TARGET_DIR")"
    git clone --branch "$BRANCH" --depth 1 "$REPO_URL" "$TARGET_DIR"
  fi
}

run_bootstrap() {
  cd "$TARGET_DIR"
  if [ -x ./scripts/bootstrap_stow.sh ]; then
    log "Running stow bootstrap"
    if [ -n "$PROFILE" ]; then DOTFILES_PROFILE="$PROFILE" ./scripts/bootstrap_stow.sh; else ./scripts/bootstrap_stow.sh; fi
  else
    echo "No stow bootstrap script found in repo." >&2
    exit 1
  fi
}

run_installers() {
  cd "$TARGET_DIR"
  if [ "$INSTALL_PACKAGES" -eq 1 ] && [ -x ./scripts/install_packages.sh ]; then
    log "Installing package sets (apt/brew + pipx/npm/cargo)"
    if [ -n "$PROFILE" ]; then DOTFILES_PROFILE="$PROFILE" ./scripts/install_packages.sh; else ./scripts/install_packages.sh; fi
  else
    log "Skipping package sets (set DOTFILES_INSTALL_PACKAGES=1 or pass --packages)."
  fi
  if [ "$INSTALL_CSV" -eq 1 ] && [ -x ./scripts/install_csv_tools.sh ]; then
    log "Installing CSV tools"
    ./scripts/install_csv_tools.sh
  else
    log "Skipping CSV tools (set DOTFILES_INSTALL_CSV=1 or pass --csv)."
  fi
}

post_notes() {
  log "Done. Open a new shell or run: source ~/.bashrc"
  printf "\nSuggested next steps:\n"
  printf "  - zsh                     # try the zsh + starship shell\n"
  printf "  - vd data.csv              # interactive CSV browser\n"
  printf "  - csvview data.csv         # pretty CSV table\n"
  printf "  - duckdb -c \"select * from read_csv_auto('data.csv') limit 20\"\n"
  printf "  - ~/Dev/start-dev.sh myproj\n"
}

require_safe_inputs
install_deps
clone_or_update
run_bootstrap
run_installers
post_notes
