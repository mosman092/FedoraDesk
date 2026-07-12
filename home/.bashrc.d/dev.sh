# Run the AI coding CLIs inside the `dev` toolbox (git/gh live there).
# Only claude + agy — `antigravity` is the GUI IDE and must launch on the host.
#
# Pass --host (or -H) as the FIRST argument to run one on the HOST instead:
#     claude --host          # Claude Code on the host, not in the toolbox
#     agy -H                 # same for the Antigravity CLI
# (--host, not --root: it changes WHERE it runs, not your privileges. -r is
#  avoided because Claude Code already uses -r/--resume.) If you're already
# inside a toolbox it runs directly too — no nested toolbox.
if command -v toolbox >/dev/null 2>&1; then
  _run_dev() {                       # <cmd> <args…>
    local cmd="$1"; shift
    if [ "${1:-}" = --host ] || [ "${1:-}" = -H ]; then
      shift; command "$cmd" "$@"     # bypass the function → run the host binary
    elif [ -f /run/.toolboxenv ]; then
      command "$cmd" "$@"            # already in a toolbox — run it here
    else
      toolbox run -c dev "$cmd" "$@"
    fi
  }
  claude() { _run_dev claude "$@"; }
  agy()    { _run_dev agy "$@"; }
fi
