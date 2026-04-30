# Portable Zsh startup managed by ~/dotfiles.

export ZSH_DISABLE_COMPFIX=true

HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
HISTSIZE="${HISTSIZE:-50000}"
SAVEHIST="${SAVEHIST:-50000}"

setopt AUTO_CD
setopt AUTO_PUSHD
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

autoload -Uz colors compinit
colors

_zsh_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
mkdir -p "$HOME/.bashrc.d" "$_zsh_cache"
compinit -i -d "$_zsh_cache/zcompdump-${ZSH_VERSION}"
unset _zsh_cache

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Shared shell helpers live in ~/.bashrc.d and are written to be Bash/Zsh aware.
for f in "$HOME"/.bashrc.d/*.sh; do
  [ -r "$f" ] && . "$f"
done

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
else
  PROMPT='%F{green}%n@%m%f:%F{blue}%~%f %# '
fi
