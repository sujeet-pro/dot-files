#!/bin/bash
set -euo pipefail

REPO_URL="${DOTFILES_REPO_URL:-https://github.com/sujeet-pro/dot-files.git}"
DEST_DIR="${DOTFILES_DEST_DIR:-$HOME/personal/dot-files}"

echo "=========================================="
echo "  Dotfiles Remote Bootstrap"
echo "=========================================="
echo "Repo: $REPO_URL"
echo "Dest: $DEST_DIR"
echo ""

mkdir -p "$(dirname "$DEST_DIR")"

if [ -d "$DEST_DIR/.git" ]; then
  echo "Updating existing repo..."
  git -C "$DEST_DIR" pull --ff-only
else
  if [ -e "$DEST_DIR" ]; then
    echo "Error: $DEST_DIR exists but is not a git repo."
    exit 1
  fi
  echo "Cloning repo..."
  git clone "$REPO_URL" "$DEST_DIR"
fi

echo "Running setup..."
"$DEST_DIR/setup.sh"
