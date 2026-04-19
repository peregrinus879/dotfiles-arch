# dotfiles-arch

Headless Arch Linux dotfiles, adapted from [Omarchy](https://github.com/basecamp/omarchy), managed with [GNU Stow](https://www.gnu.org/software/stow/).

`dotfiles-arch` carries the shared Linux baseline for terminal-first Arch environments. It keeps Omarchy's terminal tooling and general feel while dropping desktop-specific components that do not apply on a headless machine.

If you also maintain Arch in WSL, use `dotfiles-wsl` as the additive WSL and Windows-specific overlay on top of this baseline.

## Repo Family

Derivation model for this repo family:

```text
AI harness configs              → dotfiles-ai
Omarchy + personal deviations   → dotfiles-omarchy
Omarchy + headless deviations   → dotfiles-arch
dotfiles-arch + WSL overlay     → dotfiles-wsl
```

- [`dotfiles-ai`](https://github.com/peregrinus879/dotfiles-ai) - AI harness configs: Claude Code and OpenCode settings, shared guidance, and commit workflow
- [`dotfiles-omarchy`](https://github.com/peregrinus879/dotfiles-omarchy) - Personal Omarchy customizations: Bash overrides, Hyprland bindings, and Yazi
- [`dotfiles-arch`](https://github.com/peregrinus879/dotfiles-arch) - Shared Arch Linux terminal baseline: Bash, Tmux, Neovim, Starship, Git, Yazi, btop, and fastfetch
- [`dotfiles-wsl`](https://github.com/peregrinus879/dotfiles-wsl) - WSL overlay for dotfiles-arch: Windows Terminal, clipboard integration, and repo auto-refresh

## Stack

- **Shell**: [Bash](https://www.gnu.org/software/bash/)
- **Prompt**: [Starship](https://github.com/starship/starship)
- **Multiplexer**: [Tmux](https://github.com/tmux/tmux)
- **Editor**: [Neovim](https://github.com/neovim/neovim) ([LazyVim](https://github.com/LazyVim/LazyVim))
- **Version Control**: [Git](https://git-scm.com/), [GitHub CLI](https://cli.github.com/), [LazyGit](https://github.com/jesseduffield/lazygit)
- **File Manager**: [Yazi](https://github.com/sxyazi/yazi), [eza](https://github.com/eza-community/eza), [zoxide](https://github.com/ajeetdsouza/zoxide)
- **Search and Preview**: [fd](https://github.com/sharkdp/fd), [fzf](https://github.com/junegunn/fzf), [bat](https://github.com/sharkdp/bat), [ripgrep](https://github.com/BurntSushi/ripgrep)
- **System Monitor**: [btop](https://github.com/aristocratos/btop)
- **System Info**: [fastfetch](https://github.com/fastfetch-cli/fastfetch)
- **Dotfile Management**: [GNU Stow](https://www.gnu.org/software/stow/)
- **Theme**: [Miasma](https://github.com/xero/miasma.nvim)

## Package Layout

Each top-level directory is a GNU Stow package that symlinks into `$HOME`:

```text
bash/          Shell config (.bashrc, .inputrc, .config/bash/)
btop/          System monitor config (btop.conf, themes/miasma.theme)
editorconfig/  Editor formatting rules (.editorconfig)
fastfetch/     System info config (config.jsonc)
git/           Git config (config, ignore)
nvim/          Shared Neovim config (lazyvim.json, lua/config/, lua/plugins/colorscheme + utilities, after/plugin/)
starship/      Prompt config (starship.toml)
tmux/          Tmux config (tmux.conf)
yazi/          File manager config (yazi.toml, theme.toml)
```

Key ownership rules:

- `nvim/` owns the shared Neovim config, including `lua/config/options.lua`
- environment-specific Neovim behavior should extend the shared config via `lua/config/overlay.lua`
- Bash supports additive machine overlays through `~/.config/bash-overlays/*`
- Bash overlay filenames should be descriptive by default; use numeric prefixes only when multiple overlay files need explicit lexicographic load ordering
- the shared Bash repo auto-refresh helper is present here but stays disabled unless an overlay enables it
  - overlays enable it by exporting `REPO_AUTO_REFRESH=1` and calling `enable_repo_auto_refresh`
  - tunable via `REPO_AUTO_REFRESH_ROOT` (default `~/projects/repos`) and `REPO_AUTO_REFRESH_INTERVAL` (default `300` seconds)

## Setup

For a bare-metal install on a new disk, work through `BACKUP.md` and `INSTALL.md` first. Those cover the pre-install capture and the dual-SSD system install that sits beneath this dotfiles layer.

### 1. Prerequisites

Install the baseline packages required by these dotfiles:

```bash
sudo pacman -S --needed base-devel bash-completion bat btop eza fastfetch fd fzf gcc git github-cli gum \
  jq lazygit less neovim openssh ripgrep shellcheck starship stow sudo tmux which yazi zoxide
```

`base-devel` is included so `makepkg` can build AUR packages.

Bootstrap `yay` from AUR so AUR packages can be installed and included in routine updates:

```bash
git clone https://aur.archlinux.org/yay.git /tmp/yay
( cd /tmp/yay && makepkg -si )
rm -rf /tmp/yay
```

The Go toolchain required to build `yay` is pulled in on demand by `makepkg -si` during the bootstrap.

Nerd Font support is needed only in the client terminal used to connect to the machine. A headless Arch host does not need a local font package installed for `tmux`, `nvim`, `yazi`, `starship`, or `fastfetch` icons to render correctly over SSH.

Optional: for preparing a compatible AMD Strix Halo host for ROCm-backed local models, see `STRIX-HALO-ROCM.md`. That guide is host-specific reference material, not part of the baseline setup below.

### 2. Clone

Recommended local layout for this repo family:

```text
~/projects/repos/dotfiles/dotfiles-arch
```

Stow can work from any clone location, but the related docs and cross-repo maintenance workflows assume this layout.

```bash
git clone https://github.com/peregrinus879/dotfiles-arch.git ~/projects/repos/dotfiles/dotfiles-arch
```

### 3. Neovim Base

Clone the LazyVim starter first so the shared `nvim/` package has a target directory to extend:

```bash
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
```

### 4. Private Git Identity

Tracked Git config intentionally excludes `[user]` identity. Create a local untracked file before using Git:

```bash
mkdir -p ~/.config/git
```

Create `~/.config/git/config.local` with your local identity:

```ini
[user]
  name = Your Name
  email = your-email@example.com
```

### 5. Prepare

Checklist before stowing:

- Required packages are installed
- `yay` is installed
- `dotfiles-arch` was cloned locally
- LazyVim starter was cloned into `~/.config/nvim`
- `~/.config/git/config.local` exists with your local Git identity
- Any existing conflicting files were removed

Remove existing files that would conflict with stow. The first block removes tree-folded directory symlinks left by a previous stow (harmless on a fresh machine). The second block removes individual config files:

```bash
# Tree-folded directory symlinks (from a previous stow)
rm -f ~/.config/bash ~/.config/btop ~/.config/fastfetch ~/.config/git \
  ~/.config/nvim/plugin ~/.config/tmux ~/.config/yazi

# Individual config files
rm -f ~/.bashrc ~/.inputrc
rm -f ~/.editorconfig
rm -f ~/.config/git/config ~/.config/git/ignore
rm -f ~/.config/starship.toml
rm -f ~/.config/tmux/tmux.conf
rm -f ~/.config/fastfetch/config.jsonc
rm -f ~/.config/btop/btop.conf ~/.config/btop/themes/miasma.theme
rm -f ~/.config/yazi/yazi.toml ~/.config/yazi/theme.toml
rm -f ~/.config/nvim/lazyvim.json
rm -f ~/.config/nvim/lua/config/options.lua
rm -f ~/.config/nvim/lua/plugins/example.lua
rm -f ~/.config/nvim/lua/plugins/colorscheme.lua
rm -f ~/.config/nvim/lua/plugins/disable-news-alert.lua
rm -f ~/.config/nvim/lua/plugins/snacks-animated-scrolling-off.lua
rm -f ~/.config/nvim/after/plugin/transparency.lua
```

### 6. Stow

Create symlinks for all packages:

```bash
cd ~/projects/repos/dotfiles/dotfiles-arch
stow -v -t ~ bash btop editorconfig fastfetch git nvim starship tmux yazi
```

Start a new terminal session, or run `source ~/.bashrc`, for the shell config to take effect.

### Unstow

```bash
cd ~/projects/repos/dotfiles/dotfiles-arch
stow -D -v -t ~ bash btop editorconfig fastfetch git nvim starship tmux yazi
```

### Dry Run

Preview what stow would do without making changes:

```bash
cd ~/projects/repos/dotfiles/dotfiles-arch
stow -v -n -t ~ bash btop editorconfig fastfetch git nvim starship tmux yazi
```

### Re-stow

To update symlinks after the repo content changes (same clone path):

```bash
cd ~/projects/repos/dotfiles/dotfiles-arch
stow -R -v -t ~ bash btop editorconfig fastfetch git nvim starship tmux yazi
```

To migrate from a different clone path, unstow from the old location first:

```bash
cd /old/clone/path
stow -D -v -t ~ bash btop editorconfig fastfetch git nvim starship tmux yazi
cd ~/projects/repos/dotfiles/dotfiles-arch
stow -v -t ~ bash btop editorconfig fastfetch git nvim starship tmux yazi
```

If the old clone is no longer available, run the full cleanup in section 5 before stowing.

### 7. First Launch

Open Neovim once to trigger plugin installation:

```bash
nvim
```

## Verify

After stowing:

- Confirm the core symlinks and local Git identity exist: `test -L ~/.bashrc && test -L ~/.config/starship.toml && test -L ~/.config/nvim/lua/config/options.lua && test -f ~/.config/git/config.local`
- Start a fresh shell and confirm Bash, Starship, and Tmux load without errors.
- Run `nvim` once and confirm plugins install successfully and Miasma loads.

## References

- `README.md` - package layout, setup, and verification
- `DEVIATIONS.md` - intentional deviations from Omarchy and boundary definitions
- `BACKUP.md` - pre-install backup runbook, run before a primary-disk wipe
- `INSTALL.md` - dual-SSD host install runbook with archinstall and secondary-disk setup
- `STRIX-HALO-ROCM.md` - hardware-specific reference guide for ROCm-backed local models on compatible Strix Halo hosts
- `AGENTS.md` - canonical repo-specific assistant context and maintainer checklist
- `CLAUDE.md` - thin Claude Code wrapper importing `AGENTS.md`

## Related Repos

Clone these locally if you plan to use `/synchronize` or compare against upstream references. The `/synchronize` skill expects reference repos under `~/projects/repos/references/`.

- `~/projects/repos/references/omarchy` - upstream Omarchy reference repo
- `~/projects/repos/references/omarchy-pkgs` - upstream package reference repo
- `~/projects/repos/references/miasma.nvim` - Miasma theme reference repo
- `~/projects/repos/references/yazi` - Yazi reference repo
- `~/projects/repos/dotfiles/dotfiles-wsl` - optional WSL overlay built on top of this baseline

## Credits

Adapted from [Omarchy](https://github.com/basecamp/omarchy). See [DEVIATIONS.md](DEVIATIONS.md) for intentional differences and boundary definitions.

## License

[MIT](LICENSE)
