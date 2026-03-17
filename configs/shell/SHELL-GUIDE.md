# Shell Features & Shortcuts Guide

Quick reference for all productivity tools and keybindings configured in this shell setup.

## Tool Overview

| Tool | Purpose | Config |
|------|---------|--------|
| **zsh** | Shell with completions, history sharing, fuzzy matching | `~/.zshrc` |
| **starship** | Fast, git-aware prompt with language indicators | `~/.config/starship.toml` |
| **fzf** | Fuzzy finder for files, history, and directories | Integrated in `.zshrc` |
| **fd** | Fast file finder (modern `find`), feeds into fzf | Used as fzf backend |
| **bat** | Syntax-highlighted `cat` with line numbers | Aliased as `cat` |
| **eza** | Modern `ls` with icons and tree view | Aliased as `ll`, `tree` |
| **zoxide** | Smart `cd` that learns your most-used directories | Replaces `cd` |
| **atuin** | Enhanced shell history with full-text search | Replaces Ctrl+R |
| **delta** | Syntax-highlighted git diffs with side-by-side view | Git pager |
| **lazygit** | Terminal UI for git operations | Aliased as `lg` |
| **ripgrep** | Fast code search (modern `grep`) | `rg` command |
| **jq** | JSON processor and pretty-printer | Aliased as `json` |
| **direnv** | Auto-loads `.envrc` files per directory | Hook in `.zshrc` |
| **mise** | Runtime/tool version manager (node, python, go, etc.) | `~/.config/mise/config.toml` |

## Keyboard Shortcuts

### fzf (Fuzzy Finder)

| Shortcut | Action |
|----------|--------|
| `Ctrl+R` | Fuzzy search command history (enhanced by atuin) |
| `Ctrl+T` | Fuzzy search files in current directory (with bat preview) |
| `Alt+C` | Fuzzy search and cd into directories (with tree preview) |
| `**<Tab>` | Inline fuzzy completion (e.g., `cd **<Tab>`, `vim **<Tab>`) |

### Atuin (Shell History)

| Shortcut | Action |
|----------|--------|
| `Ctrl+R` | Open atuin interactive history search |
| `Up/Down` | Prefix-based history search (type partial command first) |

> Atuin features: full-text search, per-directory history filtering, session-aware history, timestamps, duration tracking.

### Zsh Built-in

| Shortcut | Action |
|----------|--------|
| `Tab` | Auto-complete (with menu selection for multiple matches) |
| `Tab Tab` | Show completion menu |
| `Ctrl+A` | Move cursor to beginning of line |
| `Ctrl+E` | Move cursor to end of line |
| `Ctrl+W` | Delete word before cursor |
| `Ctrl+U` | Delete from cursor to beginning of line |
| `Ctrl+K` | Delete from cursor to end of line |
| `Ctrl+L` | Clear screen |
| `Ctrl+D` | Exit shell / delete char under cursor |
| `Alt+B` | Move back one word |
| `Alt+F` | Move forward one word |
| `Right Arrow` | Accept autosuggestion (zsh-autosuggestions) |

## Aliases

### File Operations

| Alias | Command | Description |
|-------|---------|-------------|
| `ll` | `eza -lah --icons` | Detailed file listing with icons |
| `la` | `eza -a --icons` | Show all files with icons |
| `lt` | `eza -lah --icons --sort=modified` | List files sorted by modification time |
| `tree` | `eza --tree --level=2 --icons` | Tree view (2 levels deep) |
| `cat` | `bat --paging=never` | Syntax-highlighted file viewing |
| `catp` | `bat --plain --paging=never` | Plain file viewing (no decorations) |

### Navigation

| Alias | Command | Description |
|-------|---------|-------------|
| `cd <pattern>` | `zoxide` | Smart jump to best-matching directory |
| `cdi <pattern>` | `zoxide interactive` | Fuzzy-select from matching directories |
| `..` | `cd ..` | Go up one directory |
| `...` | `cd ../..` | Go up two directories |
| `....` | `cd ../../..` | Go up three directories |

