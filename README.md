# dot-files

Automated macOS development environment setup using Ansible.

## Quick Start

```sh
git clone https://github.com/sujeet-pro/dot-files.git ~/dot-files
cd ~/dot-files
./setup.sh
```

`setup.sh` handles everything: Xcode CLI tools, Homebrew, Ansible, and runs the full playbook.

## How It Works

### Environment Variables (`~/.zshenv`)

Personal data (name, email, SSH key names, API tokens) lives in `~/.zshenv`, which is **never committed**. On first run, `setup.sh` copies `.zshenv.example` to `~/.zshenv` and asks you to fill it in.

Ansible templates use these env vars to generate git and SSH configs, so personal data stays out of the repo.

### Personal SSH Hosts (`~/.ssh/config.local`)

The SSH config is templated with standard entries (GitHub, Bitbucket, Colima). For personal hosts (EC2 instances, etc.), add them to `~/.ssh/config.local` — this file is auto-created on first run and is `Include`d by the main SSH config. It's gitignored.

## Makefile Targets

```sh
make help         # Show all available targets
make setup        # Full bootstrap from scratch
make update       # Update packages and re-run playbook
make check        # Dry-run: show what would change
make validate     # Quick check: tools, configs, symlinks, env vars
make test         # Local test: validate + Ansible syntax check
make test-vm      # Full end-to-end test in a clean Tart macOS VM
make test-vm-debug  # Same as test-vm but keeps VM alive for debugging
```

## Testing

### Quick validation (seconds)

```sh
make validate
```

Runs `scripts/validate.sh` which checks:
- All Homebrew formulae and casks are installed
- Config files exist and symlinks point correctly
- Required env vars are set (`GIT_USER_NAME`, etc.)
- Git config resolves correctly
- Project directories exist

### Local test (seconds)

```sh
make test
```

Runs `make validate` plus Ansible playbook syntax check.

### Full end-to-end test (30+ minutes, first run downloads ~15 GB)

```sh
make test-vm
```

Runs `scripts/tart-test.sh` which:
1. Clones a fresh macOS Sequoia VM via [Tart](https://tart.run)
2. Boots it headless, copies the repo in via rsync
3. Creates a test `~/.zshenv` with dummy values
4. Installs Homebrew and Ansible from scratch
5. Runs the full Ansible playbook
6. Runs `scripts/validate.sh` inside the VM
7. Reports pass/fail and tears down the VM

**Requirements:** `brew install cirruslabs/cli/tart` and `brew install esolitos/ipa/sshpass`

To keep the VM alive after a failure (for debugging):

```sh
make test-vm-debug
```

Then SSH in with `ssh admin@<VM_IP>` (password: `admin`).

## Directory Structure

```
dot-files/
├── .aws/                        # AWS CLI config & scripts (symlinked)
├── .colima/
│   └── default.yaml             # Colima profile (symlinked)
├── .config/
│   ├── gh/config.yml            # GitHub CLI config (symlinked)
│   ├── mise/config.toml         # mise global tools config (symlinked)
│   ├── starship.toml            # Starship prompt config (symlinked)
│   └── zed/settings.json        # Zed editor config (symlinked)
├── .vscode/
│   ├── settings.json            # VS Code settings (symlinked)
│   └── extensions.json          # Recommended extensions
├── .claude/
│   └── commands/sync.md         # Sync skill for Claude Code
├── roles/
│   ├── homebrew/                # Homebrew package installation
│   ├── mise/                    # Runtime/SDK installation via mise
│   ├── shell/                   # .zshrc, .zprofile, starship (symlinks)
│   ├── git/                     # .gitconfig files (templates from env vars)
│   ├── ssh/                     # .ssh/config (template with config.local)
│   ├── apps/                    # VS Code, Zed, GH CLI configs
│   ├── aws/                     # AWS config & scripts
│   ├── dev-tools/               # fzf keybindings, project directories
│   └── macos/                   # macOS system defaults (Dock, Finder, keyboard, etc.)
├── scripts/
│   ├── validate.sh              # Quick validation script
│   └── tart-test.sh             # Full VM end-to-end test
├── CLAUDE.md                    # Project guidelines for Claude Code
├── .zshenv.example              # Template for personal env vars
├── .zshrc                       # Shell configuration
├── setup.sh                     # One-command bootstrap
├── setup.yml                    # Ansible playbook
├── Makefile                     # Convenience targets
└── ansible.cfg                  # Ansible configuration
```

## What Gets Installed

### CLI Tools (Homebrew Formulae)

| Category | Tools |
|---|---|
| Core utilities | aichat, ansible, awscli, bat, direnv, eza, fzf, mise, ripgrep, starship, tlrc, tree, zoxide |
| Shell plugins | zsh-autosuggestions, zsh-syntax-highlighting |
| Dev tools | actionlint, buf, gh, gitleaks, pre-commit, protobuf, shellcheck, trivy, zizmor |
| Containers | colima, docker, docker-buildx, docker-compose |
| Cloud & infra | cloudflare-wrangler, k6 |
| AI | gemini-cli |

### Language SDKs (mise)

| Language/Tool | Version Strategy |
|---|---|
| node, bun, yarn, pnpm, python, uv, go, java, kotlin | latest |

### GUI Apps (Homebrew Casks)

| Category | Apps |
|---|---|
| Editors & IDEs | cursor, visual-studio-code, intellij-idea, zed |
| AI Tools | chatgpt-atlas, claude, claude-code, codex, comet |
| Terminal | ghostty |
| API clients | bruno |
| Communication | zoom |
| Utilities | maccy, rectangle, notion, nordlayer |
| Fonts | font-jetbrains-mono, font-jetbrains-mono-nerd-font |

### macOS System Defaults

| Category | Settings |
|---|---|
| Screenshots | Save to `~/screen-captures`, PNG format, no shadow |
| Finder | Show hidden files, search current folder, no extension-change warning |
| Dock | Autohide, size 36, scale effect, no recent apps, zero delay |
| Keyboard | Fast repeat (2), short initial delay (15), key repeat over accents |
| Trackpad | Tracking speed 2.5 |
| Mission Control | Don't rearrange Spaces by use, fast animation |
| Desktop Services | No `.DS_Store` on network or USB volumes |
| General UI | Expanded save/print panels, save to disk, no quarantine dialog |
| Security | Password required immediately after sleep |
| TextEdit | Plain text mode, UTF-8 encoding |
| Activity Monitor | CPU in Dock icon, show all processes |
| Safari | Developer menu enabled |
| Chrome | Swipe navigation disabled |

## Templated vs Symlinked Files

- **Symlinked** (no personal data): `.zshrc`, `starship.toml`, `mise/config.toml`, `.colima/default.yaml`, VS Code settings, Zed settings, GH CLI config, AWS config
- **Templated** (personal data from env vars): `.gitconfig`, `.gitconfig-personal`, `.gitconfig-work`, `.ssh/config`

Templated files are rendered as regular files in `~`, so personal data never flows back to git.
