# FedoraDesk

A complete, reproducible **Sway** desktop for [Fedora Sericea](https://fedoraproject.org/atomic-desktops/sericea/) (Sway Atomic / immutable rpm-ostree), themed **Catppuccin Mocha**. Waybar, a Rofi menu system, a clipboard manager, multilingual fonts, dark-mode toggle, per-monitor layout, and a set of small helper scripts — all brought up by a single `install.sh` on a clean machine.

![theme: Catppuccin Mocha](https://img.shields.io/badge/theme-Catppuccin%20Mocha-cba6f7) ![base: Fedora Sericea](https://img.shields.io/badge/base-Fedora%20Sericea-51a2da) ![wm: Sway](https://img.shields.io/badge/wm-Sway-68a063)

## Install

```bash
git clone https://github.com/mosman092/FedoraDesk ~/dotfiles
cd ~/dotfiles
./install.sh          # run as your user (NOT with sudo); it asks for your password once
```

Then **reboot once** to settle the rpm-ostree layer.

## Symlink-managed

This repo is the **single source of truth**. `install.sh` **symlinks** every file under `home/` into `$HOME` — it does *not* copy. So after install, editing e.g. `~/.config/waybar/config.jsonc` edits the file **in this repo**, and `git commit` captures it. Existing real files are backed up to `*.bak` once before the symlink replaces them. Re-running `install.sh` is safe (idempotent).

## What `install.sh` does

1. **Refuses to run as root**, then primes `sudo` **once** (keeps it alive for the whole run).
2. **Layers only missing packages** in a single live `rpm-ostree install --apply-live` transaction — including **Brave Origin** (from Brave's repo). It never re-installs anything already in the base image.
3. Installs **Chromium** + **GNOME Text Editor** (Flatpak), and the CLI dev tools.
4. **Symlinks** all configs + scripts into `$HOME` and rebuilds the font cache.
5. Sets the **GTK dark theme** correctly.
6. Runs **`apply-defaults`** → default apps, MIME associations, app keybindings, `$EDITOR`.
7. Applies the **Firefox Urdu** font pref and reloads Sway.

## What's inside

| Area | Files |
|------|-------|
| **Sway** | `sway/config.d/{appearance,keybindings,outputs}.conf`, `sway/environment` — gaps, touchpad, gestures, per-monitor layout |
| **Waybar** | `waybar/{config.jsonc,style.css}` — "floating islands" bar |
| **Rofi** | `rofi/*.rasi` — shared design system + launcher / clipboard / emoji / keys / power menus |
| **Fonts** | `fontconfig/fonts.conf` — full CJK / Thai / Bengali / Arabic / **Urdu Nastaliq** / emoji fallback |
| **Editor** | `nvim/` — LazyVim config |
| **Apps** | `foot/foot.ini`, `dunst/dunstrc`, `ddcutil/ddcutilrc`, `default-apps.conf` |
| **Scripts** | `~/.local/bin/*` |

### Helper scripts (`~/.local/bin`)

| Script | What it does |
|--------|--------------|
| `rofi-toggle` | Wraps every menu: press again to close; only one menu open at a time |
| `clip-watch` / `clip-add` / `clip-menu` | Clipboard history (text **and** images), paste-on-select |
| `theme-toggle` / `theme-status` | Dark/light switch (GTK 2/3/4 + Qt + portal); waybar icon follows the mode |
| `nightlight-toggle` / `nightlight-status` | Warm-screen (wlsunset) toggle + waybar module |
| `power-profile` / `battery-status` | Cycle power profiles (tuned); battery module shows the active profile |
| `brightness` | Internal (brightnessctl) **and** external (ddcutil/DDC) brightness in one command |
| `power-menu` · `emoji-menu` · `keys-menu` | Power dialog · emoji picker · live keybinding cheatsheet |
| `apply-defaults` | Reads `default-apps.conf`, sets MIME + app keybindings + env (Flatpak-aware) |
| `apply-firefox-urdu` | Sets Firefox's Arabic-script font to Noto Nastaliq Urdu |
| `install-antigravity-ide` | Fetches & installs the latest Antigravity IDE tarball into `~/.local` |

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

**Left:** launcher · clock (with seconds) · workspaces · focused-window title.
**Right:** theme · night light · keep-awake · clipboard · volume · network · CPU/RAM · temp · backlight · battery · tray · power.

- **Network** click → toggle Wi-Fi % ↔ live ↑/↓ bandwidth.
- **CPU / RAM** click → open `btop`.
- **Battery** click → cycle power profile (Power Saver → Balanced → Performance); tooltip shows health + active profile.
- **Brightness** click → open the monitor-layout config in the editor; scroll → adjust brightness.
- **Theme** click → toggle light/dark; the sun/moon icon reflects the current mode.

## Displays

`sway/config.d/outputs.conf` is a commented, editable monitor layout — set each screen's **position** (left/right/up/down, with centering math), **resolution**, **scale**, and **rotation**. Click the brightness % on the bar to open it; it re-applies on save.

## Fonts & multilingual text

`fontconfig/fonts.conf` gives full fallback with correct **CJK regional disambiguation** (zh/ja/ko/zh-tw/zh-hk), **Thai**, **Bengali**, **Arabic**, **color emoji**, and **Urdu in Nastaliq** (Noto Nastaliq Urdu preferred over Naskh for Arabic-script text). Firefox needs its own pref, applied by `apply-firefox-urdu`.

## Notes & gotchas

- **GTK dark mode:** `Adwaita-dark` is *not* an installed theme on Fedora — naming it makes GTK3 apps fall back to light. The fix is the valid built-in **`Adwaita`** theme + `gtk-application-prefer-dark-theme=true`.
- **Clipboard watcher:** `clip-add` reads the new clipboard from the `wl-paste --watch` stdin and sniffs PNG magic — it never re-invokes `wl-paste` (a nested call there can deadlock the watcher).
- **Waybar icons:** Font Awesome glyphs are stored as bytes in `config.jsonc`; edit with a tool that preserves them (or regenerate with `\uXXXX` escapes).
- **External brightness:** `ddcutil` needs `i2c-dev`; its package udev rule handles this after one reboot.
- **Font detection:** package checks capture `fc-list` into a string before grepping — piping `fc-list | grep -q` under `set -o pipefail` SIGPIPEs and false-flags installed fonts.

## License

MIT — see `LICENSE`.
