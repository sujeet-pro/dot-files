########################################
# ~/.zshrc - Sujeet's shell configuration
########################################

########################################
# 0. Early environment / Homebrew setup
########################################

# Detect and cache the Homebrew prefix.
# This lets us reference plugin paths (zsh-autosuggestions, syntax-highlighting, etc.)
# without hardcoding /opt/homebrew or /usr/local.
if command -v brew &>/dev/null; then
  export BREW_PREFIX="${BREW_PREFIX:-$(brew --prefix)}"
else
  # Fallback for typical Apple Silicon setup (adjust if needed).
  export BREW_PREFIX="/opt/homebrew"
fi

########################################
# 1. Language & version managers
########################################

# --- Go (goenv) --------------------------------------------------------------
# goenv manages multiple Go versions in ~/.goenv.
export GOENV_ROOT="$HOME/.goenv"
# Ensure goenv's shims and binaries are before system Go in PATH.
export PATH="$GOENV_ROOT/bin:$PATH"

if command -v goenv &>/dev/null; then
  # Initialize goenv so that `go` uses the correct version per project.
  eval "$(goenv init -)"
fi

# --- Python (pyenv) ----------------------------------------------------------
# pyenv manages multiple Python versions in ~/.pyenv.
export PYENV_ROOT="$HOME/.pyenv"
# Make sure `pyenv` itself is on PATH.
export PATH="$PYENV_ROOT/bin:$PATH"

if command -v pyenv &>/dev/null; then
  # Initialize pyenv so `python`/`pip` resolve through pyenv.
  eval "$(pyenv init -)"
fi

# --- Java (SDKMAN) -----------------------------------------------------------
# SDKMAN manages multiple Java (and other JVM tools) versions under ~/.sdkman.
export SDKMAN_DIR="$HOME/.sdkman"

# Initialize SDKMAN only if it is installed.
if [ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]; then
  # This gives you `sdk use java ...`, `sdk list java`, etc.
  source "$SDKMAN_DIR/bin/sdkman-init.sh"
fi

# --- Node.js (Volta) ---------------------------------------------------------
# Volta manages Node/PNPM/Yarn versions in a reproducible way.
# Keeping it early in PATH ensures its shims are picked up.
export PATH="$HOME/.volta/bin:$PATH"

########################################
# 2. General PATH configuration
########################################

# Prefer user-local bin for personal scripts or tools.
export PATH="$HOME/.local/bin:$PATH"

# Add Homebrew's binary directories to PATH so all brew-installed tools are available.
export PATH="$BREW_PREFIX/bin:$BREW_PREFIX/sbin:$PATH"

########################################
# 3. Core Zsh behavior & history
########################################

# Use emacs-style keybindings in the shell (the default, but set explicitly).
bindkey -e

# History file location and size.
export HISTFILE="$HOME/.zsh_history"   # Where command history is stored.
export HISTSIZE=50000                  # Number of lines kept in memory.
export SAVEHIST=50000                  # Number of lines saved to HISTFILE.

# History behavior tuning:
setopt APPEND_HISTORY          # Append to the history file instead of overwriting it.
setopt SHARE_HISTORY           # Share history across all open shell sessions.
setopt INC_APPEND_HISTORY      # Write each command to history as soon as it is executed.
setopt HIST_IGNORE_ALL_DUPS    # Remove older duplicates, keep only the latest command.
setopt HIST_REDUCE_BLANKS      # Strip superfluous whitespace before saving.
setopt HIST_VERIFY             # After !-style expansion, let you edit before running.

# Prefix-based history search with arrow keys:
# Type the beginning of a command, then use Up/Down to cycle matching history entries.
bindkey '^[[A' history-beginning-search-backward   # Up arrow
bindkey '^[[B' history-beginning-search-forward    # Down arrow

########################################
# 4. Completion system configuration
########################################

# Initialize Zsh completion system (must come before plugins that rely on it).
autoload -Uz compinit
compinit

# General completion styles:
zstyle ':completion:*' menu select           # Use a menu interface when multiple matches exist.
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' 'r:|=*' 'l:|=*'  # Case-insensitive & fuzzy matches.

setopt COMPLETE_IN_WORD                      # Allow completion in the middle of words.
setopt AUTO_MENU                             # Automatically show completion menu on repeated Tab.
setopt AUTO_LIST                             # List choices when completion is ambiguous.

########################################
# 5. Fuzzy finder (fzf)
########################################

# fzf provides powerful fuzzy search for history and files.
# This integration typically sets up:
#   - Ctrl+R: fuzzy-search through command history.
#   - Ctrl+T: fuzzy-search files.
if command -v fzf &>/dev/null; then
  # `fzf --zsh` prints the Zsh integration code, which we source on the fly.
  source <(fzf --zsh)
fi

########################################
# 6. Smarter directory jumping (zoxide)
########################################

# zoxide is a smarter `cd`: it tracks frequently used paths and lets you jump via:
#   z <pattern>     -> jumps to the most likely directory matching the pattern.
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi

########################################
# 7. Aliases
########################################

# `ll` -> better `ls` using eza, with icons (requires Nerd Font in terminal).
if command -v eza &>/dev/null; then
  alias ll="eza -lah --icons"
else
  # Fallback if eza is not installed.
  alias ll="ls -lah"
fi

# Directory movement shortcuts.
alias ..="cd .."
alias ...="cd ../.."

# Git shortcuts.
alias gs="git status"
alias gl="git log --oneline --graph --decorate"

########################################
# 8. Visual / UX plugins & prompt
########################################

# --- Autosuggestions ---------------------------------------------------------
# Shows greyed-out suggestions as you type, based on your history and completion.
# Accept suggestion with Right-arrow or End key.
if [ -f "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# --- Starship prompt ---------------------------------------------------------
# Starship is a fast, git-aware prompt written in Rust.
# It reads configuration from ~/.config/starship.toml.
# It provides:
#   - Current directory and git branch
#   - Git status icons (staged, modified, untracked, ahead/behind)
#   - Optional language/runtime version info (Python, Node, Go, etc.)
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# --- Syntax highlighting (should be last) ------------------------------------
# Colors commands, options and paths as you type, helping to catch mistakes early.
# This plugin should be sourced at the end of ~/.zshrc for best compatibility.
if [ -f "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

########################################
# End of ~/.zshrc
########################################
