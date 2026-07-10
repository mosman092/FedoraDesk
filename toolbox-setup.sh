#!/usr/bin/env bash
# Create the toolboxes and install their tools. Idempotent.
#   nvim — Neovim + LazyVim deps (run via ~/.local/bin/nvim)
#   dev  — git + gh; claude/agy/antigravity run here (via ~/.bashrc.d/dev.sh)
set -euo pipefail

say()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }

command -v toolbox >/dev/null || { warn "toolbox not installed."; exit 1; }

setup() {  # <name> <packages…>
  local name="$1"; shift
  podman container exists "$name" 2>/dev/null || { say "Creating '$name' toolbox…"; toolbox create -y "$name"; }
  say "Installing into '$name': $*"
  toolbox run -c "$name" sudo dnf install -y "$@" || warn "some packages failed in '$name' — re-run to retry."
}

setup nvim neovim python3-neovim nodejs npm fzf ripgrep fd-find sqlite gcc make git unzip
setup dev  git gh

say "Done. 'nvim' runs Neovim; type claude/agy/antigravity to run them in 'dev'."
