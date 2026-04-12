---
title: How Configuration Works
---

# How Configuration Works

The repo manages application configs through two mechanisms: **symlinks** for files you edit directly, and **templates** for files generated from environment variables.

## Symlinked Configs

These config files are symlinked from their system location to the repo. Editing either side changes the same file.

| Application   | System Path                              | Repo Path                          |
| ------------- | ---------------------------------------- | ---------------------------------- |
| Zsh           | `~/.zshrc`                               | `configs/zsh/.zshrc`               |
| Starship      | `~/.config/starship.toml`                | `configs/starship/starship.toml`   |
| Mise          | `~/.config/mise/config.toml`             | `configs/mise/config.toml`         |
| Ghostty       | `~/.config/ghostty/config`               | `configs/ghostty/config`           |
| Zed           | `~/.config/zed/settings.json`            | `configs/zed/settings.json`        |
| Claude        | `~/.config/claude/settings.json`         | `configs/claude/settings.json`     |
| GitHub CLI    | `~/.config/gh/config.yml`                | `configs/gh/config.yml`            |
| btop          | `~/.config/btop/btop.conf`               | `configs/btop/btop.conf`           |
| AWS           | `~/.aws/config`                          | `configs/aws/config`               |
| Colima        | `~/.colima/default/colima.yaml`          | `configs/colima/default.yaml`      |
| VS Code       | `~/Library/Application Support/Code/User/settings.json` | `configs/vscode/settings.json` |

### How Symlinks Work

When the playbook runs, it creates symbolic links so the system path points to the file inside the repo. Because both paths reference the same underlying file:

- Editing the file in its system location (e.g., `~/.config/ghostty/config`) changes the repo copy.
- Editing the file in the repo (e.g., `configs/ghostty/config`) changes what the application sees.

To propagate changes to another machine:

```bash
# On the machine where you made changes
git add . && git commit -m "update ghostty config" && git push

# On the other machine
git pull && make update
```

## Templated Configs

These files are **generated** from Jinja2 templates using values from your `~/.zshenv`. They are re-rendered on every playbook run, so direct edits will be overwritten.

| File                                       | Template Source                              |
| ------------------------------------------ | -------------------------------------------- |
| `~/.gitconfig`                             | `roles/git/templates/gitconfig.j2`           |
| `~/.config/git-configs/personal.gitconfig` | `roles/git/templates/gitconfig-personal.j2`  |
| `~/.config/git-configs/work.gitconfig`     | `roles/git/templates/gitconfig-work.j2`      |
| `~/.ssh/config`                            | `roles/ssh/templates/config.j2`              |

To change these configs, either:
- Edit the Jinja2 template in the repo, or
- Change the variable values in `~/.zshenv` and re-run `make setup`

## Environment Variables (~/.zshenv)

The `~/.zshenv` file is **never committed** to the repo. It holds personal data that varies per machine and per user. On first run, `setup.sh` copies `.zshenv.example` to `~/.zshenv` as a starting point.

### Required Variables (fill before running setup)

| Variable            | Purpose                                    |
| ------------------- | ------------------------------------------ |
| `GIT_USER_NAME`     | Full name used in git commits              |
| `GIT_PERSONAL_EMAIL`| Email for personal git repos               |
| `GIT_WORK_EMAIL`    | Email for work git repos                   |
| `SSH_PERSONAL_KEY`  | Filename of personal SSH key (e.g., `id_ed25519_personal`) |
| `SSH_WORK_KEY`      | Filename of work SSH key (e.g., `id_ed25519_work`)         |

### Recommended Variables (for full work/personal separation)

| Variable                  | Purpose                                                       |
| ------------------------- | ------------------------------------------------------------- |
| `GIT_WORK_FOLDERS`        | Comma-separated paths where work repos live (default: `~/work,~/workspace`) |
| `GIT_WORK_GITHUB_ORGS`    | Comma-separated GitHub orgs that should use work git config   |
| `GIT_WORK_BITBUCKET_ORGS` | Comma-separated Bitbucket workspaces for work git config      |

### Optional Variables (configure later)

API tokens, MCP server configurations, and other integrations. See `.zshenv.example` for the full list — these are not needed for setup to work.

## Work vs Personal Separation

Git is configured with **conditional includes** based on directory path and remote URL:

### Directory-based matching

- **`~/personal/`** -- Uses `GIT_PERSONAL_EMAIL` and personal git settings
- **Work folders** -- Uses `GIT_WORK_EMAIL`, work-specific `.gitignore-work`, and work git settings

By default, work folders are `~/work/` and `~/workspace/`. You can customize this by setting `GIT_WORK_FOLDERS` in `~/.zshenv`:

```bash
# Single folder
export GIT_WORK_FOLDERS="~/work"

# Multiple folders
export GIT_WORK_FOLDERS="~/work,~/workspace,~/company-projects"
```

### Remote URL-based matching

Work git config also applies to repos that match configured GitHub or Bitbucket org URLs, regardless of which directory the repo is cloned into. Set `GIT_WORK_GITHUB_ORGS` and `GIT_WORK_BITBUCKET_ORGS` for this.

### How it works

This means you never have to remember to switch git identities. Repos in work folders or matching work org URLs automatically use your work email. Repos under `~/personal/` use your personal email. Everything else uses the default (personal) identity.

Additionally, Mise tool-version files (`.mise.toml`) are auto-ignored in work repos through the work-specific gitignore, preventing local runtime configs from being accidentally committed to work projects.
