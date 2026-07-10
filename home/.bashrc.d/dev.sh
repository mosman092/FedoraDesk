# Run the AI coding CLIs inside the `dev` toolbox (git/gh live there).
if command -v toolbox >/dev/null 2>&1; then
  for _c in claude agy antigravity; do
    eval "${_c}(){ toolbox run -c dev ${_c} \"\$@\"; }"
  done
  unset _c
fi
