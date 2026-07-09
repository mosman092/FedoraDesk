#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  Sway desktop installer — Fedora Sericea (Sway Atomic) / immutable rpm-ostree
#
#  Symlinks the configs + scripts from this repo into $HOME, layers any missing
#  packages, sets a dark GTK theme, and wires up default applications.
#  Safe to re-run (idempotent): existing real files are backed up to *.bak once.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$DOTFILES/home"

say()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }

# Layer packages resiliently: if the repos don't have some package, DROP just
# those and retry — one bad name must not fail the whole transaction. Also falls
# back from --apply-live (live) to a reboot-required layer if live apply can't.
rpmostree_install() {
  local pkgs=("$@") out rc miss keep p
  [ "${#pkgs[@]}" -gt 0 ] || return 0
  out="$(sudo rpm-ostree install --idempotent --apply-live -y "${pkgs[@]}" 2>&1)"; rc=$?
  printf '%s\n' "$out" | grep -vE '^$' | tail -3
  if [ $rc -ne 0 ]; then
    miss="$(printf '%s\n' "$out" | grep -oiE 'not found:.*' | sed 's/[^:]*: *//' | tr ',' ' ')"
    if [ -n "${miss// }" ]; then
      warn "not in repos, skipping: $miss"
      keep=(); for p in "${pkgs[@]}"; do case " $miss " in *" $p "*) ;; *) keep+=("$p");; esac; done
      [ "${#keep[@]}" -gt 0 ] || return 0
      out="$(sudo rpm-ostree install --idempotent --apply-live -y "${keep[@]}" 2>&1)"; rc=$?
      pkgs=("${keep[@]}")
    fi
  fi
  if [ $rc -ne 0 ]; then
    warn "--apply-live failed; layering without live (reboot to finish)…"
    sudo rpm-ostree install --idempotent -y "${pkgs[@]}" || warn "layer failed — try manually: ${pkgs[*]}"
  fi
}

# ── 0. run as normal user; prime sudo ONCE ───────────────────────────────────
# Run this script as YOUR user (not `sudo ./install.sh`) — symlinks must land in
# your $HOME, not /root. sudo is used only for the steps that truly need it
# (rpm-ostree package layering + the Brave Origin installer).
if [ "$(id -u)" -eq 0 ]; then
  echo "Do NOT run as root. Run as your normal user: ./install.sh" >&2
  exit 1
fi
if command -v sudo >/dev/null; then
  say "Some steps need root (package layering + Brave Origin). Enter your password once:"
  sudo -v || warn "sudo not primed — you may be prompted again later."
  # keep the sudo timestamp fresh for the whole run (rpm-ostree can be slow)
  ( while true; do sudo -n true 2>/dev/null; sleep 50; done ) &
  _sudo_keepalive=$!
  trap 'kill "$_sudo_keepalive" 2>/dev/null || true' EXIT
fi

# ── 1. packages ──────────────────────────────────────────────────────────────
# command -> Fedora package. Only commands that are MISSING get layered, so we
# never trip on packages already provided by the base image.
declare -A PKG=(
  [rofi]=rofi [waybar]=waybar [foot]=foot [dunst]=dunst [thunar]=Thunar
  [imv]=imv [xarchiver]=xarchiver [nvim]=neovim [grim]=grim [slurp]=slurp
  [grimshot]=grimshot [wl-copy]=wl-clipboard [wtype]=wtype [swaylock]=swaylock
  [swayidle]=swayidle [brightnessctl]=brightnessctl [ddcutil]=ddcutil
  [wlsunset]=wlsunset [pavucontrol]=pavucontrol [wpctl]=wireplumber
  [notify-send]=libnotify [gsettings]=glib2 [xdg-mime]=xdg-utils [btop]=btop
  [node]=nodejs [fzf]=fzf [tuned-adm]=tuned
)
# NOTE: lazygit is NOT in Fedora repos and is intentionally left out (optional).

need=()
for cmd in "${!PKG[@]}"; do
  command -v "$cmd" >/dev/null 2>&1 || need+=("${PKG[$cmd]}")
