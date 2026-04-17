# AGENTS.md - dotfiles-arch

Headless Arch baseline dotfiles adapted from [Omarchy](https://github.com/basecamp/omarchy). Omarchy, official docs, official package docs, and `DEVIATIONS.md` are the source of truth for default behavior and intentional differences.

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

- `README.md` - package layout, setup, and verification
- `DEVIATIONS.md` - intentional deviations from Omarchy and boundary definitions
- `STRIX-HALO-ROCM.md` - optional host-specific guide for ROCm-backed local models on compatible AMD Strix Halo systems
- `.claude/skills/synchronize/SKILL.md` - repo-specific sync workflow against upstream references

## Setup Invariants

- `nvim/` assumes the LazyVim starter was cloned into `~/.config/nvim` first
- Bash may load additive machine-specific overlays from `~/.config/bash-overlays/` after the shared init
- Git identity is expected in the untracked local file `~/.config/git/config.local`
- Nerd Font rendering comes from the client terminal, not the headless Arch host

## Reference Sources

- `DEVIATIONS.md` for upstream GitHub URLs and boundary definitions
- `.claude/skills/synchronize/SKILL.md` for local reference repo paths and official docs
- `STRIX-HALO-ROCM.md` is optional host-specific guidance, not baseline setup

## Skills

- `/synchronize` - sync this baseline against Omarchy references

## Workflow

- Use `/synchronize` when syncing this baseline against Omarchy references
- Keep changes within the baseline scope of this repo
- Keep all intentional differences documented in `DEVIATIONS.md`
- Update `README.md`, `AGENTS.md`, and `DEVIATIONS.md` together when ownership, setup, or sync assumptions change

## Future Enhancements

- **Makefile automation**: Wrap stow/unstow/dry-run, `make verify` for symlink and syntax checks, `make clean` for README "Prepare" cleanup steps. Combined stow order across repos: dotfiles-ai, dotfiles-arch, dotfiles-wsl.
- **ShellCheck**: Makefile target or pre-commit hook covering `bash/.bashrc` and `bash/.config/bash/*`. `shellcheck` is already in the baseline package list.
- **Windows Terminal drift detection**: Script to checksum tracked `settings.json` against the deployed Windows-side file at `/mnt/c/Users/.../LocalState/settings.json`. Relevant to dotfiles-wsl as well.

## Maintainer Checklist

1. Review the local reference repos and official docs for upstream changes to owned packages.
2. Use `/synchronize` or compare manually against the upstream references.
3. Confirm every intentional difference is still documented in `DEVIATIONS.md`.
4. Update `README.md` when package ownership, setup steps, or verification steps change.
5. Confirm the setup invariants still hold: LazyVim starter, `~/.config/git/config.local`, package list, and Stow targets.
6. Start a fresh shell and Neovim session after structural changes to verify everything still loads cleanly.
