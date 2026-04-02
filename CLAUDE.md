# dotfiles-arch

Headless Arch baseline dotfiles adapted from [Omarchy](https://github.com/basecamp/omarchy). Omarchy is the source of truth; deviate only when something breaks or does not apply in this terminal-first headless Arch baseline.

## Scope

This repo is the shared Linux baseline for terminal-first headless Arch environments.

It owns:

- shared shell and terminal configs
- shared Neovim config
- Arch-native Neovim overlay in `nvim-arch/`

It does not own:

- WSL or Windows-specific behavior

## Environment

- OS: Arch Linux
- Terminal: terminal-first, headless-friendly baseline
- Dev: Tmux, Neovim (LazyVim), Bash

## Key Files

- `README.md` - stack, stow packages, setup steps
- `APPROACH.md` - baseline methodology and deviations from Omarchy

## Stow Packages

Each top-level package is managed with GNU Stow and symlinked into `$HOME`.

- `bash/`
- `btop/`
- `editorconfig/`
- `fastfetch/`
- `git/`
- `nvim/`
- `nvim-arch/`
- `starship/`
- `tmux/`
- `yazi/`

Neovim is intentionally split:

- `nvim/` for shared config
- `nvim-arch/` for Arch-native `lua/config/options.lua`

WSL should consume `dotfiles-wsl` for its overlay instead of stowing `nvim-arch/`.

## Reference Repos

Reference repos should be cloned locally and used as sync references:

- `omarchy/` - main repo for bash, tmux, starship, git, fastfetch, btop, and editorconfig references
- `omarchy-pkgs/` - package builds, including the Omarchy Neovim package
- `miasma.nvim/` - Miasma color scheme source

## Skills

- `/synchronize` - sync this baseline against Omarchy references

## Workflow

- Use `/synchronize` when syncing this baseline against Omarchy references
- Keep changes within the baseline scope of this repo
- Put WSL and Windows-specific deviations in `dotfiles-wsl`
