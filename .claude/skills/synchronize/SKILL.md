---
name: synchronize
description: Sync this headless Arch baseline against Omarchy references and official docs. Covers the shared Linux packages owned by dotfiles-arch.
---

# Synchronize Baseline

Source configs from reference repos and official docs, compare against `dotfiles-arch`, and apply changes only where they belong in the shared Arch baseline.

## Sources

### Reference Repos

Reference repos live under `~/projects/repos/references/`:

- `omarchy/` - main repo for bash, tmux, starship, git, fastfetch, btop, and editorconfig references
- `omarchy-pkgs/` - package builds, including the Omarchy Neovim package
- `miasma.nvim/` - Miasma color scheme source
- `yazi/` - Yazi reference repo for configuration, theme, and feature changes

### Official Docs

- [The Omarchy Manual](https://learn.omacom.io/2/the-omarchy-manual) - setup guides, keybindings, workflows
- [GNU Stow Manual](https://www.gnu.org/software/stow/manual/stow.html) - symlink management and package structure
- [Bash Reference Manual](https://www.gnu.org/software/bash/manual/bash.html) - builtins, expansion, scripting
- [Starship Configuration](https://starship.rs/config/) - module options and format strings
- [Tmux Wiki](https://github.com/tmux/tmux/wiki) - usage and recipes
- [LazyVim Docs](https://www.lazyvim.org/) - installation, extras, and plugin conventions
- [Neovim Docs](https://neovim.io/doc/) - options, API, and Lua reference
- [lazy.nvim Docs](https://lazy.folke.io/) - plugin manager configuration
- [Git Docs](https://git-scm.com/docs) - config options and behavior
- [Yazi Docs](https://yazi-rs.github.io/docs/) - configuration and themes
- [btop](https://github.com/aristocratos/btop) - config options and themes
- [fastfetch Wiki](https://github.com/fastfetch-cli/fastfetch/wiki) - modules and JSON config

## Workflow

1. Compare reference repos against the packages owned by `dotfiles-arch`
2. For Omarchy-derived packages, compare against `omarchy/`, `omarchy-pkgs/`, and `miasma.nvim/`
3. For non-Omarchy tools such as Yazi, compare against `yazi/` and official docs
4. For each difference, classify it:
   - **Intentional deviation**: documented in `APPROACH.md`, should stay different
   - **New upstream addition**: added in Omarchy after the last sync, should be reviewed for inclusion
   - **Upstream change to existing config**: modified in Omarchy, needs review
5. Check `git log --format="%h %ad %s" --date=short -- <file>` on the relevant reference repo when you need to determine when a difference was introduced
6. Cross-check differences against `APPROACH.md`. If a difference is not documented there, treat it as a likely upstream change that needs review
7. Apply new upstream additions and changes where they belong in the shared baseline
8. Keep WSL-specific and Windows-specific behavior out of `dotfiles-arch`
9. Update `README.md` and `APPROACH.md` when package ownership, setup steps, or documented deviations change

## Rules

- Present proposed changes to the user before editing
- Omarchy is the source of truth; deviate only when something breaks or does not apply in the shared headless Arch baseline
- Always check all relevant reference repos, not just one
- Never assume a difference is intentional without verifying it is documented in `APPROACH.md`
- Do not add WSL-specific or Windows-specific behavior to this repo
- Keep Neovim split clean: shared config in `nvim/`, Arch-native options in `nvim-arch/`
- If a change only applies to WSL, document or apply it in `dotfiles-wsl` instead
