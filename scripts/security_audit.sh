#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-audit.XXXXXX")"
trap 'rm -rf "$TMPDIR"' EXIT

fail=0
say() { printf '[security-audit] %s\n' "$*"; }
bad() { printf '[security-audit] FAIL: %s\n' "$*" >&2; fail=1; }

say "Checking shell syntax"
while IFS= read -r -d '' file; do
  bash -n "$file" || bad "bash syntax failed: $file"
done < <(find . -path ./.git -prune -o -type f -name '*.sh' -print0)

if command -v shellcheck >/dev/null 2>&1; then
  say "Running shellcheck"
  mapfile -d '' shell_files < <(find . -path ./.git -prune -o -type f -name '*.sh' -print0)
  if [ "${#shell_files[@]}" -gt 0 ]; then
    shellcheck -S warning "${shell_files[@]}" || bad "shellcheck reported issues"
  fi
else
  say "shellcheck not installed; skipping shellcheck"
fi

say "Checking tracked file permissions"
while IFS= read -r path; do
  mode="$(git ls-files -s -- "$path" | awk '{print $1}')"
  case "$mode" in
    100644|100755|120000) : ;;
    *) bad "unexpected git mode $mode: $path" ;;
  esac
done < <(git ls-files)

say "Checking for broad local write permissions"
while IFS= read -r -d '' file; do
  bad "tracked file is group/world writable: ${file#./}"
done < <(find . -path ./.git -prune -o -type f -perm /022 -print0)

say "Checking for high-risk secret patterns"
secret_regex='((BEGIN|END) [A-Z ]*PRIVATE KEY|password[[:space:]]*=|passwd[[:space:]]*=|api[_-]?key[[:space:]]*=|access[_-]?token[[:space:]]*=|client[_-]?secret[[:space:]]*=|AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9_]{30,})'
if command -v rg >/dev/null 2>&1; then
  secret_hits="$(rg -n -I -e "$secret_regex" -g '!.git' -g '!SECURITY.md' -g '!scripts/security_audit.sh' -g '!.gitconfig.local.example' . || true)"
else
  secret_hits="$(
    git grep -n -I -E "$secret_regex" \
      -- . ':!SECURITY.md' ':!scripts/security_audit.sh' ':!.gitconfig.local.example' || true
  )"
fi
if [ -n "$secret_hits" ]; then
  printf '%s\n' "$secret_hits" >&2
  bad "possible secret material found"
fi

say "Checking for unsafe SSH key generation"
if command -v rg >/dev/null 2>&1; then
  rg -n -I -e 'ssh-keygen .* -N ""' -g '!.git' -g '!scripts/security_audit.sh' . >"$TMPDIR/ssh-audit" 2>/dev/null || true
else
  git grep -n -I 'ssh-keygen .* -N ""' -- . ':!scripts/security_audit.sh' >"$TMPDIR/ssh-audit" 2>/dev/null || true
fi
if [ -s "$TMPDIR/ssh-audit" ]; then
  cat "$TMPDIR/ssh-audit" >&2
  bad "passphrase-less SSH key generation is not allowed"
fi

say "Checking remote installer opt-in guards"
if command -v rg >/dev/null 2>&1; then
  rg -n -I -e 'curl .*\| *(sh|bash)' -g '!.git' -g '!README.md' -g '!SECURITY.md' . | grep -v 'DOTFILES_ALLOW_REMOTE_INSTALLERS' >"$TMPDIR/curl-audit" 2>/dev/null || true
else
  git grep -n -I -E 'curl .*\| *(sh|bash)' -- . ':!README.md' ':!SECURITY.md' | grep -v 'DOTFILES_ALLOW_REMOTE_INSTALLERS' >"$TMPDIR/curl-audit" 2>/dev/null || true
fi
if [ -s "$TMPDIR/curl-audit" ]; then
  cat "$TMPDIR/curl-audit" >&2
  bad "curl-to-shell must be guarded by DOTFILES_ALLOW_REMOTE_INSTALLERS"
fi

say "Checking duplicate config drift"
drift_pairs=(
  "scripts/tmux_ide.sh:stow/scripts/scripts/tmux_ide.sh"
  "scripts/install_apt_minimal.sh:stow/scripts/scripts/install_apt_minimal.sh"
  "scripts/corepack_setup.sh:stow/scripts/scripts/corepack_setup.sh"
  "scripts/update_system_specs.sh:stow/scripts/scripts/update_system_specs.sh"
  "scripts/tmux_project.sh:stow/scripts/scripts/tmux_project.sh"
  "scripts/tmux_nvim_tree_toggle.sh:stow/scripts/scripts/tmux_nvim_tree_toggle.sh"
)
for pair in "${drift_pairs[@]}"; do
  left="${pair%%:*}"
  right="${pair#*:}"
  if [ -f "$left" ] && [ -f "$right" ] && ! cmp -s "$left" "$right"; then
    bad "duplicate files drifted: $left != $right"
  fi
done

if [ "$fail" -ne 0 ]; then
  exit 1
fi

say "OK"
