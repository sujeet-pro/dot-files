# dot-files

Automated macOS development environment setup using Ansible.

## What Started as Dot Files

This repository started as a simple collection of configuration files (`.zshrc`, `.gitconfig`, `starship.toml`, etc.) — the classic "dot-files" repo. Over time it evolved into a **full macOS system setup tool** that handles everything from installing CLI tools and GUI apps to configuring system defaults and managing language runtimes.

If you're here just for the configuration files, see [Where Are the Configs?](#where-are-the-configs) below.

## Quick Start

One-liner for a fresh Mac (clones the repo and runs setup):

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/sujeet-pro/dot-files/main/bootstrap-remote.sh)"
```

Or manually:

```sh
git clone https://github.com/sujeet-pro/dot-files.git ~/personal/dot-files
cd ~/personal/dot-files
./setup.sh
```

`setup.sh` handles everything:
1. Installs Xcode CLI tools, Homebrew, and Ansible (if missing)
2. Creates `~/.zshenv` from a template and asks you to fill in personal values
3. Runs the Ansible playbook to install packages, configure apps, and set system defaults
4. Detects any installed packages not tracked in the repo and offers to add or remove them

Re-running `./setup.sh` is always safe — it's fully idempotent. Missing software gets installed, broken symlinks get fixed, and unmanaged packages get flagged.

## Where Are the Configs?

All application configuration files live under **`configs/`**, organized by app:

```
configs/
├── aws/config              # AWS CLI configuration
├── btop/btop.conf          # btop system monitor
├── claude/
│   ├── settings.json       # Claude Code global settings
│   └── skills/             # Claude Code custom skills
├── colima/default.yaml     # Colima (Docker runtime) profile
├── gh/config.yml           # GitHub CLI
├── ghostty/config          # Ghostty terminal (used by cmux)
├── mise/config.toml        # mise global tool versions
├── shell/
│   ├── .zshrc              # Zsh configuration
│   ├── .zshenv.example     # Template for personal env vars
│   ├── starship.toml       # Starship prompt theme
│   └── SHELL-GUIDE.md      # Shell setup documentation
├── vscode/settings.json    # VS Code editor settings
└── zed/settings.json       # Zed editor settings
```

These are **symlinked** to their expected locations on the system (e.g. `configs/shell/.zshrc` → `~/.zshrc`). Editing either side updates both.

Some configs contain personal data (name, email, SSH keys) and are **templated** instead of symlinked:

| File | Template | Source of Values |
|------|----------|-----------------|
| `~/.gitconfig` | `roles/git/templates/gitconfig.j2` | `~/.zshenv` env vars |
| `~/.gitconfig-personal` | `roles/git/templates/gitconfig-personal.j2` | `~/.zshenv` env vars |
| `~/.gitconfig-work` | `roles/git/templates/gitconfig-work.j2` | `~/.zshenv` env vars |
| `~/.ssh/config` | `roles/ssh/templates/ssh_config.j2` | `~/.zshenv` env vars |

## How It Works

### Environment Variables (`~/.zshenv`)

Personal data (name, email, SSH key names, API tokens) lives in `~/.zshenv`, which is **never committed**. On first run, `setup.sh` copies `configs/shell/.zshenv.example` to `~/.zshenv` and asks you to fill it in.

Ansible templates use these env vars to generate git and SSH configs, so personal data stays out of the repo.

### Personal SSH Hosts (`~/.ssh/config.local`)

The SSH config is templated with standard entries (GitHub, Bitbucket, Colima). For personal hosts (EC2 instances, etc.), add them to `~/.ssh/config.local` — this file is auto-created on first run and is `Include`d by the main SSH config. It's gitignored.

### Cleanup Check

After running the playbook, `setup.sh` compares what's installed on your system against what's configured in the repo:

- **Homebrew formulae** — `brew leaves` vs `roles/homebrew/vars/main.yml`
- **Homebrew casks** — `brew list --cask` vs `roles/homebrew/vars/main.yml`
- **VS Code extensions** — `code --list-extensions` vs `roles/apps/vars/main.yml`

For each unmanaged package, you can choose to **add it to the repo**, **remove it from the system**, or **skip** it.

## Make Targets

| Command | Description |
|---------|-------------|
| `make setup` | Full bootstrap from scratch (`setup.sh`) |
| `make update` | Update Homebrew packages and re-run playbook |
| `make cleanup` | Detect unmanaged packages and offer to add/remove them |
| `make check` | Dry-run: show what Ansible would change without applying |
| `make validate` | Quick validation of tools, configs, symlinks, and env vars |
| `make test` | `validate` + Ansible syntax check |
| `make test-vm` | Full end-to-end test in a clean Tart macOS VM |
| `make test-vm-debug` | Same as `test-vm` but keeps VM alive for debugging |
| `make help` | Show all available targets |

## Testing

### Quick validation (seconds)

```sh
make validate
```

Runs `scripts/validate.sh` which checks:
- All Homebrew formulae and casks are installed
- Config symlinks point correctly
- Required env vars are set (`GIT_USER_NAME`, etc.)
- Git config resolves correctly
- Project directories exist
- macOS defaults are applied

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

## What Gets Installed

### CLI Tools (Homebrew Formulae)

| Category | Tools |
|---|---|
| Core utilities | aichat, ansible, atuin, awscli, bat, btop, direnv, eza, fd, fzf, jq, mise, ripgrep, starship, tlrc, tree, zoxide |
| Shell plugins | zsh-autosuggestions, zsh-syntax-highlighting |
| Dev tools | actionlint, buf, gh, git-delta, gitleaks, hyperfine, lazygit, pre-commit, protobuf, shellcheck, trivy, watchexec, zizmor |
| Containers | colima, docker, docker-buildx, docker-compose |
| Cloud & infra | k6 |
| AI | gemini-cli |

### Language SDKs (mise)

| Language/Tool | Version Strategy |
|---|---|
| node, bun, yarn, pnpm, python, uv, go, java, kotlin | latest |

### GUI Apps (Homebrew Casks)

| Category | Apps |
|---|---|
| Editors & IDEs | cursor, visual-studio-code, intellij-idea, webstorm, pycharm, datagrip, zed, antigravity |
| AI tools | chatgpt-atlas, claude, claude-code, codex, codex-app, comet, cursor-cli |
| Terminal | cmux |
| API clients | bruno |
| Communication | zoom |
| Utilities | logi-options+, raycast, notion, nordlayer |
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

## Repository Structure

```
dot-files/
├── configs/                         # All app configuration files (see above)
├── roles/
│   ├── homebrew/                    # Homebrew formulae and cask installation
│   ├── mise/                        # Runtime/SDK installation via mise
│   ├── shell/                       # .zshrc, .zprofile, starship (symlinks)
│   ├── git/                         # .gitconfig files (templates from env vars)
│   ├── ssh/                         # .ssh/config (template with config.local)
│   ├── apps/                        # VS Code, Zed, GH CLI, Ghostty, btop configs
│   ├── claude/                      # Claude Code settings and skills
│   ├── aws/                         # AWS CLI config
│   ├── dev-tools/                   # fzf keybindings, colima, project directories
│   └── macos/                       # macOS system defaults (Dock, Finder, keyboard, etc.)
├── scripts/
│   ├── validate.sh                  # Quick validation script
│   └── tart-test.sh                 # Full VM end-to-end test
├── setup.sh                         # Single entry point: bootstrap + playbook + cleanup
├── setup.yml                        # Ansible playbook
├── Makefile                         # Convenience targets
└── ansible.cfg                      # Ansible configuration
```

## Adding Packages

- **Homebrew formula**: add to `homebrew_formulae` in `roles/homebrew/vars/main.yml`
- **Homebrew cask**: add to `homebrew_casks` in `roles/homebrew/vars/main.yml`
- **VS Code extension**: add to `vscode_extensions` in `roles/apps/vars/main.yml`

Or just install them normally and run `make cleanup` — it will detect the new packages and offer to add them to the config.

## Adding App Configs

1. Place config files under `configs/<app-name>/`
2. Add symlink tasks to the appropriate role in `roles/<role>/tasks/main.yml`
3. Add validation checks to `scripts/validate.sh`
