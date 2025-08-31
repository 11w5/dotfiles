# Homebrew-managed extras (optional)
if command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
  # fzf keybindings/completion if installed via brew
  FZF_KB="$(brew --prefix)/opt/fzf/shell/key-bindings.bash"
  FZF_COMP="$(brew --prefix)/opt/fzf/shell/completion.bash"
  [ -f "$FZF_KB" ] && source "$FZF_KB"
  [ -f "$FZF_COMP" ] && source "$FZF_COMP"
fi
# nnn quality-of-life
export NNN_OPTS="deH"

