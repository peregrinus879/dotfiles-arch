# AGENTS.md - dotfiles-arch

Headless Arch baseline dotfiles adapted from [Omarchy](https://github.com/basecamp/omarchy). Omarchy, official docs, official package docs, and `DEVIATIONS.md` are the source of truth for default behavior and intentional differences.

**This repo is frozen and reference-only.** It keeps serving the remaining headless host until that machine is retired. It receives no new features and no upstream syncs; apply fixes only when the remaining host requires them. The actively maintained successor is `dotfiles-wsl`, which carries this baseline forward as self-contained WSL Arch dotfiles.

## Scope

This repo carries the frozen terminal baseline for the remaining headless Arch host.

It owns:

- GNU Stow packages for Bash, Git, Neovim, tmux, starship, fastfetch, btop, editorconfig, and Yazi, as deployed on the remaining host
- host-specific runbooks: `BACKUP.md`, `INSTALL.md`, and `STRIX-HALO-ROCM.md`
- baseline setup and maintenance docs, kept for reference

It does not own:

- WSL or Windows-specific behavior (owned by `dotfiles-wsl`)
- any actively maintained baseline; new terminal-baseline work happens in `dotfiles-wsl`

## Environment

- OS: Arch Linux
- Terminal: terminal-first, headless-friendly baseline
- Dev: Tmux, Neovim (LazyVim), Bash

## Key Files

- `README.md` - package layout, setup, and verification
- `DEVIATIONS.md` - intentional deviations from Omarchy and boundary definitions
- `BACKUP.md` - pre-install backup runbook for a headless hub
- `INSTALL.md` - dual-SSD host install runbook with archinstall and secondary-disk setup
- `STRIX-HALO-ROCM.md` - optional host-specific guide for ROCm-backed local models on compatible AMD Strix Halo systems
- `.claude/skills/synchronize/SKILL.md` - retired sync workflow, kept for reference

## Setup Invariants

- `nvim/` assumes the LazyVim starter was cloned into `~/.config/nvim` first
- Bash may load additive machine-specific overlays from `~/.config/bash-overlays/` after the shared init
- Git identity is expected in the untracked local file `~/.config/git/config.local`
- Nerd Font rendering comes from the client terminal, not the headless Arch host

## Reference Sources

- `DEVIATIONS.md` for upstream GitHub URLs and boundary definitions
- `BACKUP.md` for the pre-install capture that runs before a primary-disk wipe
- `INSTALL.md` for the bare-metal install and dual-SSD storage layout
- `STRIX-HALO-ROCM.md` is optional host-specific guidance, not baseline setup

## Workflow

- Do not adopt new upstream changes or add features; this repo is frozen
- Apply a change only when the remaining host requires a fix, and keep it minimal
- Keep all intentional differences documented in `DEVIATIONS.md` if a fix lands
- Update `README.md`, `AGENTS.md`, and `DEVIATIONS.md` together if a fix changes ownership, setup, or documented behavior
- Direct any shared terminal-baseline improvement to `dotfiles-wsl` instead

## Maintainer Checklist

1. Confirm the change is a fix the remaining host actually needs; otherwise it belongs in `dotfiles-wsl`.
2. Keep the fix minimal and within the frozen scope.
3. Confirm every intentional difference is still documented in `DEVIATIONS.md`.
4. Update `README.md`, `BACKUP.md`, or `INSTALL.md` only if the fix invalidates documented steps.
5. Start a fresh shell and Neovim session on the host after structural changes to verify everything still loads cleanly.
