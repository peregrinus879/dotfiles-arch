# AGENTS.md - dotfiles-arch

Headless Arch baseline dotfiles adapted from [Omarchy](https://github.com/basecamp/omarchy). Omarchy is the upstream reference; `dotfiles-arch` is the baseline source of truth for shared Linux behavior.

## Scope

This repo is the shared Linux baseline for terminal-first headless Arch environments.

It owns:

- shared shell and terminal configs
- shared Neovim config
- shared helper logic that overlays may enable without changing baseline ownership

It does not own:

- WSL or Windows-specific behavior

## Environment

- OS: Arch Linux
- Terminal: terminal-first, headless-friendly baseline
- Dev: Tmux, Neovim (LazyVim), Bash

## Key Files

- `README.md` - stack, stow packages, setup steps
- `DEVIATIONS.md` - intentional deviations from Omarchy and baseline boundaries
- `STRIX-HALO-ROCM.md` - optional host-specific guide for ROCm-backed local models on compatible AMD Strix Halo systems
- `.claude/skills/synchronize/SKILL.md` - repo-specific sync workflow against upstream references

## Reference Docs

- `STRIX-HALO-ROCM.md` is reference material for a compatible AMD Strix Halo host, not baseline setup required by this repo
- keep hardware-specific runbooks separate from the shared baseline unless the behavior becomes owned setup in `README.md`

## Stow Packages

Each top-level package is managed with GNU Stow and symlinked into `$HOME`.

- `bash/`
- `btop/`
- `editorconfig/`
- `fastfetch/`
- `git/`
- `nvim/`
- `starship/`
- `tmux/`
- `yazi/`

Neovim shared config, including `lua/config/options.lua`, lives in `nvim/`.

WSL and other environment-specific repos should extend this baseline through overlays instead of changing ownership here.

## Setup Invariants

- `nvim/` assumes the LazyVim starter was cloned into `~/.config/nvim` first
- Bash may load additive machine-specific overlays from `~/.config/bash-overlays/` after the shared init
- Git identity is expected in the untracked local file `~/.config/git/config.local`
- Nerd Font rendering comes from the client terminal, not the headless Arch host
- Future shared Linux changes belong here; WSL and Windows-specific changes belong in `dotfiles-wsl`

## Reference Repos

Reference repos should be cloned locally and used as sync references:

- `omarchy/` - main repo for bash, tmux, starship, git, fastfetch, btop, and editorconfig references
- `omarchy-pkgs/` - package builds, including the Omarchy Neovim package
- `miasma.nvim/` - Miasma color scheme source
- `yazi/` - Yazi reference repo for configuration, theme, and feature changes

## Skills

- `/synchronize` - sync this baseline against Omarchy references

## Workflow

- Use `/synchronize` when syncing this baseline against Omarchy references
- Keep changes within the baseline scope of this repo
- Keep all intentional differences documented in `DEVIATIONS.md`
- Treat `STRIX-HALO-ROCM.md` as optional host guidance, not as a baseline requirement
- Put WSL and Windows-specific deviations in `dotfiles-wsl`
