---
title: Language Runtimes
---

# Language Runtimes

All language runtimes are managed by [mise](https://mise.jdx.dev/), installed as a Homebrew formula. Mise handles downloading, installing, and switching between versions of Node, Python, Java, and other tools.

## Managed runtimes

Source: `configs/mise/config.toml` (symlinked to `~/.config/mise/config.toml`).

| Runtime | Version | Notes |
|---------|---------|-------|
| `node` | `lts` | Current LTS release; updated automatically on `mise install` |
| `bun` | `latest` | Fast JavaScript runtime and bundler |
| `java` | `temurin-17` | Eclipse Temurin JDK 17 (LTS) |
| `python` | `3.12` | Used for Ansible and general scripting |
| `uv` | `latest` | Fast Python package installer (replaces pip) |
| `yarn` | `1` | Yarn Classic; used by projects that have not migrated to v4 |

## Why mise

| Alternative | Why not |
|-------------|---------|
| asdf | ~10x slower to resolve and install versions; mise is a drop-in replacement written in Rust |
| fnm | Node-only; does not handle Python, Java, or other runtimes |
| nvm | Node-only and slow; adds noticeable shell startup time |
| proto | Smaller ecosystem; fewer plugins and community support |

Mise is a single tool that replaces asdf, fnm, nvm, pyenv, jenv, and direnv in one binary.

## Config location

The global mise config lives at:

```
configs/mise/config.toml  -->  ~/.config/mise/config.toml  (symlink)
```

The Ansible `mise` role creates this symlink and runs `mise install` to ensure all runtimes are present.

## Work vs personal separation

Projects under `~/work/` can have their own `.mise.toml` files for project-specific runtime versions. These files are auto-ignored via `.gitignore-work` so they never get committed to work repos.

This means you can pin `node = "18"` in a work project without affecting your global `lts` setting, and the `.mise.toml` file stays local to your machine.

## Global npm packages

Source: `roles/mise/vars/main.yml` under `npm_global_packages`.

These packages are installed globally via the mise-managed Node (LTS):

| Package | Purpose |
|---------|---------|
| `diagramkit` | Diagram generation from code |
| `excalidraw-cli` | Export Excalidraw diagrams from the command line |
| `vite-plus` | Enhanced Vite dev server |

## How to add a runtime

1. Edit `configs/mise/config.toml` and add the tool under `[tools]`:
   ```toml
   [tools]
   node = "lts"
   ruby = "3.3"   # <-- new runtime
   ```

2. Run `mise install` to download and install it:
   ```bash
   mise install
   ```

   Or re-run the full playbook:
   ```bash
   make setup
   ```

3. Verify it is active:
   ```bash
   mise ls
   ruby --version
   ```

To add a global npm package, add it to `roles/mise/vars/main.yml` under `npm_global_packages` and run `make setup`.
