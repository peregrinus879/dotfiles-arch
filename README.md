# dotfiles-arch

Headless Arch Linux dotfiles, adapted from [Omarchy](https://github.com/basecamp/omarchy), managed with [GNU Stow](https://www.gnu.org/software/stow/).

This repo is for making a headless Arch Linux machine look and feel like Omarchy at the terminal layer, without carrying Omarchy's desktop-specific components.

If you also maintain an Arch Linux WSL environment, use `dotfiles-wsl` as a separate overlay on top of this baseline.

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

## Stow Packages

Each directory is a GNU Stow package that symlinks into `$HOME`:

```text
bash/          Shell config (.bashrc, .inputrc, .config/bash/)
btop/          System monitor config (btop.conf, themes/miasma.theme)
editorconfig/  Editor formatting rules (.editorconfig)
fastfetch/     System info config (config.jsonc)
git/           Git config (config, ignore)
nvim/          Shared Neovim config (lazyvim.json, lua/plugins/, plugin/after/)
nvim-arch/     Arch-native Neovim options (lua/config/options.lua)
starship/      Prompt config (starship.toml)
tmux/          Tmux config (tmux.conf)
yazi/          File manager config (yazi.toml, theme.toml)
```

Neovim is split so the shared config and Arch-native `options.lua` remain separate:

- `nvim/` contains shared Neovim config
- `nvim-arch/` contains the Arch-native `lua/config/options.lua`

## Setup

### 1. Prerequisites

Install the baseline packages required by these dotfiles:

```bash
sudo pacman -S --needed bash-completion bat btop eza fastfetch fd fzf gcc gum github-cli \
  jq lazygit less neovim openssh ripgrep shellcheck starship stow tmux yazi zoxide
```

Nerd Font support is needed only in the client terminal used to connect to the machine. A headless Arch host does not need a local font package installed for `tmux`, `nvim`, `yazi`, `starship`, or `fastfetch` icons to render correctly over SSH.

Optional: for preparing a compatible AMD Strix Halo host for ROCm-backed local models, see `STRIX-HALO-ROCM.md`. That guide is host-specific reference material, not part of the baseline setup below.

### 2. Neovim Base

Clone the LazyVim starter first so the shared `nvim/` package and the `nvim-arch/` overlay have a target directory to extend:

```bash
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
```

### 3. Private Git Identity

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

### 4. Clone

```bash
git clone https://github.com/peregrinus879/dotfiles-arch.git ~/path/to/dotfiles-arch
```

Or with SSH:

```bash
git clone git@github.com:peregrinus879/dotfiles-arch.git ~/path/to/dotfiles-arch
```

### 5. Prepare

Checklist before stowing:

- Required packages are installed
- LazyVim starter was cloned into `~/.config/nvim`
- `~/.config/git/config.local` exists with your local Git identity
- Any existing conflicting dotfiles were removed

Remove existing files that would conflict with stow:

```bash
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
rm -f ~/.config/nvim/plugin/after/transparency.lua
```

### 6. Stow

Create symlinks for all packages:

```bash
cd ~/path/to/dotfiles-arch
stow -v -t ~ bash btop editorconfig fastfetch git nvim nvim-arch starship tmux yazi
```

Start a new terminal session, or run `source ~/.bashrc`, for the shell config to take effect.

### Unstow

```bash
cd ~/path/to/dotfiles-arch
stow -D -v -t ~ bash btop editorconfig fastfetch git nvim nvim-arch starship tmux yazi
```

### Dry Run

Preview what stow would do without making changes:

```bash
cd ~/path/to/dotfiles-arch
stow -v -n -t ~ bash btop editorconfig fastfetch git nvim nvim-arch starship tmux yazi
```

### 7. Neovim Plugins

Open Neovim once to trigger plugin installation:

```bash
nvim
```

## References

- `README.md` - repo scope, package ownership, and setup
- `APPROACH.md` - design rationale and deviations from Omarchy
- `STRIX-HALO-ROCM.md` - hardware-specific reference guide for ROCm-backed local models on compatible Strix Halo hosts
- `AGENTS.md` - canonical repo-specific assistant context
- `CLAUDE.md` - thin Claude Code wrapper importing `AGENTS.md`

## Related Repos

Clone these locally if you plan to use `/synchronize` or compare this baseline against upstream references.

- `~/projects/repos/references/omarchy` - upstream Omarchy reference repo
- `~/projects/repos/references/omarchy-pkgs` - upstream package reference repo
- `~/projects/repos/references/miasma.nvim` - Miasma theme reference repo
- `~/projects/repos/references/yazi` - Yazi reference repo
- `~/projects/repos/dotfiles/dotfiles-wsl` - optional WSL overlay built on top of this baseline

## Credits

Adapted from [Omarchy](https://github.com/basecamp/omarchy). See [APPROACH.md](APPROACH.md) for methodology and deviations.

## License

[MIT](LICENSE)