done
command -v nvim >/dev/null 2>&1 || need+=(python3-neovim)          # nvim providers
command -v sqlite3 >/dev/null 2>&1 || need+=(sqlite)               # snacks frecency (LazyVim)
# NOTE: capture fc-list ONCE into a string and grep that — do NOT pipe
# `fc-list | grep -q` under `set -o pipefail`: grep -q exits on first match and
# closes the pipe, fc-list gets SIGPIPE, and pipefail then wrongly reports the
# font as missing (=> tries to re-install already-present base fonts => the whole
# rpm-ostree transaction fails).
FC="$(fc-list 2>/dev/null)"
has_font(){ grep -qi "$1" <<<"$FC"; }
has_font "Font Awesome 6 Free" || need+=(fontawesome-6-free-fonts)
# core Noto (Sans/Serif/Mono) — usually in base, but ensure it explicitly
has_font "Noto Sans "          || need+=(google-noto-sans-vf-fonts)
has_font "Noto Serif "         || need+=(google-noto-serif-vf-fonts)
has_font "Noto Sans Mono"      || need+=(google-noto-sans-mono-vf-fonts)
has_font "Noto Color Emoji"    || need+=(google-noto-color-emoji-fonts)
# multilingual coverage (CJK, Thai, Arabic, Bengali, Urdu-Nastaliq) + DejaVu/Liberation
has_font "Noto Sans CJK"       || need+=(google-noto-sans-cjk-fonts)
has_font "Noto Nastaliq Urdu"  || need+=(google-noto-nastaliq-urdu-fonts)
has_font "Noto Sans Bengali"   || need+=(google-noto-sans-bengali-fonts)
has_font "Noto Sans Thai"      || need+=(google-noto-sans-thai-fonts)
has_font "DejaVu Sans"         || need+=(dejavu-sans-fonts dejavu-serif-fonts)
has_font "Liberation Sans"     || need+=(liberation-sans-fonts liberation-serif-fonts liberation-mono-fonts)

# Brave Origin ships in Brave's own rpm repo — add it so `brave-origin` can go
# into the SAME transaction as everything else (one install, one live-apply).
if ! command -v brave-origin >/dev/null 2>&1; then
  say "Adding Brave repo (for brave-origin)…"
  if curl -fsS https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo \
       | sudo install -DTm644 /dev/stdin /etc/yum.repos.d/brave-browser.repo; then
    need+=(brave-origin)
  else
    warn "couldn't add Brave repo — skipping brave-origin"
  fi
fi

# ── ONE rpm-ostree transaction for ALL packages + Brave Origin, applied live ──
if [ "${#need[@]}" -gt 0 ]; then
  mapfile -t need < <(printf '%s\n' "${need[@]}" | sort -u)
  say "Layering everything in one live transaction: ${need[*]}"
  if command -v rpm-ostree >/dev/null; then
    rpmostree_install "${need[@]}"
  elif command -v dnf >/dev/null; then
    sudo dnf install -y "${need[@]}" || warn "install manually: ${need[*]}"
  else
    warn "No rpm-ostree/dnf — install manually: ${need[*]}"
  fi
else
  say "All required packages + Brave Origin already present."
fi

# ── User Flatpaks: Chromium + GNOME Text Editor (no sudo, applies live) ──
# GNOME Text Editor = the friendly GUI editor for opening files from Thunar
# (modern Ctrl+S/C/V/Z keys); nvim stays the terminal editor.
if command -v flatpak >/dev/null; then
  flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  say "Installing Chromium + GNOME Text Editor (Flatpak)…"
  flatpak install -y --user flathub org.chromium.Chromium org.gnome.TextEditor \
    || warn "Flatpak install failed."
  # let the editor read/write your home files when opened from Thunar
  flatpak override --user --filesystem=home org.gnome.TextEditor 2>/dev/null || true
else
  warn "flatpak not found — skipping Chromium / Text Editor."
fi

# lazygit (LazyVim's optional git UI, <leader>gg) is NOT in Fedora repos.
# Left out on purpose to keep nvim = pure LazyVim. To add it later, either
# `flatpak`/COPR, or grab the binary from github.com/jesseduffield/lazygit.

