# dot-files

The folder structure refers to the `$HOME` of the user on a mac os system.

## Configurations

| File | Description |
| --- | --- |
| `.zshrc` | **Shell Configuration**: Sets up Homebrew, version managers (goenv, pyenv, sdkman, volta), PATH, zsh history, aliases, and plugins (autosuggestions, syntax highlighting). |
| `.gitconfig` | **Global Git Config**: Defines user identity, default branch (`main`), push/pull behavior, aliases, and conditional includes for work/personal profiles. |
| `.gitconfig-personal` | **Personal Git Profile**: Specific Git settings for repositories in `~/personal/`. |
| `.gitconfig-work` | **Work Git Profile**: Specific Git settings for repositories in `~/work/`. |
| `.ssh/config` | **SSH Configuration**: Manages SSH keys for different hosts (e.g., using `id_ed25519_personal` for GitHub and `id_ed25519_work` for Bitbucket). |
| `.config/starship.toml` | **Starship Prompt**: Customizes the terminal prompt with modules for git status, language versions (Python, Node, Go, Java), and execution time. |
| `.vscode/settings.json` | **VS Code Settings**: associates specific config files with file types for syntax highlighting. |

## Installation of tools

### Better Alternatives

| Original | Better Alternative | Description |
| --- | --- | --- |
| ls | eza | ls replacement for listing files and folders |
| top | htop | top replacement for system monitoring |
| top | btop | top and htop replacement for system monitoring |
| cat | bat | cat replacement for viewing files |
| find | fd | find replacement for finding files |
| find | fzf | fzf replacement for fuzzy finding files |
| grep | ripgrep | grep replacement for searching files |
| cd | z | zoxide replacement for navigating files |
| man | tldr | man replacement for viewing manual pages (installed via tlrc) |


### Brew Formulae

| Formula | Category | Description |
| --- | --- | --- |
| `git` | Essentials | Distributed version control system |
| `curl` | Essentials | Command line tool for transferring data with URLs |
| `wget` | Essentials | Internet file retriever |
| `jq` | Essentials | Lightweight and flexible command-line JSON processor |
| `yq` | Essentials | Portable command-line YAML processor |
| `htop` | Monitoring | Interactive process viewer |
| `btop` | Monitoring | Resource monitor that shows usage and stats |
| `bat` | Monitoring | Cat clone with syntax highlighting and Git integration |
| `tlrc` | Monitoring | Official tldr client (simplified man pages) |
| `eza` | File Management | Modern replacement for ls |
| `tree` | File Management | Display directories as trees |
| `fd` | File Management | Simple, fast and user-friendly alternative to find |
| `fzf` | File Management | Command-line fuzzy finder |
| `ripgrep` | File Management | Recursively searches directories for a regex pattern |
| `zoxide` | File Management | Smarter cd command |
| `volta` | Version Management | JavaScript tool manager |
| `pyenv` | Version Management | Python version management |
| `goenv` | Version Management | Go version management |
| `awscli` | Cloud | Official Amazon Web Services CLI |
| `starship` | Terminal | Minimal, blazing-fast, and infinitely customizable prompt |
| `zsh-autosuggestions` | Terminal | Fish-like autosuggestions for zsh |
| `zsh-syntax-highlighting` | Terminal | Syntax highlighting for Zsh |
| `aichat` | AI | All-in-one AI CLI tool |
| `gemini-cli` | AI | Command line interface for Google Gemini |

### Brew Casks

| Cask | Category | Description |
| --- | --- | --- |
| `antigravity` | Editors & Agents | Powerful agentic AI coding assistant |
| `cursor` | Editors & Agents | AI-first code editor |
| `visual-studio-code` | Editors & Agents | Extensible code editor |
| `codex` | Editors & Agents | OpenAI's coding agent that runs in your terminal |
| `brave-browser` | Browsers | Privacy-oriented web browser |
| `chatgpt-atlas` | Browsers | OpenAI's official browser with ChatGPT built in |
| `discord` | Communications | Voice and text chat |
| `zoom` | Communications | Video conferencing |
| `slack` | Communications | Team communication |
| `orbstack` | Docker | Fast, light, and simple Docker & Linux for macOS |
| `font-jetbrains-mono-nerd-font` | Fonts | Developer font with icons |
| `raindropio` | Productivity | Bookmark manager |
| `maccy` | Productivity | Lightweight clipboard manager |
| `todoist-app` | Productivity | To-do list and task manager |
| `nordlayer` | VPN | Business VPN solution |


### Installation

To install all the tools listed above, you can use the following commands:

**Install all Brew Formulae:**
```sh
brew install git curl wget jq yq htop btop bat tlrc eza tree fd fzf ripgrep zoxide volta pyenv goenv awscli starship zsh-autosuggestions zsh-syntax-highlighting aichat gemini-cli
```

**Install all Brew Casks:**
```sh
brew install --cask antigravity cursor visual-studio-code codex brave-browser chatgpt-atlas discord zoom slack orbstack font-jetbrains-mono-nerd-font raindropio maccy todoist-app nordlayer
```

