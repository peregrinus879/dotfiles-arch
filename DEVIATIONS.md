# Deviations

## Purpose

This document records the intentional differences carried by `dotfiles-arch` relative to [Omarchy](https://github.com/basecamp/omarchy), and defines the boundary between this shared Linux baseline and environment-specific overlays.

Omarchy remains the upstream reference. `dotfiles-arch` is the baseline source of truth for shared Linux behavior in this repo family.

## Deviation Policy

Omarchy is an opinionated Arch Linux distribution targeting a full desktop environment with Hyprland, systemd user services, GUI applications, and hardware-specific integrations. This repo extracts the terminal-layer configuration that remains useful on a headless Arch machine and restructures it into GNU Stow packages.

**Guiding principles:**

- **Follow Omarchy conventions by default.** Aliases, keybindings, tmux layout ratios, and tool choices should stay close to Omarchy unless a headless or non-desktop constraint requires a change.
- **Adapt only what breaks or does not apply.** Desktop-bound behavior, GUI launchers, and hardware workflows are omitted because they do not fit a headless machine.
- **Keep `dotfiles-arch` as the baseline.** This repo should contain only shared Arch/Linux behavior. WSL-specific and Windows-specific adaptations belong in `dotfiles-wsl`.
- **Use GNU Stow for dotfile management.** Omarchy uses direct file copies and packaged assets. This repo uses symlink-based package ownership for clearer separation and reuse.
- **Single theme, no switching.** Omarchy supports many themes and hot-reload infrastructure. This repo uses Miasma only, so theme switching infrastructure is intentionally omitted.
- **Avoid AUR for the baseline.** Baseline packages should come from official Arch repos or upstream installers unless there is a concrete reason to add more complexity.

## Reference Sources

- [basecamp/omarchy](https://github.com/basecamp/omarchy) - main repo for bash, tmux, starship, git, fastfetch, btop, and editorconfig references
- [omacom-io/omarchy-pkgs](https://github.com/omacom-io/omarchy-pkgs) - package builds, including the Omarchy Neovim package
- [xero/miasma.nvim](https://github.com/xero/miasma.nvim) - Miasma color scheme source

## Intentional Deviations

### Environment target

- Headless Arch baseline, not a full Omarchy desktop.
- Desktop services, GUI launchers, display manager integration, and Hyprland-specific behavior are intentionally excluded.
- Nerd Font rendering is a client-terminal concern, not a host package concern, for machines used only over SSH or Mosh.

### Dotfile management

- GNU Stow with symlinked package ownership replaces Omarchy's file-copy and package-install model.

### Theme

- Only Miasma is configured. Omarchy's multi-theme plugin set and theme hot-reload infrastructure are omitted.

### Bash

- Config location is `~/.config/bash/` using an XDG-style layout instead of Omarchy's internal default path.
- Modular shell functions live in `~/.config/bash/functions/` and are sourced via a loop in `.bashrc`.
- Optional Bash environment overlays are sourced from `~/.config/bash-overlays/*` after the shared init so machine-specific packages can enable shared helpers without replacing baseline ownership.
- Dropped aliases: `open` (GUI-only), `d='docker'`, and `r='rails'`.
- `cx` omits Omarchy's `--allow-dangerously-skip-permissions` flag.
- `y()` is added for Yazi cd-on-exit support. Yazi is not part of Omarchy.
- `mise`-specific shell handling is omitted from the baseline.
- A shared repo auto-refresh helper is included but disabled by default. This is a personal workflow deviation from Omarchy so WSL and future Omarchy overlays can safely enable fetch plus fast-forward checks under `~/projects/repos` without changing the headless baseline behavior.

### Starship

- The prompt shows `hostname` only during SSH sessions so remote shells are visually distinct from local ones while keeping the local prompt minimal.

### Tmux dev layout

- `tdl` keeps the local split ratios from this dotfiles setup rather than mirroring Omarchy exactly: 50% editor and 50% AI in the top 85%, with a 15% bottom terminal pane.

### Neovim

- `lua/config/options.lua` lives in the shared `nvim/` package, matching Omarchy's single shared `options.lua` ownership model.
- `options.lua` keeps Omarchy's `vim.opt.relativenumber = false` baseline and loads an optional `lua/config/overlay.lua` when present so environment overlays can extend the shared config without replacing the file.
- `all-themes.lua` and `omarchy-theme-hotreload.lua` are omitted because the baseline uses Miasma only.
- Neo-tree shows dotfiles by default so the file explorer matches the baseline preference for visible dotfiles.
- `render-markdown.nvim` is added beyond Omarchy's `omarchy-nvim` baseline as a standalone plugin, using its default upstream setup for headless-safe Markdown rendering inside Neovim.
- Kept verbatim from `omarchy-nvim`: `transparency.lua`, `disable-news-alert.lua`, `snacks-animated-scrolling-off.lua`, and `vim.opt.relativenumber = false`.

### Fastfetch

- Fastfetch is rewritten for a headless terminal-first environment instead of Omarchy's desktop-oriented presentation.
- The same box-drawing structure and section layout are kept: Hardware, Software, and Uptime.
- Desktop modules are omitted: `display`, `wm`, `de`, and `wmtheme`.
- Omarchy-specific helper commands are omitted: `omarchy-version`, `omarchy-version-branch`, `omarchy-version-channel`, `omarchy-version-pkgs`, and `omarchy-theme-current`.
- `OS Age` is omitted from the baseline.
- Omarchy's ASCII logo is replaced with fastfetch's built-in small logo.
- Icon codepoints use the Material Design Icons range for broader terminal font compatibility.
- Standard modules `shell` and `os` are added.
- The baseline remains shared with WSL unless future validation shows that a clean shared config is no longer practical.

### btop

- `btop.conf` is based on the generated config format produced by current `btop`, including lowercase booleans and additional default settings.
- The intentional baseline change is `color_theme = "miasma"` instead of Omarchy's `"current"`.

### Yazi

- Added entirely. Yazi is not part of Omarchy.
- `yazi.toml` keeps the local layout and behavior choices: ratio `[2, 4, 4]`, hidden files shown, and directories sorted first.
- `theme.toml` carries the Miasma palette.
- One off-palette color, `#333333`, is kept for alternate and inactive backgrounds to create subtle separation from the base terminal background `#222222`.

## Skipped From Omarchy

- GUI and desktop components, including Hyprland, Waybar, SDDM, Plymouth, Mako, Walker, Fcitx5, and related user services
- SwayOSD, hardware drivers, Elephant widgets, and other desktop-bound integrations
- `omarchy-fish`, `omarchy-zsh`, and `omarchy-walker`
- `drives` functions such as `iso2sd` and `format-drive`
- `transcoding` functions for video and image conversion
- Hardware-focused tooling and desktop automation
- Theme switching infrastructure not needed for a single-theme setup
- Shell or app packages outside the chosen Bash plus terminal-tooling baseline

## Out Of Scope

The following do **not** belong in `dotfiles-arch` and should stay in `dotfiles-wsl` or another overlay repo:

- Windows Terminal configuration
- WSL clipboard integration using `clip.exe` and `powershell.exe`
- WSL bootstrap steps such as `/etc/wsl.conf`
- Any other Windows interoperability behavior
