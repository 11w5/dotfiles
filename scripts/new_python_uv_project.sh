#!/usr/bin/env bash
set -euo pipefail
name=${1:-}
[ -n "$name" ] || { echo "Usage: new_python_uv_project.sh <name>"; exit 1; }
root="$HOME/Dev/Projects/$name"
if [ -e "$root" ]; then
  echo "Path exists: $root" >&2
  exit 1
fi
mkdir -p "$root"
cd "$root"

# Initialize project with uv
uv init .

# Create virtual environment and add dev tools
uv venv
uv add --dev pytest ruff black pre-commit

# Minimal test and README
mkdir -p tests
cat > tests/test_smoke.py <<PY
def test_smoke():
    assert True
PY

# Pre-commit setup
cat > .pre-commit-config.yaml <<PC
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.6.9
    hooks:
      - id: ruff
        args: ["--fix"]
      - id: ruff-format
  - repo: https://github.com/psf/black
    rev: 24.8.0
    hooks:
      - id: black
        language_version: python3
PC

# Git ignore
cat > .gitignore <<GI
.venv/
__pycache__/
*.pyc
.env
.dist/
.build/
.coverage
htmlcov/
.DS_Store
GI

# Sync dependencies and enable pre-commit
uv sync
uv run pre-commit install

# Update README
cat > README.md <<MD
# $name

Development with uv:

- Create & sync env: `uv sync`
- Run tests: `uv run pytest`
- Add deps: `uv add <pkg>`
- Add dev deps: `uv add --dev <pkg>`
- Lint/format: `uv run ruff check .` / `uv run black .`
- Pre-commit: configured; `uv run pre-commit run -a`
MD

# Initialize git
git init -q
git add .
 git commit -q -m "chore: bootstrap $name with uv"

echo "Python (uv) project created at: $root"
