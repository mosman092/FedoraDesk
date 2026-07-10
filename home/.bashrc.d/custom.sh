# Personal bash config for Fedora Sericea (Atomic / Sway). Sourced by the stock
# ~/.bashrc via ~/.bashrc.d/*, so it coexists with dev.sh and /etc/bashrc.

# ── functions (safe in any shell) ────────────────────────────────────────────

# clear screen + scrollback
cls() { printf '\033c\033[3J'; }

# system info via fastfetch
info() {
  if command -v fastfetch >/dev/null; then fastfetch "$@"
  else echo "fastfetch not installed (it's layered by install.sh / 'pkg install fastfetch')."; fi
}

# host packages (rpm-ostree) — verb wrapper, Atomic-aware
pkg() {
  case "${1:-status}" in
    install) sudo rpm-ostree install "${@:2}" ;;
    remove)  sudo rpm-ostree uninstall "${@:2}" ;;
    update)  sudo rpm-ostree upgrade ;;
    status)  rpm-ostree status ;;
    info)    rpm -qi "${@:2}" ;;
    clean)   clean ;;
    *)       rpm-ostree "$@" ;;
  esac
}

# flatpak apps — verb wrapper
fp() {
  case "${1:-list}" in
    search)  flatpak search "${@:2}" ;;
    install) flatpak install --user flathub "${@:2}" ;;
    remove)  flatpak uninstall --user "${@:2}" ;;
    update)  flatpak update ;;
    list)    flatpak list --app ;;
    info)    flatpak info "${@:2}" ;;
    *)       flatpak "$@" ;;
  esac
}

# Fedora Atomic deep clean — asks y/n before EACH step (Enter = yes, n = skip)
clean() {
  sudo -v || return 1
  local _r m
  _step() { echo; echo -en "\033[1;34m$1\033[0m  [Y/n] "; read -r _r; [[ -z "$_r" || "$_r" =~ ^[Yy] ]]; }
  # real btrfs on Atomic is mounted at /sysroot; a plain install uses /
  _btrfs() { local x; for x in /sysroot /; do findmnt -no FSTYPE "$x" 2>/dev/null | grep -q btrfs && { echo "$x"; return 0; }; done; return 1; }

  if _step "[1/8] rpm-ostree cleanup (old base + metadata cruft)?"; then
    sudo rpm-ostree cleanup -bm
  fi

  if _step "[2/8] Remove unused Flatpak runtimes?"; then
    flatpak uninstall --user --unused -y 2>/dev/null
    flatpak uninstall --unused -y 2>/dev/null
  fi

  if _step "[3/8] Wipe ALL of ~/.cache?"; then
    find ~/.cache -mindepth 1 -delete 2>/dev/null
  fi

  if _step "[4/8] Vacuum systemd journals (>1 week / >50M)?"; then
    sudo journalctl --vacuum-time=1weeks --vacuum-size=50M
  fi

  if _step "[5/8] Empty trash?"; then
    gio trash --empty 2>/dev/null || rm -rf ~/.local/share/Trash/* 2>/dev/null
  fi

  if _step "[6/8] Btrfs balance (reclaim mostly-empty chunks)?"; then
    m=$(_btrfs) && sudo btrfs balance start -dusage=5 -musage=5 "$m" || echo "  not btrfs — skipped."
  fi

  if _step "[7/8] Btrfs scrub (integrity check)?"; then
    m=$(_btrfs) && sudo btrfs scrub start -B "$m" || echo "  not btrfs — skipped."
  fi

  if _step "[8/8] Trim SSD partitions?"; then
    sudo fstrim -va
  fi

  echo -e "\n\033[1;32mDone — system is lean.\033[0m"
}

# ── interactive-only bits ────────────────────────────────────────────────────
if [[ $- == *i* ]]; then
  shopt -s autocd histappend checkwinsize
  HISTCONTROL=ignoreboth
  HISTSIZE=10000
  HISTFILESIZE=20000

  # aliases
  alias ..='cd ..'  ...='cd ../..'  .3='cd ../../..'
  alias cp='cp -i'  mv='mv -i'  rm='rm -i'
  alias ls='ls --color=auto'  grep='grep --color=auto'
  alias ll='ls -alF'  la='ls -A'  l='ls -CF'
  alias tb='toolbox enter'

  # prompt: cwd + git branch (no external theme)
  _gitbranch() { git branch --show-current 2>/dev/null | sed 's/.*/ (&)/'; }
  PS1='\[\e[1;34m\]\w\[\e[0;35m\]$(_gitbranch)\[\e[0m\] \$ '

  # greeting
  command -v fastfetch >/dev/null && fastfetch
fi
