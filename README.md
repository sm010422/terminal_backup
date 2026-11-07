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
- `tmux/scripts/agent-dot.sh` : Prints a per-window Claude Code agent status mark for the tmux window tabs (red `✕` error > purple `?` waiting > green `●` idle > teal `●` subagent > blue `●` executing > orange `●` thinking > grey `●` compacting), read from tmux-agent-sidebar's `@pane_status` / `@pane_subagents` and `@pane_phase`
- `tmux/scripts/agent-phase.sh` : Claude Code hook that writes the running agent's phase (`thinking` / `executing` / `compacting`) to the tmux pane option `@pane_phase`; wired up in `claude/settings.json` (PreToolUse, PostToolUse, UserPromptSubmit, SessionStart, PreCompact)
- Restore the scripts: `mkdir -p ~/.tmux/scripts && cp tmux/scripts/*.sh ~/.tmux/scripts/ && chmod +x ~/.tmux/scripts/*.sh`
- `tmux/scripts/active-tab-shape.sh` : Switches the active window tab's end caps at runtime to try other Nerd Font shapes (`notch`, `arrow`, `round`, `triangle`, `pixel`, `wave`, ...). The chosen default (rounded) lives in `.tmux.conf` as `@active_cap_l` / `@active_cap_r`; run `tmux source ~/.tmux.conf` to go back to it
- `tmux/scripts/sidebar-all.sh` : Wraps tmux-agent-sidebar's `prefix + E` (toggle in all windows) and remembers the state, so new windows open a sidebar only while that mode is on (the plugin's `@sidebar_auto_create` is turned off in `.tmux.conf`)
- `.vimrc` : Basic Vim editor configuration
- `.viminfo` : Vim operation history and state log

### ⚙️ Git & Package Management
- `.gitconfig` : Global Git configuration (User info, global aliases, etc.)
- `.gitignore_global` : Global list of files and directories ignored by Git
- `brew_installed_list.txt` : Backup list of packages (Formulae/Casks) installed via Homebrew

### 🍎 MacOS Automation
- `.hammerspoon/` : Hammerspoon script directory for macOS window management and automation
- `macos/dock.sh` : Restores Dock settings (icon size 35, auto-hide, size locked against mouse resizing). Run `./macos/dock.sh`

### 🤖 Claude Code
- `claude/settings.json` : User settings from `~/.claude/settings.json` (hooks, enabled plugins, marketplaces, TUI). The auto-generated `autoMode` block is stripped because it embeds local paths.
- `claude/CLAUDE.md` : Global instructions for all projects
- `claude/hooks/kg-sync.sh` : SessionEnd hook that syncs durable facts from each session into the personal-kg MCP server (runs a headless `claude -p` detached from tmux)

Restore:
```sh
mkdir -p ~/.claude/hooks
cp claude/settings.json claude/CLAUDE.md ~/.claude/
cp claude/hooks/kg-sync.sh ~/.claude/hooks/ && chmod +x ~/.claude/hooks/kg-sync.sh
```
Hooks installed by other tools (`hooks/gitnexus/`, `hooks/herdr-agent-state.sh`) and plugins are not backed up; reinstall GitNexus, herdr, and the plugins listed in `enabledPlugins` (tmux-agent-sidebar: `/plugin marketplace add ~/.tmux/plugins/tmux-agent-sidebar`, then `/plugin install tmux-agent-sidebar@hiroppy`).
Session data (`projects/`, `history.jsonl`, `file-history/`, caches) is intentionally excluded: it is large and may contain private content.
