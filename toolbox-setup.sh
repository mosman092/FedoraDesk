#!/usr/bin/env bash
# Create the dev toolbox (git/gh/vim) where claude/agy run. Idempotent.
set -euo pipefail

say()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }

command -v toolbox >/dev/null || { warn "toolbox not installed."; exit 1; }

setup() {
  local name="$1"; shift
  podman container exists "$name" 2>/dev/null || { say "Creating '$name' toolbox…"; toolbox create -y "$name"; }
  say "Installing into '$name': $*"
  toolbox run -c "$name" sudo dnf install -y "$@" || warn "some packages failed in '$name' — re-run to retry."
}

setup dev git gh vim-enhanced wl-clipboard wtype

say "Done. Type claude/agy to run them in 'dev'."