# ── CLI dev tools: Claude Code + Antigravity CLI (install into ~, no sudo) ──
if command -v claude >/dev/null 2>&1; then
  say "Claude Code already installed."
else
  say "Installing Claude Code…"
  curl -fsSL https://claude.ai/install.sh | bash || warn "Claude Code install failed."
fi
if command -v agy >/dev/null 2>&1 || command -v antigravity >/dev/null 2>&1; then
  say "Antigravity CLI already installed."
else
  say "Installing Antigravity CLI…"
  curl -fsSL https://antigravity.google/cli/install.sh | bash || warn "Antigravity CLI install failed."
fi
# Antigravity IDE: no official Fedora RPM — this script grabs the latest tarball.
if command -v antigravity >/dev/null 2>&1; then
  say "Antigravity IDE already installed."
else
  say "Installing Antigravity IDE (tarball → ~/.local)…"
  bash "$SRC/.local/bin/install-antigravity-ide" || warn "Antigravity IDE install failed — run: install-antigravity-ide"
fi

# ── 2. symlink dotfiles ──────────────────────────────────────────────────────
say "Linking configs + scripts into \$HOME…"
while IFS= read -r -d '' f; do
  rel="${f#"$SRC"/}"
  dst="$HOME/$rel"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "$dst.bak.$$"
    warn "backed up existing $rel -> $rel.bak.$$"
  fi
  ln -sfn "$f" "$dst"
done < <(find "$SRC" -type f -print0)
chmod +x "$HOME"/.local/bin/* 2>/dev/null || true
# rebuild font cache so the shipped fontconfig fallback takes effect
command -v fc-cache >/dev/null && fc-cache -f >/dev/null 2>&1 || true

# ── 3. GTK dark theme ────────────────────────────────────────────────────────
# GTK3 apps (Thunar) only go dark with the VALID "Adwaita" theme + prefer-dark;
# naming the non-existent "Adwaita-dark" silently falls back to light.
say "Setting GTK dark theme…"
mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0
if command -v gsettings >/dev/null; then
  gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true
  gsettings set org.gnome.desktop.interface gtk-theme Adwaita       2>/dev/null || true
fi
for v in gtk-3.0 gtk-4.0; do
  printf '[Settings]\ngtk-theme-name=Adwaita\ngtk-application-prefer-dark-theme=true\ngtk-icon-theme-name=Adwaita\n' > ~/.config/$v/settings.ini
done
printf 'gtk-theme-name="Adwaita"\n' > ~/.gtkrc-2.0

# ── 4. default apps + MIME ───────────────────────────────────────────────────
if command -v xdg-mime >/dev/null; then
  say "Applying default applications (MIME, keybindings, env)…"
  "$HOME/.local/bin/apply-defaults" || warn "apply-defaults reported issues (fine outside a Sway session)"
fi

# ── 4b. Firefox Urdu font pref (per profile; noop if Firefox never launched) ──
[ -x "$HOME/.local/bin/apply-firefox-urdu" ] && "$HOME/.local/bin/apply-firefox-urdu" || true

# ── 4c. font check: prove every requested family is actually present ─────────
say "Fonts installed:"
FC2="$(fc-list 2>/dev/null)"
for f in "Noto Sans" "Noto Serif" "Noto Sans Mono" "Noto Sans CJK" "Noto Color Emoji" \
         "Noto Nastaliq Urdu" "Noto Sans Bengali" "Noto Sans Thai" \
         "Liberation Sans" "DejaVu Sans" "Font Awesome 6 Free"; do
  grep -qi "$f" <<<"$FC2" && echo "   ✅ $f" || warn "   MISSING: $f"
done

# ── 5. reload if running ─────────────────────────────────────────────────────
if command -v swaymsg >/dev/null && swaymsg -t get_version >/dev/null 2>&1; then
  say "Reloading Sway…"
  swaymsg reload || true
fi

say "Done."
echo
warn "If packages were layered WITHOUT --apply-live, reboot to finish."
warn "External-monitor brightness (ddcutil) needs the i2c-dev module + group; the"
warn "ddcutil package ships a udev rule that handles this after one reboot."
