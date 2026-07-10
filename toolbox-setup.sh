#!/usr/bin/env bash
# Create the `nvim` toolbox with Neovim + LazyVim deps. Neovim-only; idempotent.
set -euo pipefail

say()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }

command -v toolbox >/dev/null || { warn "toolbox not installed."; exit 1; }

if ! podman container exists nvim 2>/dev/null; then
  say "Creating 'nvim' toolbox…"
  toolbox create -y nvim
else
  say "'nvim' toolbox already exists."
fi

say "Installing Neovim + LazyVim deps inside 'nvim'…"
toolbox run -c nvim sudo dnf install -y \
  neovim python3-neovim nodejs npm fzf \
  ripgrep fd-find sqlite gcc make git unzip \
  || warn "some packages failed — re-run to retry."

say "Done. Type 'nvim' on the host — it runs inside the 'nvim' toolbox."
