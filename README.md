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
3. Layers only the **missing** packages — including `fastfetch` and **Brave Origin** — in one live `rpm-ostree` transaction.
4. Installs **Flatpaks**: Chromium, GNOME Text Editor, **LocalSend**, **Bazaar**, **Flatseal** (plus the system-wide Flathub remote and LocalSend's network/Wayland sandbox permissions).
5. Installs the self-contained CLI tools (Claude Code, Antigravity) into `~/.local`.
6. Symlinks configs + scripts, rebuilds the font cache, and sets the GTK dark theme.
7. Applies default apps / MIME / `$EDITOR` and the Firefox Urdu font pref.
8. **Hardens the firewall** (see [Security](#security)).
9. Creates the **`nvim` + `dev` toolboxes** (see [Toolboxes](#toolboxes)).
10. Reboots.

## Toolboxes

The host stays lean — dev tools live in `toolbox` containers, not layered on the base OS. `toolbox-setup.sh` creates two (idempotent; re-run anytime):

| Toolbox | Contains | Reached via |
|---------|----------|-------------|
| **`nvim`** | Neovim + LazyVim deps (`python3-neovim`, `ripgrep`, `fd`, `gcc`/`make`, `git`, `sqlite`, `node`/`npm`, `fzf`) | `~/.local/bin/nvim` wrapper |
| **`dev`** | `git` + `gh` | typing `claude` / `agy` / `antigravity` |

- **`nvim`** — the `~/.local/bin/nvim` wrapper transparently runs Neovim **inside** the container, so `nvim file.txt` from your terminal, Thunar, or a Sway keybinding all Just Work. `~/.config/nvim` and your files are shared, so it's the **same LazyVim setup editing your real files**. Node is there only for JS/TS LSPs.
- **`dev`** — `~/.bashrc.d/dev.sh` makes `claude`, `agy`, and `antigravity` run **inside `dev`**, so those AI CLIs use that container's `git`/`gh`. They're self-contained binaries in shared `~/.local`, so the same file runs on host or in the container — the wrapper just picks where.
- **Antigravity IDE** is a GUI and stays on the host.
- Each container is a throwaway `dnf` playground (`toolbox rm <name>` to reset) with **zero** cost to the host base image.

## What's inside

| Area | Files |
|------|-------|
| **Sway** | `sway/config.d/{appearance,keybindings,outputs}.conf`, `sway/environment` |
| **Waybar** | `waybar/{config.jsonc,style.css}` — floating-islands bar |
| **Rofi** | `rofi/*.rasi` — shared design system + launcher / clipboard / emoji / keys / power menus |
| **Fonts** | `fontconfig/fonts.conf` — CJK / Thai / Bengali / Arabic / **Urdu Nastaliq** / emoji fallback |
| **Editor** | `nvim/` — LazyVim config (Neovim runs in the [`nvim` toolbox](#toolboxes)) |
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
| `Super`+`Shift`+`S` | Screenshot → clipboard | `Super`+`Shift`+`T` | Toggle dark/light |
| `Super`+`N` | Toggle night light | Brightness keys | Internal + external |
| **3-finger swipe** | Switch workspaces | **4-finger swipe** | Switch windows |

Touchpad: tap-to-click, natural scroll, disable-while-typing.

## Waybar

**Left:** launcher · clock · workspaces · window title.
**Right:** theme · night light · keep-awake · clipboard · volume · mic · network · CPU/RAM · temp · backlight · battery · tray · power.

- **Volume** — left-click mute · right-click `pavucontrol` (output devices) · scroll ±2% (cap 150%).
- **Mic** — left-click mute · right-click `pavucontrol` (input devices) · scroll ±2% (cap 100%).
- **Network** click toggles Wi-Fi % ↔ live bandwidth · **CPU/RAM** open `btop` · **Battery** cycles power profile · **Brightness** click opens the monitor layout, scroll adjusts · **Theme** click toggles light/dark.

## Displays

`sway/config.d/outputs.conf` is a commented, editable per-monitor layout — set each screen's **position**, **resolution**, **scale**, and **rotation**. Use `scale` to match physical size across displays of different DPI (a 24″ 1440p and a 14″ 1080p at the same scale render the bar at different physical sizes). Click the brightness % on the bar to open it; it re-applies on save.

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
