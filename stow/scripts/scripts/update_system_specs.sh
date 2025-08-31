#!/usr/bin/env bash
set -euo pipefail
SPEC="$HOME/SYSTEM_SPECS.md"
cat > "$SPEC" <<'DOC'
# System Specification Snapshot

Generated: $(date -Is)
Host: $(hostname -f 2>/dev/null || hostname)
User: $(whoami)

## OS and Kernel
```
uname -a: $(uname -a)

/etc/os-release:
$(cat /etc/os-release)
```

## CPU
```
$(command -v lscpu >/dev/null 2>&1 && lscpu || grep -E "model name|cpu cores|processor" /proc/cpuinfo | sort -u)
```

## Memory
```
$(free -h)
```

## Disk and Filesystems
```
$(df -hT -x tmpfs -x devtmpfs)

lsblk:
$(lsblk -o NAME,TYPE,SIZE,FSTYPE,MOUNTPOINT)
```

## Identity and Limits
```
User: $(whoami)
UID/GID: $(id)
Groups: $(groups)
Umask: $(umask)
ulimit -a:
$(ulimit -a)
```

## Shell, PATH, Locale
```
SHELL: $SHELL
PATH: $PATH

$(locale)
```

## Time and Clock
```
$(date -Is)
$(command -v timedatectl >/dev/null 2>&1 && timedatectl)
```

## Virtualization / Container
```
$(command -v systemd-detect-virt >/dev/null 2>&1 && systemd-detect-virt)
/proc/1/cgroup:
$(cat /proc/1/cgroup)
```

## GPU / Graphics
```
$(if command -v nvidia-smi >/dev/null 2>&1; then nvidia-smi -L; else echo "nvidia-smi: not found"; fi)

lspci (graphics):
$(command -v lspci >/dev/null 2>&1 && lspci | grep -i -E "vga|3d|nvidia|amd" || echo "lspci not available")
```

## Network
```
Hostname: $(hostname -f 2>/dev/null || hostname)

Addresses:
$(ip -brief addr || ifconfig -a)

Routes:
$(ip route)

Connectivity to https://example.com:
$(command -v curl >/dev/null 2>&1 && curl -Is https://example.com | head -n1 || echo "curl not available")
```

## Developer Tools
```
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
      npm|pnpm|yarn|go|rustc|cargo|make|cmake|ninja|git|rg|docker|podman|kubectl|helm|aws|gcloud|az|pip|pipx) "$cmd" --version | head -n1 ;;
      *) "$cmd" --version | head -n1 ;;
    esac
  else
    printf "%-8s: not found\n" "$cmd"
  fi
done
)
```

## Package Managers
```
$(
for pm in apt apt-get dnf yum apk zypper brew; do
  if command -v "$pm" >/dev/null 2>&1; then
    printf "%-8s: " "$pm"; "$pm" --version 2>&1 | head -n1
  fi
done
)
```
DOC

echo "Wrote $SPEC"

