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
9. Creates the **`nvim` toolbox** (see [Neovim toolbox](#neovim-toolbox)).
10. Reboots.

## Neovim toolbox

The host stays lean: **Neovim lives in a `toolbox` container named `nvim`**, not layered on the base OS. `toolbox-setup.sh` creates it and installs **Neovim** plus everything LazyVim expects — `python3-neovim`, `ripgrep`, `fd`, `gcc`/`make`, `git`, `sqlite`, and **Node**/`npm` (for JS LSPs) — all inside that one container.

You never think about the container: a thin wrapper at `~/.local/bin/nvim` transparently runs Neovim **inside `nvim`**, so `nvim file.txt` from your terminal, Thunar, or a Sway keybinding all Just Work. Your `~/.config/nvim` and files are shared with the container, so it's the **same LazyVim setup editing your real files**.

- **Scope:** this container is **only for Neovim**. Want other dev tools? Make a separate toolbox — keep this one clean.
- **Why:** every host package taxes `rpm-ostree` upgrades. The toolbox is a throwaway `dnf` playground (`toolbox rm nvim` to reset) with **zero** cost to the host.
- **Node** ships inside it only because Neovim needs it for JS/TS tooling — it never touches the host.
- **Claude Code / Antigravity CLI** are self-contained binaries in `~/.local` (shared home), so they already work from **both** the host and any toolbox — no wrapper needed.
- Antigravity **IDE** is a GUI and stays on the host.

Re-run `./toolbox-setup.sh` anytime to (re)build the container.

## What's inside

| Area | Files |
|------|-------|
| **Sway** | `sway/config.d/{appearance,keybindings,outputs}.conf`, `sway/environment` |
| **Waybar** | `waybar/{config.jsonc,style.css}` — floating-islands bar |
| **Rofi** | `rofi/*.rasi` — shared design system + launcher / clipboard / emoji / keys / power menus |
| **Fonts** | `fontconfig/fonts.conf` — CJK / Thai / Bengali / Arabic / **Urdu Nastaliq** / emoji fallback |
| **Editor** | `nvim/` — LazyVim config (Neovim runs in the [`nvim` toolbox](#neovim-toolbox)) |
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

MIT — see `LICENSE`.
