# Dotfiles

Net: this is a small, security-first terminal setup for Bash/Zsh, tmux,
Neovim, Git, Starship, Ranger, and a few project helpers.

The important constraint is simple: this repo is public configuration only.
No secrets, no private keys, no local machine inventory, and no tracked personal
identity.

## Security Model

1. `stow/` is the only canonical dotfile tree.
2. `~/.gitconfig.local` owns private Git identity.
3. Remote package installers are off by default.
4. Generated local files stay out of git.
5. SSH setup prefers an existing agent-backed key and will not create an empty
   passphrase key.

Read [SECURITY.md](SECURITY.md) before adding new machine-specific config.

## Install

Manual install is the default path:

```bash
git clone https://github.com/11w5/dotfiles.git ~/dotfiles
cd ~/dotfiles
./scripts/bootstrap_stow.sh
```

The remote installer is intentionally conservative. It bootstraps links only:

```bash
curl -fsSL https://raw.githubusercontent.com/11w5/dotfiles/main/install.sh | bash
```

Opt into package installs explicitly:

```bash
DOTFILES_INSTALL_PACKAGES=1 ./install.sh
DOTFILES_INSTALL_CSV=1 ./install.sh
```

Remote language/package installers stay blocked unless you also set:

```bash
DOTFILES_ALLOW_REMOTE_INSTALLERS=1
```

Neovim will not clone `lazy.nvim` on first launch unless you allow that one-time
bootstrap:

```bash
DOTFILES_NVIM_BOOTSTRAP=1 nvim
```

Unverified GitHub binary downloads for DuckDB/xsv stay blocked unless you set:

```bash
DOTFILES_ALLOW_UNVERIFIED_DOWNLOADS=1
```

## Local Git Identity

Create `~/.gitconfig.local`:

```ini
[user]
    name = Your Name
    email = you@example.com
```

Use `.gitconfig.local.example` as the template. The real file is ignored.

## Make Targets

```bash
make bootstrap     # stow link dotfiles
make restow        # restow canonical packages
make packages      # install apt/brew packages, plus opt-in language installers
make csv           # install CSV helpers, with remote binaries opt-in
make ssh           # configure/test GitHub SSH without weak key generation
make audit         # run local security audit
make update        # ff-only pull + restow
make uninstall     # destow packages
```

## Layout

```text
stow/bash/.bashrc.d/*              -> ~/.bashrc.d/*
stow/zsh/.zshrc                    -> ~/.zshrc
stow/starship/.config/starship.toml -> ~/.config/starship.toml
stow/tmux/.tmux.conf               -> ~/.tmux.conf
stow/nvim/.config/nvim/init.lua    -> ~/.config/nvim/init.lua
stow/ranger/.config/ranger/*       -> ~/.config/ranger/*
stow/scripts/scripts/*             -> ~/scripts/*
stow/dev/Dev/start-dev.sh          -> ~/Dev/start-dev.sh
stow/editor/.editorconfig          -> ~/.editorconfig
stow/git/.gitconfig                -> ~/.gitconfig
stow/git/.gitignore_global         -> ~/.gitignore_global
```

Optional overlays can live under `stow/os-linux`, `stow/os-macos`,
`stow/os-wsl`, or `stow/host-<hostname>` when needed.

## Daily Commands

```bash
dev                 # cd ~/dev
proj                # cd ${DOTFILES_PROJECTS_DIR:-~/dev}
pp                  # fuzzy project picker
mkpy name           # uv Python project
mkjs name           # JS project through pnpm/corepack or npm
v                   # $EDITOR
o path              # open in the OS file browser
csv file.csv        # quick CSV view
~/Dev/start-dev.sh  # tmux dev session
```

## SSH

Default:

```bash
./scripts/setup_ssh_github.sh
```

That expects an existing loaded SSH key, including a 1Password-backed key.

Generate a new encrypted key only when needed:

```bash
./scripts/setup_ssh_github.sh --generate --upload
```

The script requires strict known-host checking. On a new machine, verify the
GitHub host key fingerprint before adding it to `known_hosts`.

## Audit

Run this before commits:

```bash
./scripts/security_audit.sh
```

It checks Bash syntax, optional ShellCheck output, tracked file modes, obvious
secret patterns, passphrase-less SSH generation, remote installer guards, and
duplicate script drift.
