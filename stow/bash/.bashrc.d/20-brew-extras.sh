# Homebrew-managed extras (optional)
if command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
  # fzf keybindings/completion if installed via brew
  case "$-" in
    *i*)
      if [ -t 0 ]; then
        _dot_fzf_shell="bash"
        [ -n "${ZSH_VERSION:-}" ] && _dot_fzf_shell="zsh"
        FZF_KB="$(brew --prefix)/opt/fzf/shell/key-bindings.$_dot_fzf_shell"
        FZF_COMP="$(brew --prefix)/opt/fzf/shell/completion.$_dot_fzf_shell"
        [ -f "$FZF_KB" ] && . "$FZF_KB"
        [ -f "$FZF_COMP" ] && . "$FZF_COMP"
        unset _dot_fzf_shell FZF_KB FZF_COMP
      fi
      ;;
  esac
fi
# nnn quality-of-life
export NNN_OPTS="deH"
