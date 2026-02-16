Sync the dot-files repo with the current system state. Follow these steps:

## 1. Homebrew packages

Run `brew leaves` (formulae) and `brew list --cask` (casks). Compare with `roles/homebrew/vars/main.yml`. Report any packages installed on the system but missing from the repo, and any listed in the repo but not installed.

## 2. VS Code extensions

Run `code --list-extensions`. Compare with both `roles/apps/vars/main.yml` (vscode_extensions) and `.vscode/extensions.json` (recommendations). Report differences — both files should stay in sync with each other and with what's installed.

## 3. macOS defaults

Read the current values for each default listed in `roles/macos/vars/main.yml` using `defaults read`. Compare with the values defined in the vars file. Report any that differ from what the repo expects.

## 4. Update repo files

Present all differences found above and ask the user which changes to apply. For approved changes, update the corresponding YAML/JSON files in the repo. Keep the existing formatting and comment structure.

## 5. Validate

Run `make validate` to verify everything passes after changes.
