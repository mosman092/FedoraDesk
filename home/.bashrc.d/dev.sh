if [ -f /run/.toolboxenv ] && command -v flatpak-spawn >/dev/null 2>&1; then
  export BROWSER="$HOME/.local/bin/host-open"
fi

if command -v toolbox >/dev/null 2>&1; then
  _run_dev() {
    local cmd="$1"; shift
    if [ "${1:-}" = --host ] || [ "${1:-}" = -H ]; then
      shift; command "$cmd" "$@"
    elif [ -f /run/.toolboxenv ]; then
      command "$cmd" "$@"
    else
      toolbox run -c dev "$cmd" "$@"
    fi
  }
  claude() { _run_dev claude "$@"; }
  agy()    { _run_dev agy "$@"; }
fi
