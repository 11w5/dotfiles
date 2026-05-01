# Dotfiles Security Policy

Net: this repo is public portable configuration only. It must never become a
secret store, identity store, or machine inventory dump.

## Hard Rules

1. No secrets, tokens, passwords, private keys, cookies, or local `.env` files.
2. No private SSH keys. Public keys are allowed only when intentionally shared.
3. No machine-specific identity in tracked config. Put names, work emails, and
   signing keys in `~/.gitconfig.local`.
4. No generated host inventories, network maps, or system snapshots in git.
5. No unaudited remote installer execution by default. Scripts that download
   binaries or run third-party installers require an explicit opt-in variable.
6. `stow/` is the canonical config tree. Root-level scripts are allowed; root
   copies of dotfiles are not.
7. Installer failures should fail closed unless a step is explicitly optional.
8. Editor/plugin bootstraps that fetch code from the network must be explicit.

## Local Identity

Use a private local Git config:

```ini
[user]
    name = Your Name
    email = you@example.com
```

Save it at `~/.gitconfig.local`. That file is ignored by git.

## Before Committing

Run:

```bash
./scripts/security_audit.sh
```

The audit checks syntax, file permissions, common secret patterns, root/stow
drift, unsafe SSH defaults, and remote installer opt-in guards.
