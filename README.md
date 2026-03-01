# 💻 Terminal & Development Environment Backup (Dotfiles)

A backup repository to safely store and synchronize my MacBook terminal and development environment settings.

## 🛠️ Environment & Tools

- **Terminal:** iTerm2
- **Shell:** Zsh + Oh-My-Zsh
- **Prompt Theme:** PowerLevel10k
- **Editor:** Neovim (LazyVim) & Vim
- **Multiplexer:** Tmux
- **Package Manager:** Homebrew
- **Font:** MesloLGSDZ Nerd Font (Regular, 13)

---

## 📁 Files & Directories

### 🐚 Shell & Terminal Settings
- `.zshrc` : Main Zsh configuration (Aliases, Paths, plugins, etc.)
- `.zprofile` : Zsh environment variables and system-wide initialization
- `.p10k.zsh` : PowerLevel10k prompt theme configuration
- `iTerm2 setting export 2026:03:01.itermexport` : Full backup of iTerm2 profiles, colors, and keybindings
- `.iterm2_shell_integration.zsh` : Integration script for advanced iTerm2 and shell features
- `.zcompdump*` : Zsh completion cache files (typically ignored by Git)

### 💻 Editor & Multiplexer
- `.tmux.conf` : Tmux configuration for sessions, window splits, and custom keybindings
- `.vimrc` : Basic Vim editor configuration
- `.viminfo` : Vim operation history and state log

### ⚙️ Git & Package Management
- `.gitconfig` : Global Git configuration (User info, global aliases, etc.)
- `.gitignore_global` : Global list of files and directories ignored by Git
- `brew_installed_list.txt` : Backup list of packages (Formulae/Casks) installed via Homebrew

### 🍎 MacOS Automation
- `.hammerspoon/` : Hammerspoon script directory for macOS window management and automation