### Git

| Alias | Command | Description |
|-------|---------|-------------|
| `gs` | `git status` | Short status |
| `gl` | `git log --oneline --graph --decorate` | Compact log with graph |
| `gd` | `git diff` | Show unstaged changes |
| `gds` | `git diff --stat` | Diff summary (files changed) |
| `gdc` | `git diff --cached` | Show staged changes |
| `gcl` | `git checkout $(branch \| fzf)` | Fuzzy-select local branch to checkout |
| `gcr` | `git checkout $(branch -r \| fzf)` | Fuzzy-select remote branch to checkout |
| `gbd` | `git branch \| fzf -m \| xargs git branch -d` | Fuzzy multi-select branches to delete |
| `lg` | `lazygit` | Open lazygit terminal UI |

### Frontend Development

| Alias | Command | Description |
|-------|---------|-------------|
| `scripts` | `jq '.scripts' package.json` | View package.json scripts |
| `deps` | `jq '.dependencies' package.json` | View production dependencies |
| `devdeps` | `jq '.devDependencies' package.json` | View dev dependencies |
| `killport <port>` | `lsof -ti:<port> \| xargs kill -9` | Kill process on a specific port |
| `json` | `jq '.'` | Pretty-print JSON (pipe into it) |

### Other

| Alias | Command | Description |
|-------|---------|-------------|
| `ai` / `aie` | `aichat -e` | Quick AI chat in terminal |
| `aws-whoami` | `aws sts get-caller-identity` | Check current AWS identity |

## Git Integration (delta)

All `git diff`, `git log -p`, and `git show` output is automatically rendered with:
- Syntax highlighting
- Side-by-side view
- Line numbers
- Hyperlinks to files

Navigate delta output:
| Key | Action |
|-----|--------|
| `n` | Jump to next file |
| `N` | Jump to previous file |
| `q` | Quit |

## lazygit Shortcuts

Open with `lg`. Key panels:

| Key | Panel |
|-----|-------|
| `1` | Status |
| `2` | Files |
| `3` | Branches |
| `4` | Commits |
| `5` | Stash |
| `Space` | Stage/unstage file |
| `c` | Commit |
| `p` | Pull |
| `P` | Push |
| `r` | Rebase |
| `s` | Stash |
| `?` | Show all keybindings |

## Prompt Indicators (Starship)

The prompt shows context-aware information:

```
~/work/project  main ●✚…⇡
❯
```

| Indicator | Meaning |
|-----------|---------|
| `●` | Staged changes |
| `✚` | Modified files |
| `…` | Untracked files |
| `✖` | Deleted files |
| `»` | Renamed files |
| `≠` | Merge conflicts |
| `⇡` | Ahead of remote |
| `⇣` | Behind remote |
| `⇕` | Diverged from remote |
| `⚑` | Stashed changes |

Language versions (Node, Bun, Python, Go, Java, Kotlin) appear automatically when relevant project files are detected.

## Productivity Tips

1. **Find any file fast**: `Ctrl+T` → type partial name → Enter
2. **Jump to any project**: `cd proj` → zoxide takes you to `~/work/project`
3. **Recall complex commands**: `Ctrl+R` → type keywords from anywhere in the command
4. **Review git changes**: `lg` → navigate visually, stage hunks, commit, push
5. **Check API responses**: `curl -s api/endpoint | json`
6. **Kill stuck dev server**: `killport 3000`
7. **Browse project scripts**: `scripts` in any npm project
8. **Benchmark a command**: `hyperfine 'npm run build' 'bun run build'`
9. **Watch files for changes**: `watchexec -e ts,tsx -- npm test`
10. **Search code fast**: `rg "TODO" --type ts` or `rg "function.*fetch" -g "*.tsx"`
