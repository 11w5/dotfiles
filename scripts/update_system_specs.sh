#!/usr/bin/env bash
set -euo pipefail
umask 077

SPEC="${DOTFILES_SYSTEM_SPECS_PATH:-$HOME/SYSTEM_SPECS.private.md}"
INCLUDE_NETWORK="${DOTFILES_SYSTEM_SPECS_INCLUDE_NETWORK:-0}"

run_or_note() {
  if command -v "$1" >/dev/null 2>&1; then
    "$@" 2>&1 || printf '%s: command failed\n' "$1"
  else
    printf '%s: not found\n' "$1"
  fi
}

{
cat <<DOC
# System Specification Snapshot

Generated: $(date -Is 2>/dev/null || date)
Host: $(hostname)
User: $(whoami)

## OS and Kernel
~~~text
uname -a: $(uname -a)

/etc/os-release:
$(cat /etc/os-release)
~~~

## CPU
~~~text
$(run_or_note lscpu || grep -E "model name|cpu cores|processor" /proc/cpuinfo | sort -u)
~~~

## Memory
~~~text
$(free -h)
~~~

## Disk and Filesystems
~~~text
$(df -hT -x tmpfs -x devtmpfs)

lsblk:
$(run_or_note lsblk -o NAME,TYPE,SIZE,FSTYPE,MOUNTPOINT)
~~~

## Identity and Limits
~~~text
User: $(whoami)
UID/GID: $(id)
Groups: $(groups)
Umask: $(umask)
ulimit -a:
$(ulimit -a)
~~~

## Shell, PATH, Locale
~~~text
SHELL: $SHELL
PATH: $PATH

$(locale)
~~~

## Time and Clock
~~~text
$(date -Is 2>/dev/null || date)
$(run_or_note timedatectl)
~~~

## Virtualization / Container
~~~text
$(run_or_note systemd-detect-virt)
/proc/1/cgroup:
$(cat /proc/1/cgroup)
~~~

## GPU / Graphics
~~~text
$(if command -v nvidia-smi >/dev/null 2>&1; then nvidia-smi -L; else echo "nvidia-smi: not found"; fi)

lspci (graphics):
$(command -v lspci >/dev/null 2>&1 && lspci | grep -i -E "vga|3d|nvidia|amd" || echo "lspci not available")
~~~
DOC

if [ "$INCLUDE_NETWORK" = "1" ]; then
cat <<DOC

## Network
~~~text
Hostname: $(hostname)

Addresses:
$(run_or_note ip -brief addr)

Routes:
$(run_or_note ip route)

Connectivity to https://example.com:
$(command -v curl >/dev/null 2>&1 && curl -Is https://example.com | head -n1 || echo "curl not available")
~~~
DOC
else
cat <<'DOC'

## Network
Network details omitted by default. Set DOTFILES_SYSTEM_SPECS_INCLUDE_NETWORK=1
when a local private snapshot really needs addresses and routes.
DOC
fi

cat <<DOC

## Developer Tools
~~~text
$(
for cmd in python3 pip pipx node npm pnpm yarn go rustc cargo java javac gcc g++ clang make cmake ninja git rg docker podman kubectl helm aws gcloud az; do
  if command -v "$cmd" >/dev/null 2>&1; then
    printf "%-8s: " "$cmd"
    case "$cmd" in
      java) "$cmd" -version 2>&1 | head -n1 ;;
      javac) "$cmd" -version 2>&1 | head -n1 ;;
      gcc|g++|clang) "$cmd" --version | head -n1 ;;
      python3) "$cmd" --version ;;
      node) "$cmd" -v ;;
      npm|pnpm|yarn|go|rustc|cargo|make|cmake|ninja|git|rg|docker|podman|kubectl|helm|aws|gcloud|az|pip|pipx) "$cmd" --version 2>&1 | head -n1 ;;
      *) "$cmd" --version 2>&1 | head -n1 ;;
    esac
  else
    printf "%-8s: not found\n" "$cmd"
  fi
done
)
~~~

## Package Managers
~~~text
$(
for pm in apt apt-get dnf yum apk zypper brew; do
  if command -v "$pm" >/dev/null 2>&1; then
    printf "%-8s: " "$pm"; "$pm" --version 2>&1 | head -n1
  fi
done
)
~~~
DOC
} > "$SPEC"

chmod 600 "$SPEC"
echo "Wrote $SPEC"
