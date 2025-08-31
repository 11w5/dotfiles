# Lightweight, interoperable shell startup for Zsh
# Reuse Bash config by sourcing ~/.bashrc.d/*.sh

# Ensure ~/.bashrc.d exists
mkdir -p "$HOME/.bashrc.d"

# Source all .bashrc.d scripts (order by name)
for f in "$HOME"/.bashrc.d/*.sh; do
  [ -r "$f" ] && . "$f"
done

# Zsh-specific niceties
autoload -Uz compinit && compinit -i
setopt HIST_IGNORE_DUPS SHARE_HISTORY

