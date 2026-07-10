# Run the AI coding CLIs inside the `dev` toolbox (git/gh live there).
# Only claude + agy — `antigravity` is the GUI IDE and must launch on the host.
if command -v toolbox >/dev/null 2>&1; then
  for _c in claude agy; do
    eval "${_c}(){ toolbox run -c dev ${_c} \"\$@\"; }"
  done
  unset _c
fi
