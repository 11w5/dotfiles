# Friendly defaults
export EDITOR=${EDITOR:-nvim}
export VISUAL=$EDITOR

# User bin paths
case ":$PATH:" in
  *":$HOME/.local/bin:"*) : ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
case ":$PATH:" in
  *":$HOME/.cargo/bin:"*) : ;;
  *) export PATH="$HOME/.cargo/bin:$PATH" ;;
esac
case ":$PATH:" in
  *":$HOME/.linuxbrew/bin:"*) : ;;
  *) export PATH="$HOME/.linuxbrew/bin:$PATH" ;;
esac
case ":$PATH:" in
  *":$HOME/scripts:"*) : ;;
  *) export PATH="$HOME/scripts:$PATH" ;;
esac

_dot_shell_name="${ZSH_VERSION:+zsh}"
_dot_shell_name="${_dot_shell_name:-${BASH_VERSION:+bash}}"
_dot_interactive=0
case "$-" in
  *i*) [ -t 0 ] && _dot_interactive=1 ;;
esac

# fzf keybindings and completion if available
if [ "$_dot_interactive" -eq 1 ] && [ "$_dot_shell_name" = "zsh" ]; then
  for f in \
    /usr/share/doc/fzf/examples/key-bindings.zsh \
    /usr/share/fzf/key-bindings.zsh \
    "$HOME/.fzf/shell/key-bindings.zsh" \
    "${HOMEBREW_PREFIX:-}/opt/fzf/shell/key-bindings.zsh"
  do
    [ -f "$f" ] && . "$f"
  done
  for f in \
    /usr/share/doc/fzf/examples/completion.zsh \
    /usr/share/fzf/completion.zsh \
    "$HOME/.fzf/shell/completion.zsh" \
    "${HOMEBREW_PREFIX:-}/opt/fzf/shell/completion.zsh"
  do
    [ -f "$f" ] && . "$f"
  done
elif [ "$_dot_interactive" -eq 1 ]; then
  for f in \
    /usr/share/doc/fzf/examples/key-bindings.bash \
    /usr/share/fzf/key-bindings.bash \
    "$HOME/.fzf/shell/key-bindings.bash" \
    "${HOMEBREW_PREFIX:-}/opt/fzf/shell/key-bindings.bash"
  do
    [ -f "$f" ] && . "$f"
  done
  for f in \
    /usr/share/doc/fzf/examples/completion.bash \
    /usr/share/fzf/completion.bash \
    "$HOME/.fzf/shell/completion.bash" \
    "${HOMEBREW_PREFIX:-}/opt/fzf/shell/completion.bash"
  do
    [ -f "$f" ] && . "$f"
  done
fi

# zoxide smart cd
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init "$_dot_shell_name")"
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
alias dev='cd ~/dev'
alias proj='cd ${DOTFILES_PROJECTS_DIR:-$HOME/dev}'

# Cross-platform opener: o <path>
o() {
  local target=${1:-.}
  if command -v open >/dev/null 2>&1; then open "$target" 2>/dev/null || true
  elif grep -qi microsoft /proc/version 2>/dev/null && command -v wslview >/dev/null 2>&1; then wslview "$target"
  elif command -v xdg-open >/dev/null 2>&1; then xdg-open "$target" >/dev/null 2>&1 &
  elif command -v gio >/dev/null 2>&1; then gio open "$target" >/dev/null 2>&1 &
  else echo "No opener found (open/xdg-open/gio)." >&2; return 1; fi
}

# CSV quick view helper if csvview exists
csv() {
  if command -v csvview >/dev/null 2>&1; then csvview "$@"; else column -s, -t "$1" | less -S; fi
}

# Auto-activate Python .venv when entering a directory; deactivate when leaving
_auto_venv() {
  if [ -n "$VIRTUAL_ENV" ] && [ ! -e "$PWD/.venv/bin/activate" ]; then
    deactivate 2>/dev/null || true
  elif [ -z "$VIRTUAL_ENV" ] && [ -e "$PWD/.venv/bin/activate" ]; then
    . "$PWD/.venv/bin/activate" 2>/dev/null || true
  fi
}
if [ "$_dot_shell_name" = "zsh" ]; then
  autoload -Uz add-zsh-hook 2>/dev/null || true
  add-zsh-hook chpwd _auto_venv 2>/dev/null || true
  add-zsh-hook precmd _auto_venv 2>/dev/null || true
else
  case ";${PROMPT_COMMAND:-};" in
    *"_auto_venv"*) : ;;
    *) PROMPT_COMMAND="_auto_venv; ${PROMPT_COMMAND:-}" ;;
   esac
fi

# Project picker: jump to a project under ~/dev by default
pp() {
  local dir
  command -v fzf >/dev/null 2>&1 || { echo "fzf not installed"; return 1; }
  command -v fd >/dev/null 2>&1 || command -v fdfind >/dev/null 2>&1 || { echo "fd/fdfind not installed"; return 1; }
  local projects_dir="${DOTFILES_PROJECTS_DIR:-$HOME/dev}"
  if command -v fd >/dev/null 2>&1; then
    dir=$(fd -t d -d 3 . "$projects_dir" 2>/dev/null | fzf)
  else
    dir=$(fdfind -t d -d 3 . "$projects_dir" 2>/dev/null | fzf)
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
  local dir="${DOTFILES_PROJECTS_DIR:-$HOME/dev}/$1"; mkdir -p "$dir" && cd "$dir" || return 1
  uv init . && uv venv && uv sync
}
mkjs() { # mkjs <name>
  [ -n "$1" ] || { echo "Usage: mkjs <name>"; return 1; }
  local dir="${DOTFILES_PROJECTS_DIR:-$HOME/dev}/$1"; mkdir -p "$dir" && cd "$dir" || return 1
  if command -v corepack >/dev/null 2>&1; then corepack enable >/dev/null 2>&1 || true; fi
  if command -v pnpm >/dev/null 2>&1 || corepack prepare pnpm@latest --activate >/dev/null 2>&1; then
    pnpm init -y
  else
    npm init -y
  fi
}
unset _dot_shell_name _dot_interactive
