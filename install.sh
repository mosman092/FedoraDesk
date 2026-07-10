#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$DOTFILES/home"

say()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }

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

# run as your user, not root — symlinks must land in your $HOME, not /root
if [ "$(id -u)" -eq 0 ]; then
  echo "Do NOT run as root. Run as your normal user: ./install.sh" >&2
  exit 1
fi
if command -v sudo >/dev/null; then
  say "Some steps need root (package layering + Brave Origin). Enter your password once:"
  sudo -v || warn "sudo not primed — you may be prompted again later."
  ( while true; do sudo -n true 2>/dev/null; sleep 50; done ) &
  _sudo_keepalive=$!
  trap 'kill "$_sudo_keepalive" 2>/dev/null || true' EXIT
fi

say "Updating the base system first…"
if command -v rpm-ostree >/dev/null; then
  sudo rpm-ostree upgrade || warn "system upgrade reported an issue — continuing."
elif command -v dnf >/dev/null; then
  sudo dnf -y upgrade || warn "system upgrade reported an issue — continuing."
fi

declare -A PKG=(
  [rofi]=rofi [waybar]=waybar [foot]=foot [dunst]=dunst [thunar]=Thunar
  [imv]=imv [mpv]=mpv [xarchiver]=xarchiver [grim]=grim [slurp]=slurp
  [grimshot]=grimshot [wl-copy]=wl-clipboard [wtype]=wtype [swaylock]=swaylock
  [swayidle]=swayidle [brightnessctl]=brightnessctl [ddcutil]=ddcutil
  [wlsunset]=wlsunset [pavucontrol]=pavucontrol [wpctl]=wireplumber
  [notify-send]=libnotify [gsettings]=glib2 [xdg-mime]=xdg-utils [btop]=btop
  [tuned-adm]=tuned [fastfetch]=fastfetch
)
# Neovim lives in the `nvim` toolbox (toolbox-setup.sh), not the host.

need=()
for cmd in "${!PKG[@]}"; do
  command -v "$cmd" >/dev/null 2>&1 || need+=("${PKG[$cmd]}")
done
# don't pipe fc-list|grep -q under pipefail: SIGPIPE => false "missing" => reinstall base fonts => txn fails
FC="$(fc-list 2>/dev/null)"
has_font(){ grep -qi "$1" <<<"$FC"; }
has_font "Font Awesome 6 Free" || need+=(fontawesome-6-free-fonts)
has_font "Noto Sans "          || need+=(google-noto-sans-vf-fonts)
has_font "Noto Serif "         || need+=(google-noto-serif-vf-fonts)
has_font "Noto Sans Mono"      || need+=(google-noto-sans-mono-vf-fonts)
has_font "Noto Color Emoji"    || need+=(google-noto-color-emoji-fonts)
has_font "Noto Sans CJK"       || need+=(google-noto-sans-cjk-fonts)
has_font "Noto Nastaliq Urdu"  || need+=(google-noto-nastaliq-urdu-fonts)
has_font "Noto Sans Bengali"   || need+=(google-noto-sans-bengali-fonts)
has_font "Noto Sans Thai"      || need+=(google-noto-sans-thai-fonts)
has_font "DejaVu Sans"         || need+=(dejavu-sans-fonts dejavu-serif-fonts)
has_font "Liberation Sans"     || need+=(liberation-sans-fonts liberation-serif-fonts liberation-mono-fonts)

if ! command -v brave-origin >/dev/null 2>&1; then
  say "Adding Brave repo (for brave-origin)…"
  if curl -fsS https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo \
       | sudo install -DTm644 /dev/stdin /etc/yum.repos.d/brave-browser.repo; then
    need+=(brave-origin)
  else
    warn "couldn't add Brave repo — skipping brave-origin"
  fi
fi

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

if command -v flatpak >/dev/null; then
  flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo \
    2>/dev/null || warn "couldn't add system-wide Flathub remote"
  say "Installing Flatpak apps (Chromium, Text Editor, LocalSend, Bazaar, Flatseal)…"
  flatpak install -y --user flathub \
    org.chromium.Chromium org.gnome.TextEditor \
    org.localsend.localsend_app io.github.kolunmi.Bazaar com.github.tchx84.Flatseal \
    || warn "Flatpak install failed."
  flatpak override --user --filesystem=home org.gnome.TextEditor 2>/dev/null || true
  flatpak override --user --share=network --socket=wayland org.localsend.localsend_app \
    2>/dev/null || true
  flatpak update -y --user 2>/dev/null || true
else
  warn "flatpak not found — skipping Flatpak apps."
fi

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
if command -v antigravity >/dev/null 2>&1; then
  say "Antigravity IDE already installed."
else
  say "Installing Antigravity IDE (tarball → ~/.local)…"
  bash "$SRC/.local/bin/install-antigravity-ide" || warn "Antigravity IDE install failed — run: install-antigravity-ide"
fi

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
command -v fc-cache >/dev/null && fc-cache -f >/dev/null 2>&1 || true

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

if command -v xdg-mime >/dev/null; then
  say "Applying default applications (MIME, keybindings, env)…"
  "$HOME/.local/bin/apply-defaults" || warn "apply-defaults reported issues (fine outside a Sway session)"
fi

[ -x "$HOME/.local/bin/apply-firefox-urdu" ] && "$HOME/.local/bin/apply-firefox-urdu" || true

say "Fonts installed:"
FC2="$(fc-list 2>/dev/null)"
for f in "Noto Sans" "Noto Serif" "Noto Sans Mono" "Noto Sans CJK" "Noto Color Emoji" \
         "Noto Nastaliq Urdu" "Noto Sans Bengali" "Noto Sans Thai" \
         "Liberation Sans" "DejaVu Sans" "Font Awesome 6 Free"; do
  grep -qi "$f" <<<"$FC2" && echo "   ✅ $f" || warn "   MISSING: $f"
done

if command -v firewall-cmd >/dev/null; then
  say "Hardening firewalld (baseline + SSH rate-limit + LocalSend)…"
  fw(){ sudo firewall-cmd "$@" >/dev/null || warn "firewall-cmd $* failed"; }

  fw --set-default-zone=public
  for svc in ssh http https; do fw --permanent --add-service="$svc"; done

  for ip in ipv4 ipv6; do
    fw --permanent --direct --add-rule "$ip" filter INPUT_direct 0 \
       -p tcp --dport 22 -m state --state NEW -m recent --set
    fw --permanent --direct --add-rule "$ip" filter INPUT_direct 1 \
       -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 30 --hitcount 6 \
       -j REJECT --reject-with tcp-reset
  done

  fw --permanent --add-port=53317/tcp
  fw --permanent --add-port=53317/udp

  fw --reload
else
  warn "firewall-cmd not found — skipping firewall hardening."
fi

# nvim toolbox: Neovim lives here, not on the host (reached via ~/.local/bin/nvim)
if command -v toolbox >/dev/null; then
  say "Setting up the 'nvim' toolbox (Neovim + LazyVim deps)…"
  bash "$DOTFILES/toolbox-setup.sh" || warn "toolbox setup failed — run ./toolbox-setup.sh later"
else
  warn "toolbox not found — skipping; the nvim wrapper won't work until the toolbox exists."
fi

say "Done — rebooting to apply everything."
warn "Press Ctrl+C within 10s to cancel and reboot yourself later."
sleep 10
sudo systemctl reboot
