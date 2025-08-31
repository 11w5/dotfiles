#!/usr/bin/env bash
set -euo pipefail

# Installs DuckDB CLI, xsv, and a csvview helper.
# - Uses apt for visidata/csvkit if available (optional)
# - Installs to /usr/local/bin if writable (or sudo available), else ~/.local/bin

SUDO=""
if [ "${EUID:-$(id -u)}" -ne 0 ] && command -v sudo >/dev/null 2>&1; then SUDO=sudo; fi

BIN_DIR=/usr/local/bin
ADDPATH=0
if ! ( [ -w "$BIN_DIR" ] || [ -n "$SUDO" ] ); then
  BIN_DIR="$HOME/.local/bin"
  mkdir -p "$BIN_DIR"
  ADDPATH=1
fi

log() { printf '%s\n' "$*"; }

log "[1/4] Optional apt installs (visidata/csvkit)…"
if command -v apt-get >/dev/null 2>&1; then
  $SUDO apt-get update -y || true
  $SUDO apt-get install -y visidata || true
  $SUDO apt-get install -y csvkit || $SUDO apt-get install -y python3-csvkit || true
fi

log "[2/4] DuckDB CLI…"
if ! command -v duckdb >/dev/null 2>&1; then
  DUCK_BASE=$(curl -fsSLI -o /dev/null -w '%{url_effective}' https://github.com/duckdb/duckdb/releases/latest | sed 's/tag/download/')
  if curl -fL "$DUCK_BASE/duckdb_cli-linux-amd64.zip" -o /tmp/duckdb.zip || \
     curl -fL "$DUCK_BASE/duckdb_cli-linux-x86_64.zip" -o /tmp/duckdb.zip; then
    unzip -o /tmp/duckdb.zip -d /tmp >/dev/null
    $SUDO install -m 0755 /tmp/duckdb "$BIN_DIR/duckdb"
  else
    log "WARN: DuckDB download failed; skipping."
  fi
else
  log "duckdb already present: $(command -v duckdb)"
fi

log "[3/4] xsv (best-effort)…"
if ! command -v xsv >/dev/null 2>&1; then
  install_xsv() {
    local url="$1"
    log "Trying $url"
    if curl -fL "$url" -o /tmp/xsv.tar.gz; then
      tar -xzf /tmp/xsv.tar.gz -C /tmp
      local bin
      bin=$(tar -tzf /tmp/xsv.tar.gz | grep -E '/xsv$' | head -n1 | sed 's|^|/tmp/|') || true
      [ -z "$bin" ] && bin=$(find /tmp -maxdepth 2 -type f -name xsv | head -n1 || true)
      if [ -n "$bin" ] && [ -f "$bin" ]; then
        $SUDO install -m 0755 "$bin" "$BIN_DIR/xsv"
        return 0
      fi
    fi
    return 1
  }
  XSV_HTML=$(curl -fsSL https://github.com/BurntSushi/xsv/releases/latest || true)
  if [ -n "$XSV_HTML" ]; then
    XSV_PATH=$(printf "%s" "$XSV_HTML" | grep -oE '/BurntSushi/xsv/releases/download/[^"']+/xsv-[^"']+-(x86_64|amd64)-unknown-linux-(gnu|musl)\.tar\.gz' | head -n1 || true)
    [ -n "$XSV_PATH" ] && install_xsv "https://github.com$XSV_PATH" || true
  fi
  if ! command -v xsv >/dev/null 2>&1; then
    install_xsv "https://github.com/BurntSushi/xsv/releases/download/0.13.0/xsv-0.13.0-x86_64-unknown-linux-gnu.tar.gz" || \
    install_xsv "https://github.com/BurntSushi/xsv/releases/download/0.13.0/xsv-0.13.0-x86_64-unknown-linux-musl.tar.gz" || \
    log "xsv not installed (asset not reachable); csvview will fall back."
  fi
else
  log "xsv already present: $(command -v xsv)"
fi

log "[4/4] csvview helper…"
CSVVIEW="$BIN_DIR/csvview"
if [ ! -f "$CSVVIEW" ]; then
  cat > /tmp/csvview <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [ $# -eq 0 ]; then
  echo "Usage: csvview <file.csv> [xsv table options]" >&2
  exit 1
fi
if command -v xsv >/dev/null 2>&1; then
  xsv table "$@" | less -S
elif command -v csvlook >/dev/null 2>&1; then
  csvlook -I "$1" | less -S
else
  column -s, -t "$1" | less -S
fi
SH
  $SUDO install -m 0755 /tmp/csvview "$CSVVIEW"
else
  log "csvview already exists: $CSVVIEW"
fi

if [ "$ADDPATH" -eq 1 ]; then
  if ! printf '%s' ":$PATH:" | grep -q ":$HOME/.local/bin:"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    log "Added ~/.local/bin to PATH. Restart shell or run: export PATH=\"$HOME/.local/bin:$PATH\""
  fi
fi

echo
echo "Versions:"
command -v duckdb >/dev/null 2>&1 && duckdb -c "select 'duckdb ok' as ok" || echo "duckdb: MISSING"
command -v xsv    >/dev/null 2>&1 && xsv --version || echo "xsv: not installed (fallback active)"
command -v vd     >/dev/null 2>&1 && vd --version  || echo "visidata: try 'vd --version'"

