# AGENTS.md - dotfiles-arch

Headless Arch baseline dotfiles adapted from [Omarchy](https://github.com/basecamp/omarchy). Omarchy, official docs, official package docs, and `DEVIATIONS.md` are the source of truth for inherited behavior and intentional differences.

## Scope

This repo carries the shared Linux baseline for terminal-first headless Arch environments.

It owns:

- shared GNU Stow packages for Bash, Git, Neovim, tmux, starship, fastfetch, btop, editorconfig, and Yazi
- shared helper logic that overlays may enable without changing baseline ownership
- baseline setup and maintenance docs

It does not own:

- WSL or Windows-specific behavior
- host-specific runbooks beyond optional reference material

## Environment

- OS: Arch Linux
- Terminal: terminal-first, headless-friendly baseline
- Dev: Tmux, Neovim (LazyVim), Bash

## Key Files

- `README.md` - stack, stow packages, setup steps
- `DEVIATIONS.md` - intentional deviations from Omarchy and baseline boundaries
- `STRIX-HALO-ROCM.md` - optional host-specific guide for ROCm-backed local models on compatible AMD Strix Halo systems
- `.claude/skills/synchronize/SKILL.md` - repo-specific sync workflow against upstream references

## Setup Invariants

- `nvim/` assumes the LazyVim starter was cloned into `~/.config/nvim` first
- Bash may load additive machine-specific overlays from `~/.config/bash-overlays/` after the shared init
- Git identity is expected in the untracked local file `~/.config/git/config.local`
- Nerd Font rendering comes from the client terminal, not the headless Arch host
- Future shared Linux changes belong here; WSL and Windows-specific changes belong in `dotfiles-wsl`

## Reference Sources

- `STRIX-HALO-ROCM.md` is optional reference material for compatible AMD Strix Halo hosts, not baseline setup required by this repo
- `/synchronize` expects local reference repos under the canonical `~/projects/repos/references/` root
- `~/projects/repos/references/omarchy` - main repo for bash, tmux, starship, git, fastfetch, btop, and editorconfig references
- `~/projects/repos/references/omarchy-pkgs` - package builds, including the Omarchy Neovim package
- `~/projects/repos/references/miasma.nvim` - Miasma color scheme source
- `~/projects/repos/references/yazi` - Yazi reference repo for configuration, theme, and feature changes

## Skills

- `/synchronize` - sync this baseline against Omarchy references

## Workflow

- Use `/synchronize` when syncing this baseline against Omarchy references
- Keep changes within the baseline scope of this repo
- Keep all intentional differences documented in `DEVIATIONS.md`
- Update `README.md`, `AGENTS.md`, and `DEVIATIONS.md` together when ownership, setup, or sync assumptions change
- Treat `STRIX-HALO-ROCM.md` as optional host guidance, not as a baseline requirement
- Put WSL and Windows-specific deviations in `dotfiles-wsl`

## Maintainer Checklist

1. Review the local reference repos and current official docs for Omarchy, GNU Stow, LazyVim, Neovim, Yazi, `btop`, and `fastfetch`.
2. Use `/synchronize` or compare the owned packages manually against the upstream references.
3. Confirm every intentional difference is still documented in `DEVIATIONS.md`.
4. Update `README.md` when package ownership, setup steps, or verification steps change.
5. Keep WSL and Windows-specific behavior in `dotfiles-wsl`.
6. Confirm the baseline assumptions still hold: LazyVim starter, `~/.config/git/config.local`, package list, and Stow targets.
7. Start a fresh shell and Neovim session after structural changes to verify the baseline still loads cleanly.
