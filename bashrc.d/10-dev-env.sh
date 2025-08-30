# Friendly defaults
export EDITOR=${EDITOR:-nvim}
export VISUAL=$EDITOR

# fzf keybindings and completion if available
if [ -f /usr/share/doc/fzf/examples/key-bindings.bash ]; then
  source /usr/share/doc/fzf/examples/key-bindings.bash
fi
if [ -f /usr/share/doc/fzf/examples/completion.bash ]; then
  source /usr/share/doc/fzf/examples/completion.bash
fi
if [ -f /usr/share/fzf/key-bindings.bash ]; then
  source /usr/share/fzf/key-bindings.bash
fi
if [ -f /usr/share/fzf/completion.bash ]; then
  source /usr/share/fzf/completion.bash
fi

# zoxide smart cd
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init bash)"
fi

# Prefer modern ls if present; fall back to ls
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first --icons --git'
  alias ll='eza -lah --group-directories-first --icons --git'
  alias la='eza -a --group-directories-first --icons --git'
elif command -v exa >/dev/null 2>&1; then
  alias ls='exa --group-directories-first --icons --git'
  alias ll='exa -lah --group-directories-first --icons --git'
  alias la='exa -a --group-directories-first --icons --git'
else
  alias ls='ls --color=auto -F'
  alias ll='ls -lah --color=auto'
  alias la='ls -a --color=auto'
fi

# cat with syntax highlighting
if command -v batcat >/dev/null 2>&1; then
  alias cat='batcat --paging=never'
elif command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
fi

# fd-find on Ubuntu installs as fdfind
if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
  alias fd='fdfind'
fi

# Quick helpers
mkcd() { mkdir -p "$1" && cd "$1"; }
# Fuzzy cd: list dirs, then cd
fcd() { local dir; dir=$(fd -t d -H . 2>/dev/null | fzf) && cd "$dir"; }

# Shortcuts
alias gs='git status'
alias gl='git log --oneline --graph --decorate -n 20'
alias v='${EDITOR:-nvim}'

# nnn convenience (if installed)
command -v nnn >/dev/null 2>&1 && alias n='nnn -deH'

# Dev shortcuts
alias dev='cd ~/Dev'
alias proj='cd ~/Dev/Projects'

# User bin paths
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.linuxbrew/bin:$HOME/scripts:$PATH"

# Auto-activate Python .venv when entering a directory; deactivate when leaving
_auto_venv() {
  if [ -n "$VIRTUAL_ENV" ] && [ ! -e "$PWD/.venv/bin/activate" ]; then
    deactivate 2>/dev/null || true
  elif [ -z "$VIRTUAL_ENV" ] && [ -e "$PWD/.venv/bin/activate" ]; then
    . "$PWD/.venv/bin/activate" 2>/dev/null || true
  fi
}
case ";$PROMPT_COMMAND;" in
  *"_auto_venv"*) : ;;
  *) PROMPT_COMMAND="_auto_venv; ${PROMPT_COMMAND}" ;;
 esac

# Project picker: jump to a project under ~/Dev/Projects
pp() {
  local dir
  command -v fzf >/dev/null 2>&1 || { echo "fzf not installed"; return 1; }
  command -v fd >/dev/null 2>&1 || command -v fdfind >/dev/null 2>&1 || { echo "fd/fdfind not installed"; return 1; }
  if command -v fd >/dev/null 2>&1; then
    dir=$(fd -t d -d 3 . "$HOME/Dev/Projects" 2>/dev/null | fzf)
  else
    dir=$(fdfind -t d -d 3 . "$HOME/Dev/Projects" 2>/dev/null | fzf)
  fi
  [ -n "$dir" ] && cd "$dir"
}
# uv helpers
alias uvr='uv run'
alias uva='uv add'
alias uvd='uv add --dev'
alias uvt='uv run pytest -q'

# Minimal project bootstrap helpers
mkpy() { # mkpy <name>
  [ -n "$1" ] || { echo "Usage: mkpy <name>"; return 1; }
  local dir="$HOME/Dev/Projects/$1"; mkdir -p "$dir" && cd "$dir" || return 1
  uv init . && uv venv && uv sync
}
mkjs() { # mkjs <name>
  [ -n "$1" ] || { echo "Usage: mkjs <name>"; return 1; }
  local dir="$HOME/Dev/Projects/$1"; mkdir -p "$dir" && cd "$dir" || return 1
  if command -v corepack >/dev/null 2>&1; then corepack enable >/dev/null 2>&1 || true; fi
  if command -v pnpm >/dev/null 2>&1 || corepack prepare pnpm@latest --activate >/dev/null 2>&1; then
    pnpm init -y
  else
    npm init -y
  fi
}
