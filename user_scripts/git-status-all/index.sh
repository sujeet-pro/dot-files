#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# git-status-all
#
# Iterates through all first-level subdirectories of a given folder
# and reports git status in a human-readable format.
#
# For each directory:
#   - "No changes" if working tree is clean AND all commits are pushed
#   - Otherwise, bullet-pointed breakdown of what's pending
#
# Usage:
#   git-status-all [path]    (default: current directory)
# ─────────────────────────────────────────────────────────────

TARGET_DIR=""

usage() {
  cat <<EOF
Usage: git-status-all [path]

Checks git status of all first-level subdirectories.

Arguments:
  [path]    Directory to scan (default: current directory)

Options:
  -h, --help    Show this help
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage ;;
    -*)        echo "Unknown option: $1"; exit 1 ;;
    *)
      if [[ -z "$TARGET_DIR" ]]; then
        TARGET_DIR="$1"; shift
      else
        echo "Unexpected argument: $1"; exit 1
      fi
      ;;
  esac
done

[[ -z "$TARGET_DIR" ]] && TARGET_DIR="$(pwd)"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Error: '$TARGET_DIR' is not a directory."
  exit 1
fi

# ─────────────────── scan directories ───────────────────

TOTAL=0
CLEAN=0
DIRTY=0
NOT_GIT=0

for dir in "$TARGET_DIR"/*/; do
  [[ ! -d "$dir" ]] && continue

  dir_name="$(basename "$dir")"
  TOTAL=$((TOTAL + 1))

  # Skip non-git directories
  if [[ ! -d "$dir/.git" ]]; then
    echo "━━━ $dir_name ━━━"
    echo "  (not a git repository)"
    echo ""
    NOT_GIT=$((NOT_GIT + 1))
    continue
  fi

  echo "━━━ $dir_name ━━━"

  issues=()

  # Untracked files
  untracked=$(git -C "$dir" ls-files --others --exclude-standard 2>/dev/null)
  if [[ -n "$untracked" ]]; then
    count=$(echo "$untracked" | wc -l | tr -d ' ')
    issues+=("Untracked files ($count):")
    while IFS= read -r f; do
      issues+=("    $f")
    done <<< "$untracked"
  fi

  # Staged (uncommitted) changes
  staged=$(git -C "$dir" diff --cached --name-status 2>/dev/null)
  if [[ -n "$staged" ]]; then
    count=$(echo "$staged" | wc -l | tr -d ' ')
    issues+=("Staged but uncommitted ($count):")
    while IFS= read -r f; do
      issues+=("    $f")
    done <<< "$staged"
  fi

  # Unstaged modifications
  unstaged=$(git -C "$dir" diff --name-status 2>/dev/null)
  if [[ -n "$unstaged" ]]; then
    count=$(echo "$unstaged" | wc -l | tr -d ' ')
    issues+=("Modified but unstaged ($count):")
    while IFS= read -r f; do
      issues+=("    $f")
    done <<< "$unstaged"
  fi

  # Unpushed commits (across all tracking branches)
  current_branch=$(git -C "$dir" symbolic-ref --short HEAD 2>/dev/null || echo "")
  if [[ -n "$current_branch" ]]; then
    upstream=$(git -C "$dir" rev-parse --abbrev-ref "@{upstream}" 2>/dev/null || echo "")
    if [[ -n "$upstream" ]]; then
      unpushed=$(git -C "$dir" log "$upstream..HEAD" --oneline 2>/dev/null)
      if [[ -n "$unpushed" ]]; then
        count=$(echo "$unpushed" | wc -l | tr -d ' ')
        issues+=("Unpushed commits on $current_branch ($count):")
        while IFS= read -r line; do
          issues+=("    $line")
        done <<< "$unpushed"
      fi

      # Unpulled commits (remote ahead of local)
      unpulled=$(git -C "$dir" log "HEAD..$upstream" --oneline 2>/dev/null)
      if [[ -n "$unpulled" ]]; then
        count=$(echo "$unpulled" | wc -l | tr -d ' ')
        issues+=("Unpulled commits from remote ($count):")
        while IFS= read -r line; do
          issues+=("    $line")
        done <<< "$unpulled"
      fi
    else
      issues+=("No upstream tracking branch set for '$current_branch'")
    fi
  fi

  # Stashed changes
  stash_count=$(git -C "$dir" stash list 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$stash_count" -gt 0 ]]; then
    issues+=("Stashed changes ($stash_count)")
  fi

  # Report
  if [[ ${#issues[@]} -eq 0 ]]; then
    echo "  No changes"
    CLEAN=$((CLEAN + 1))
  else
    for line in "${issues[@]}"; do
      if [[ "$line" == "    "* ]]; then
        echo "    $line"
      else
        echo "  • $line"
      fi
    done
    DIRTY=$((DIRTY + 1))
  fi

  echo ""
done

# ─────────────────── summary ───────────────────

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Scanned $TOTAL directories: $CLEAN clean, $DIRTY with changes, $NOT_GIT not git repos."
