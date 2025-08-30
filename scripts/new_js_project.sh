#!/usr/bin/env bash
set -euo pipefail
name=${1:-}
[ -n "$name" ] || { echo "Usage: new_js_project.sh <name>"; exit 1; }
root="$HOME/Dev/Projects/$name"
mkdir -p "$root"
cd "$root"
if command -v corepack >/dev/null 2>&1; then
  corepack enable >/dev/null 2>&1 || true
  if corepack prepare pnpm@latest --activate >/dev/null 2>&1; then
    pm=pnpm
  else
    pm=npm
  fi
else
  pm=npm
fi
$pm init -y

# Basic scripts
jq '.scripts += {"start":"node index.js","test":"echo \"No tests\" && exit 0"}' package.json > package.tmp.json && mv package.tmp.json package.json
[ ! -f index.js ] && echo "console.log('hello');" > index.js

cat > README.md <<MD
# $name

Using $pm:

- Install deps: `$pm install`
- Start: `$pm run start`
- Test: `$pm test`
MD

echo -e "node_modules/\n.DS_Store\n" > .gitignore

git init -q
git add .
git commit -q -m "chore: bootstrap $name ($pm)"

echo "JS project created at: $root (pm: $pm)"
