# FedoraDesk

A reproducible **Sway** desktop for [Fedora Sericea](https://fedoraproject.org/atomic-desktops/sericea/) (immutable rpm-ostree), themed **Catppuccin Mocha**. A single `install.sh` takes a clean machine to a fully configured desktop — Waybar, a Rofi menu system, clipboard manager, multilingual fonts, dark-mode toggle, per-monitor layout, firewall hardening, and a set of helper scripts.

![theme: Catppuccin Mocha](https://img.shields.io/badge/theme-Catppuccin%20Mocha-cba6f7) ![base: Fedora Sericea](https://img.shields.io/badge/base-Fedora%20Sericea-51a2da) ![wm: Sway](https://img.shields.io/badge/wm-Sway-68a063)

## Install

```bash
git clone https://github.com/mosman092/FedoraDesk ~/dotfiles
cd ~/dotfiles
./install.sh          # run as your user, NOT sudo — it asks for your password once
```

The script **reboots at the end** (10s, cancellable) to settle the rpm-ostree layer. Re-running is safe and idempotent.

## How it works

This repo is the single source of truth. `install.sh` **symlinks** everything under `home/` into `$HOME` — it does not copy. So editing e.g. `~/.config/waybar/config.jsonc` edits the file *in this repo*, and `git commit` captures it. Pre-existing real files are backed up to `*.bak` once before the symlink replaces them.

## What `install.sh` does

1. Refuses to run as root; primes `sudo` once for the whole run.
2. **Updates the base system** (`rpm-ostree upgrade`).
3. Layers only the **missing** packages — including `fastfetch`, the editors **`vim`** + **`mousepad`**, and **Brave Origin** — in one `rpm-ostree` transaction (**not** live-applied; it comes up on the reboot).
4. Keeps **Firefox native** (the base-image rpm) — Brave is the daily driver, but Firefox stays for the odd test.
5. Installs a small set of **Flatpaks** (per-user Flathub only, **no** system-wide remote): Chromium, **mpv**, **LocalSend**, **Obsidian** — just the apps not packaged natively (plus the home-filesystem / network / Wayland sandbox permissions they need).
6. Installs the self-contained CLI tools (Claude Code, Antigravity) into `~/.local`.
7. Symlinks configs + scripts and writes the GTK dark theme.
8. Sets the firewall rules and the Firefox Urdu font pref.
9. Creates the **`dev` toolbox** (git · gh · vim) — see [Toolboxes](#toolboxes). The editor, **`vim`**, is layered on the host.
10. **Reboots** — packages, fonts, and defaults all take effect on the clean boot.

**Nothing is applied live.** `install.sh` lays everything down and reboots once into a consistent state — no half-applied packages, no mid-install reloads. The font cache and default-app/MIME setup run **once on the first boot** via `~/.local/bin/first-run` (hooked into Sway's startup).

## Toolboxes

The host stays lean — heavier dev tooling lives in a `toolbox` container. `toolbox-setup.sh` creates one (idempotent; re-run anytime):

| Toolbox | Contains | Reached via |
|---------|----------|-------------|
| **`dev`** | `git` + `gh` + `vim` + `wl-clipboard` + `wtype` | typing `claude` / `agy` / `codex` |

- **`dev`** — `~/.bashrc.d/dev.sh` makes the **CLIs** `claude`, `agy` (Antigravity CLI), and `codex` run **inside `dev`**, so they use that container's `git`/`gh` (and `vim` as the commit editor). `wl-clipboard` + `wtype` are installed too, so clipboard (text **and** images) and simulated typing work from inside the container over the shared Wayland socket. They're self-contained binaries in shared `~/.local`, so the same file runs on host or in the container — the wrapper just picks where.
- **Editor** — `vim` is small and dependency-free, so it's layered on the **host** directly (no toolbox, no wrapper). `vim file.txt` from your terminal, Thunar, or a Sway keybinding all Just Work.
- **`antigravity`** is the **GUI IDE** (not a CLI), launches on the **host**, and is the default `code_editor` for source files — it is *not* wrapped.
- The container is a throwaway `dnf` playground (`toolbox rm dev` to reset) with **zero** cost to the host base image.

## What's inside

| Area | Files |
|------|-------|
| **Sway** | `sway/config.d/{appearance,keybindings,outputs}.conf`, `sway/environment` |
| **Waybar** | `waybar/{config.jsonc,style.css}` — floating-islands bar |
| **Rofi** | `rofi/*.rasi` — one flat, minimal design system across launcher · clipboard · emoji · keys · power · window switcher · notification-action menus |
| **Fonts** | `fontconfig/fonts.conf` — CJK / Thai / Bengali / Arabic / **Urdu Nastaliq** / emoji fallback. **Noto Nastaliq Urdu + DejaVu** ship as `.ttf` files under `.local/share/fonts/` (symlinked, not layered — keeps them out of every `rpm-ostree` deployment); the rest come from the base image. |
| **Editors** | `vim` (terminal `EDITOR`; VS Code-style keys + `habamax` truecolor theme via `~/.vimrc`) · `mousepad` (GUI `text_editor` for plain text) · **Antigravity** (`code_editor` for source files) |
| **Apps** | `foot/foot.ini`, `dunst/dunstrc`, `ddcutil/ddcutilrc`, `default-apps.conf` |
| **Scripts** | `~/.local/bin/*` |

### Helper scripts (`~/.local/bin`)

| Script | What it does |
|--------|--------------|
| `rofi-toggle` | Wraps every menu: press again to close; only one open at a time |
| `clip-watch` · `clip-add` · `clip-menu` | Clipboard history (text **and** images), paste-on-select |
| `theme-toggle` · `theme-status` | Dark/light switch (GTK 2/3/4 + Qt + portal); bar icon follows |
| `nightlight-toggle` · `nightlight-status` | Warm-screen (wlsunset) toggle + bar module |
| `power-profile` · `battery-status` | Cycle power profiles (tuned); battery module shows the active one |
| `brightness` | Internal (brightnessctl) **and** external (ddcutil) brightness in one command |
| `power-menu` · `emoji-menu` · `keys-menu` | Power dialog · emoji picker · live keybinding cheatsheet |
| `window-menu` · `notify-menu` | Window switcher (icon + title, generic-icon fallback) · renders dunst notification actions in Rofi |
| `fan-toggle` | Toggles nbfc laptop fan control between automatic and 100% |
| `apply-defaults` | Sets MIME + app keybindings + env from `default-apps.conf` (Flatpak-aware) |
| `apply-firefox-urdu` | Sets Firefox's Arabic-script font to Noto Nastaliq Urdu |
| `install-antigravity-ide` | Fetches & installs the latest Antigravity IDE into `~/.local` |

## Keybindings

| Key | Action | Key | Action |
|-----|--------|-----|--------|
| `Super`+`D` | App launcher | `Super`+`Return` | Terminal (foot) |
| `Alt`+`Tab` | Window switcher | `Super`+`Shift`+`Return` | Browser |
| `Super`+`Q` | Close window | `Super`+`Shift`+`F` | File manager |
| `Super`+`Shift`+`V` | Clipboard history | `Super`+`.` | Emoji picker |
| `Super`+`/` | Keybinding cheatsheet | `Super`+`Escape` | Power menu |
| `Super`+`Shift`+`S` | Screenshot → Pictures + clipboard | `Super`+`Shift`+`T` | Toggle dark/light |
| `Super`+`N` | Toggle night light | Brightness keys | Internal + external |
| `Ctrl`+`Super`+`F` | Toggle fan: 100% ↔ auto | | |
| **3-finger swipe** | Switch workspaces | **4-finger swipe** | Switch windows |

Touchpad: tap-to-click, natural scroll, disable-while-typing.

## Waybar

**Left:** power · clock · workspaces · window title.
**Right:** theme · night light · keep-awake · volume · mic · network · CPU/RAM · temp · backlight · battery · tray · launcher.

- **Volume** — left-click mute · right-click `pavucontrol` (output devices) · scroll ±2% (cap 150%).
- **Mic** — left-click mute · right-click `pavucontrol` (input devices) · scroll ±2% (cap 100%).
- **Network** click toggles Wi-Fi % ↔ live bandwidth · **CPU/RAM** open `btop` · **Battery** cycles power profile · **Brightness** click opens the monitor layout, scroll adjusts · **Theme** click toggles light/dark.

## Displays

`sway/config.d/outputs.conf` is an editable per-monitor layout — set each screen's **position**, **resolution**, **scale**, and **rotation**. Use `scale` to match physical size across displays of different DPI (a 24″ 1440p and a 14″ 1080p at the same scale render the bar at different physical sizes). Click the brightness % on the bar to open it; it re-applies on save.

## Security

`install.sh` locks firewalld to a small baseline and rate-limits SSH:

- Default zone `public`; only **SSH / HTTP / HTTPS** allowed.
- **SSH brute-force protection** — more than 6 new connections in 30s from one IP are rejected with a TCP reset (IPv4 + IPv6).
- **LocalSend** port `53317` (tcp + udp) whitelisted for discovery and transfer.

Check active rules with `sudo firewall-cmd --list-all`.

## Notes

- **GTK dark mode** — use the valid `Adwaita` theme + `prefer-dark`; `Adwaita-dark` isn't an installed theme and silently falls back to light.
- **Waybar icons** — Font Awesome glyphs are stored as raw bytes; edit with a tool that preserves them (or use `\uXXXX` escapes).
- **External brightness** — `ddcutil` needs the `i2c-dev` module, which its udev rule loads after the reboot.
- **Notifications** — `dunst` is themed to match Rofi (flat, 2px corners, bottom-right above the bar); notifications carrying actions or URLs open them in Rofi via `notify-menu`.
- **Click-to-close** — Rofi menus close on `Escape`, right-click, or pressing the same shortcut again. Click-*outside*-to-close is X11-only in Rofi and does not work under Wayland.

## License

MIT License — Copyright (c) 2026 M Usman

```
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

Full text in [`LICENSE`](LICENSE).
