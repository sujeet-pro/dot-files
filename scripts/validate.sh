#!/bin/bash

# Dotfiles Validation Script
# Checks that all tools are installed, configs are in place, and env vars are set.

set -u

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

pass() {
  echo -e "  ${GREEN}✓${NC} $1"
  ((PASS++))
}

fail() {
  echo -e "  ${RED}✗${NC} $1"
  ((FAIL++))
}

warn() {
  echo -e "  ${YELLOW}!${NC} $1"
  ((WARN++))
}

check_command() {
  if command -v "$1" &>/dev/null; then
    pass "$1"
  else
    fail "$1 — not found"
  fi
}

check_file() {
  if [ -e "$1" ]; then
    pass "$2"
  else
    fail "$2 — $1 missing"
  fi
}

check_symlink() {
  if [ -L "$1" ]; then
    pass "$2 (symlink)"
  elif [ -e "$1" ]; then
    warn "$2 — exists but not a symlink"
  else
    fail "$2 — $1 missing"
  fi
}

check_env() {
  local val="${!1:-}"
  if [ -n "$val" ]; then
    pass "$1 is set"
  else
    fail "$1 is not set"
  fi
}

echo ""
echo "=========================================="
echo "  Dotfiles Validation"
echo "=========================================="

# --- Homebrew formulae ---
echo ""
echo "Homebrew CLI tools:"
for cmd in aichat ansible aws bat buf colima docker eza fnm fzf gh go http k6 lima node protoc python3 rg starship tldr tree wrangler zoxide; do
  check_command "$cmd"
done

# --- Homebrew casks (check apps exist) ---
echo ""
echo "Homebrew casks (applications):"
for app in "Cursor" "Visual Studio Code" "IntelliJ IDEA" "Zed" "Claude" "Ghostty" "Zoom" "Maccy" "Rectangle"; do
  if [ -d "/Applications/${app}.app" ]; then
    pass "$app"
  else
    warn "$app — not in /Applications"
  fi
done

# --- Config files ---
echo ""
echo "Config files:"
check_symlink "$HOME/.zshrc" ".zshrc"
check_symlink "$HOME/.config/starship.toml" "starship.toml"
check_file "$HOME/.gitconfig" ".gitconfig"
check_file "$HOME/.gitconfig-personal" ".gitconfig-personal"
check_file "$HOME/.gitconfig-work" ".gitconfig-work"
check_file "$HOME/.ssh/config" ".ssh/config"
check_file "$HOME/.ssh/config.local" ".ssh/config.local"
check_symlink "$HOME/.aws/config" ".aws/config"
check_symlink "$HOME/.aws/switch-aws-profile.sh" ".aws/switch-aws-profile.sh"
check_symlink "$HOME/.aws/aws-login.zsh" ".aws/aws-login.zsh"
check_symlink "$HOME/.config/gh/config.yml" "gh/config.yml"
check_symlink "$HOME/.config/zed/settings.json" "zed/settings.json"

# --- VS Code ---
echo ""
echo "VS Code:"
VSCODE_DIR="$HOME/Library/Application Support/Code/User"
check_symlink "$VSCODE_DIR/settings.json" "VS Code settings.json"

# --- Env vars ---
echo ""
echo "Environment variables:"
check_env GIT_USER_NAME
check_env GIT_PERSONAL_EMAIL
check_env GIT_WORK_EMAIL
check_env SSH_PERSONAL_KEY
check_env SSH_WORK_KEY

# --- Git config resolution ---
echo ""
echo "Git config resolution:"
RESOLVED_NAME=$(git config --global user.name 2>/dev/null || echo "")
if [ -n "$RESOLVED_NAME" ]; then
  pass "git user.name = $RESOLVED_NAME"
else
  fail "git user.name not set"
fi

# --- Directories ---
echo ""
echo "Directories:"
check_file "$HOME/personal" "~/personal"
check_file "$HOME/work" "~/work"

# --- macOS defaults ---
echo ""
echo "macOS defaults:"

check_default() {
  local domain="$1" key="$2" expected="$3" label="$4"
  local actual
  actual=$(defaults read "$domain" "$key" 2>/dev/null || echo "__unset__")
  if [ "$actual" = "$expected" ]; then
    pass "$label = $expected"
  else
    warn "$label — expected $expected, got $actual"
  fi
}

check_default com.apple.screencapture location "$HOME/screen-captures" "Screenshot location"
check_default com.apple.dock autohide 1 "Dock autohide"
check_default com.apple.dock tilesize 36 "Dock tile size"
check_default com.apple.dock show-recents 0 "Dock show-recents"
check_default com.apple.finder AppleShowAllFiles 1 "Finder show hidden files"
check_default NSGlobalDomain KeyRepeat 2 "KeyRepeat"
check_default NSGlobalDomain InitialKeyRepeat 15 "InitialKeyRepeat"
check_default com.apple.desktopservices DSDontWriteNetworkStores 1 "No .DS_Store on network"
check_default com.apple.desktopservices DSDontWriteUSBStores 1 "No .DS_Store on USB"

# --- Summary ---
echo ""
echo "=========================================="
TOTAL=$((PASS + FAIL + WARN))
echo -e "  ${GREEN}${PASS} passed${NC}  ${RED}${FAIL} failed${NC}  ${YELLOW}${WARN} warnings${NC}  (${TOTAL} total)"
echo "=========================================="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
