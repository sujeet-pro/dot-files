#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# git-rewrite-emails
#
# Rewrites git author/committer emails in repo history using
# git-filter-repo and a JSON5 config file.
#
# Modes:
#   Single repo:  git-rewrite-emails [--dry-run] [--yes]
#   GitHub org:   git-rewrite-emails --org <name> [--clone-dir path] [--cleanup] [--dry-run]
#   Audit:        git-rewrite-emails --audit [--org <name>] [--noreply-only] [--clone-dir path] [--cleanup]
#
# Config (~/.config/user_scripts/git-rewrite-emails.json5):
#   target_email  — all remapped emails become this
#   target_name   — author/committer name to set
#   remap         — { "old@email": "new@email", ... }
#   ignore        — [ "ok@email", ... ]
#   prompts       — [ "substring", ... ] — ask user if email contains these
#
# Requires: git, git-filter-repo, jq, gh (for org mode)
# ─────────────────────────────────────────────────────────────

SCRIPT_NAME="git-rewrite-emails"
DEFAULT_CONFIG_DIR="$HOME/.config/user_scripts"
CONFIG_FILE=""
DRY_RUN=false
AUTO_YES=false
AUDIT=false
NOREPLY_ONLY=false
ORG=""
CLONE_DIR=""
CLEANUP=false

usage() {
  cat <<EOF
Usage:
  $SCRIPT_NAME [options]                          # run in current repo
  $SCRIPT_NAME --org <name> [options]             # run across all repos in a GitHub org

Options:
  --config FILE     Path to config (default: ~/.config/user_scripts/$SCRIPT_NAME.json5)
  --dry-run         Show what would change without rewriting
  --yes, -y         Skip confirmation prompts (requires existing config)
  --org ORG         GitHub organization — clone and rewrite all repos
  --clone-dir DIR   Directory to clone org repos into (default: ~/org-repos/<org>)
  --cleanup         Delete repos that were cloned by this run (keeps pre-existing ones)
  --audit           Scan repos and report emails found (no rewrite)
  --noreply-only    In audit mode, flag any email not matching *@users.noreply.github.com
  -h, --help        Show this help
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config)    CONFIG_FILE="$2"; shift 2 ;;
    --dry-run)      DRY_RUN=true; shift ;;
    --yes|-y)       AUTO_YES=true; shift ;;
    --audit)        AUDIT=true; shift ;;
    --noreply-only) NOREPLY_ONLY=true; shift ;;
    --org)          ORG="$2"; shift 2 ;;
    --clone-dir)    CLONE_DIR="$2"; shift 2 ;;
    --cleanup)      CLEANUP=true; shift ;;
    -h|--help)   usage ;;
    -*)          echo "Unknown option: $1"; exit 1 ;;
    *)           echo "Unexpected argument: $1"; exit 1 ;;
  esac
done

[[ -z "$CONFIG_FILE" ]] && CONFIG_FILE="$DEFAULT_CONFIG_DIR/$SCRIPT_NAME.json5"

# ─────────────────── dependency checks ───────────────────

check_dependency() {
  if ! command -v "$1" &>/dev/null; then
    echo "Error: '$1' is required but not installed."
    [[ -n "${2:-}" ]] && echo "  Install with: $2"
    exit 1
  fi
}

check_dependency "git"
check_dependency "jq" "brew install jq"
! $AUDIT && check_dependency "git-filter-repo" "brew install git-filter-repo"
[[ -n "$ORG" ]] && check_dependency "gh" "brew install gh"

# ─────────────────── config helpers ───────────────────

read_config() {
  sed -E 's://.*$::; s/,([[:space:]]*[}\]])/\1/g' "$CONFIG_FILE" | jq "$@"
}

read_config_raw() {
  sed -E 's://.*$::; s/,([[:space:]]*[}\]])/\1/g' "$CONFIG_FILE"
}

config_exists() { [[ -f "$CONFIG_FILE" ]]; }

collect_emails() {
  { git log --all --format='%ae'; git log --all --format='%ce'; } | sort -u
}

# ─────────────────── interactive config wizard ───────────────────

create_or_update_config() {
  if $AUTO_YES && ! config_exists; then
    echo "Error: --yes requires an existing config file at $CONFIG_FILE"
    exit 1
  fi

  local remap_json ignore_json prompts_json target_email target_name
  if config_exists; then
    remap_json="$(read_config '.remap // {}')"
    ignore_json="$(read_config '.ignore // []')"
    prompts_json="$(read_config '.prompts // []')"
    target_email="$(read_config -r '.target_email // ""')"
    target_name="$(read_config -r '.target_name // ""')"
  else
    remap_json="{}"
    ignore_json="[]"
    prompts_json="[]"
    target_email=""
    target_name=""
  fi

  if $AUTO_YES; then
    [[ -z "$target_email" ]] && { echo "Error: target_email not set in config."; exit 1; }
    echo "Using config: $CONFIG_FILE"
    echo "  Target: $target_name <$target_email>"
    return
  fi

  # Interactive: ask for target email
  if [[ -z "$target_email" ]]; then
    read -rp "Target email (all remapped emails become this): " target_email
    [[ -z "$target_email" ]] && { echo "Error: target email is required."; exit 1; }
  else
    echo "Target email: $target_email"
    read -rp "Keep? [Y/n]: " confirm
    [[ "$confirm" =~ ^[nN] ]] && read -rp "New target email: " target_email
  fi

  if [[ -z "$target_name" ]]; then
    read -rp "Target name (empty to keep original): " target_name
  else
    echo "Target name: $target_name"
    read -rp "Keep? [Y/n]: " confirm
    [[ "$confirm" =~ ^[nN] ]] && read -rp "New target name: " target_name
  fi

  # Review unknown emails
  local all_emails
  all_emails="$(collect_emails)"

  echo ""
  echo "Reviewing emails in history..."

  while IFS= read -r email; do
    [[ -z "$email" ]] && continue
    [[ "$email" == "$target_email" ]] && continue

    # Already known?
    if echo "$remap_json" | jq -e --arg e "$email" 'has($e)' &>/dev/null; then
      continue
    fi
    if echo "$ignore_json" | jq -e --arg e "$email" 'index($e) != null' &>/dev/null; then
      continue
    fi

    # Check prompt substrings
    local matched=false
    while IFS= read -r sub; do
      [[ -z "$sub" ]] && continue
      if [[ "$email" == *"$sub"* ]]; then
        matched=true
        echo "  '$email' matches prompt '$sub'"
        read -rp "    [r]emap / [i]gnore: " choice
        case "$choice" in
          r|R) remap_json="$(echo "$remap_json" | jq --arg e "$email" --arg t "$target_email" '. + {($e): $t}')" ;;
          *)   ignore_json="$(echo "$ignore_json" | jq --arg e "$email" '. + [$e]')" ;;
        esac
        break
      fi
    done < <(echo "$prompts_json" | jq -r '.[]')
    $matched && continue

    echo "  Unknown: $email"
    read -rp "    [r]emap / [i]gnore / [p]rompt substring: " choice
    case "$choice" in
      r|R) remap_json="$(echo "$remap_json" | jq --arg e "$email" --arg t "$target_email" '. + {($e): $t}')" ;;
      p|P)
        read -rp "    Substring: " sub
        [[ -n "$sub" ]] && prompts_json="$(echo "$prompts_json" | jq --arg s "$sub" '. + [$s]')"
        read -rp "    And this email? [r]emap / [i]gnore: " choice2
        case "$choice2" in
          r|R) remap_json="$(echo "$remap_json" | jq --arg e "$email" --arg t "$target_email" '. + {($e): $t}')" ;;
          *)   ignore_json="$(echo "$ignore_json" | jq --arg e "$email" '. + [$e]')" ;;
        esac
        ;;
      *)   ignore_json="$(echo "$ignore_json" | jq --arg e "$email" '. + [$e]')" ;;
    esac
  done <<< "$all_emails"

  # Save config
  mkdir -p "$(dirname "$CONFIG_FILE")"
  jq -n \
    --arg te "$target_email" \
    --arg tn "$target_name" \
    --argjson remap "$remap_json" \
    --argjson ignore "$ignore_json" \
    --argjson prompts "$prompts_json" \
    '{ target_email: $te, target_name: $tn, remap: $remap, ignore: $ignore, prompts: $prompts }' > "$CONFIG_FILE"

  echo "Config saved: $CONFIG_FILE"
}

# ─────────────────── build mailmap from config ───────────────────

build_mailmap() {
  local mailmap_file="$1"
  local target_email target_name
  target_email="$(read_config -r '.target_email')"
  target_name="$(read_config -r '.target_name // ""')"

  > "$mailmap_file"
  while IFS= read -r old_email; do
    [[ -z "$old_email" ]] && continue
    if [[ -n "$target_name" ]]; then
      echo "$target_name <$target_email> <$old_email>" >> "$mailmap_file"
    else
      echo "<$target_email> <$old_email>" >> "$mailmap_file"
    fi
  done < <(read_config -r '.remap | keys[]')
}

# ─────────────────── count commits with old emails ───────────────────

count_old_email_commits() {
  local old_emails
  old_emails="$(read_config -r '.remap | keys[]')"
  local count=0
  while IFS= read -r old_email; do
    [[ -z "$old_email" ]] && continue
    local hits
    hits="$(git log --all --format='%H %ae %ce' | grep -F "$old_email" | awk '{print $1}' | sort -u | wc -l | tr -d ' ')"
    count=$((count + hits))
  done <<< "$old_emails"
  echo "$count"
}

# ─────────────────── rewrite a single repo ───────────────────

rewrite_repo() {
  local repo_dir="$1"
  local origin_url="${2:-}"  # optional: re-add after filter-repo

  cd "$repo_dir"

  local total_commits
  total_commits="$(git rev-list --count --all 2>/dev/null || echo 0)"
  if [[ "$total_commits" -eq 0 ]]; then
    echo "  Empty repository, skipping."
    return 0
  fi

  # Save origin URL before filter-repo removes it
  if [[ -z "$origin_url" ]]; then
    origin_url="$(git remote get-url origin 2>/dev/null || echo "")"
  fi

  local affected
  affected="$(count_old_email_commits)"
  echo "  Commits: $total_commits total, $affected with old emails"

  if [[ "$affected" -eq 0 ]]; then
    echo "  Already clean — nothing to rewrite."
    return 0
  fi

  if $DRY_RUN; then
    echo "  [dry-run] Would rewrite $affected commits."
    return 0
  fi

  # Build mailmap
  local mailmap_file
  mailmap_file="$(mktemp)"
  build_mailmap "$mailmap_file"

  # Pass 1
  echo "  Rewriting (pass 1/2)..."
  git filter-repo --mailmap "$mailmap_file" --force --quiet 2>&1

  # Re-add origin (filter-repo removes it)
  if [[ -n "$origin_url" ]]; then
    git remote add origin "$origin_url" 2>/dev/null || true
  fi

  # Pass 2 (idempotent safety)
  echo "  Rewriting (pass 2/2)..."
  git filter-repo --mailmap "$mailmap_file" --force --quiet 2>&1

  # Re-add origin again
  if [[ -n "$origin_url" ]]; then
    git remote remove origin 2>/dev/null || true
    git remote add origin "$origin_url" 2>/dev/null || true
  fi

  rm -f "$mailmap_file"

  # Verify
  local remaining
  remaining="$(count_old_email_commits)"
  echo "  Rewrite complete: $affected updated, $remaining old emails remaining"
  if [[ "$remaining" -gt 0 ]]; then
    echo "  ⚠ Some old emails still present"
    return 1
  fi

  # Push if we have an origin
  if [[ -n "$origin_url" ]]; then
    echo "  Pushing all branches..."
    if ! git push --force --all origin 2>&1; then
      echo "  ⚠ Branch push failed."
      return 1
    fi
    echo "  Pushing tags..."
    git push --force --tags origin 2>&1 || true

    # Verify push: fetch and compare default branch
    git fetch origin --quiet 2>/dev/null || true
    local branch
    branch="$(git symbolic-ref --short HEAD 2>/dev/null || echo "")"
    if [[ -n "$branch" ]]; then
      local local_head remote_head
      local_head="$(git rev-parse HEAD 2>/dev/null || echo "")"
      remote_head="$(git rev-parse "origin/$branch" 2>/dev/null || echo "")"
      if [[ "$local_head" == "$remote_head" ]]; then
        echo "  ✓ Verified: local matches origin/$branch"
      else
        echo "  ⚠ Mismatch: local ($local_head) vs origin/$branch ($remote_head)"
        return 1
      fi
    fi
  fi

  return 0
}

# ─────────────────── org mode ───────────────────

run_org_mode() {
  [[ -z "$CLONE_DIR" ]] && CLONE_DIR="$HOME/org-repos/$ORG"

  # Verify gh auth
  if ! gh auth status &>/dev/null; then
    echo "Error: gh is not authenticated. Run 'gh auth login' first."
    exit 1
  fi

  echo "Fetching repos for org: $ORG ..."
  local repos
  repos="$(gh repo list "$ORG" --limit 1000 --json nameWithOwner,sshUrl,isArchived --jq '.[] | "\(.nameWithOwner)\t\(.sshUrl)\t\(.isArchived)"')"

  if [[ -z "$repos" ]]; then
    echo "No repos found for org '$ORG'."
    exit 0
  fi

  local repo_count
  repo_count="$(echo "$repos" | wc -l | tr -d ' ')"
  echo "Found $repo_count repos."
  echo ""

  mkdir -p "$CLONE_DIR"

  local success=0 skipped=0 failed=0
  local failed_repos=()
  local cloned_this_run=()

  while IFS=$'\t' read -r name_with_owner ssh_url is_archived; do
    local repo_name="${name_with_owner#*/}"
    local repo_dir="$CLONE_DIR/$repo_name"
    local was_archived=false

    echo "━━━ $name_with_owner ━━━"

    # Unarchive if needed
    if [[ "$is_archived" == "true" ]]; then
      was_archived=true
      if $DRY_RUN; then
        echo "  [dry-run] Would unarchive (archived repo)"
      else
        echo "  Unarchiving..."
        if ! gh repo unarchive "$name_with_owner" --yes 2>&1; then
          echo "  ⚠ Failed to unarchive, skipping."
          failed=$((failed + 1))
          failed_repos+=("$name_with_owner (unarchive failed)")
          echo ""
          continue
        fi
      fi
    fi

    # Clone or fetch
    if [[ -d "$repo_dir/.git" ]]; then
      echo "  Already cloned, fetching..."
      if ! git -C "$repo_dir" fetch --all --quiet 2>&1; then
        echo "  ⚠ Fetch failed, skipping."
        failed=$((failed + 1))
        failed_repos+=("$name_with_owner (fetch failed)")
        $was_archived && ! $DRY_RUN && gh repo archive "$name_with_owner" --yes 2>/dev/null
        echo ""
        continue
      fi
    else
      echo "  Cloning..."
      if $DRY_RUN; then
        echo "  [dry-run] Would clone $name_with_owner"
        skipped=$((skipped + 1))
        echo ""
        continue
      fi
      if ! git clone --quiet "$ssh_url" "$repo_dir" 2>&1; then
        echo "  ⚠ Clone failed, skipping."
        failed=$((failed + 1))
        failed_repos+=("$name_with_owner (clone failed)")
        $was_archived && gh repo archive "$name_with_owner" --yes 2>/dev/null
        echo ""
        continue
      fi
      cloned_this_run+=("$repo_dir")
    fi

    # Rewrite
    if rewrite_repo "$repo_dir" "$ssh_url"; then
      success=$((success + 1))
    else
      failed=$((failed + 1))
      failed_repos+=("$name_with_owner (rewrite/push failed)")
    fi

    # Re-archive if it was archived before
    if $was_archived && ! $DRY_RUN; then
      echo "  Re-archiving..."
      gh repo archive "$name_with_owner" --yes 2>/dev/null || echo "  ⚠ Failed to re-archive"
    fi

    echo ""
  done <<< "$repos"

  # Cleanup newly cloned repos if requested
  if $CLEANUP && [[ ${#cloned_this_run[@]} -gt 0 ]]; then
    echo "Cleaning up ${#cloned_this_run[@]} repos cloned this run..."
    for cdir in "${cloned_this_run[@]}"; do
      echo "  Removing $(basename "$cdir")..."
      rm -rf "$cdir"
    done
    echo ""
  fi

  # Summary
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Done. $success succeeded, $skipped skipped, $failed failed out of $repo_count repos."

  if [[ ${#failed_repos[@]} -gt 0 ]]; then
    echo ""
    echo "Failed:"
    for r in "${failed_repos[@]}"; do
      echo "  - $r"
    done
  fi
}

# ─────────────────── single repo mode ───────────────────

run_single_mode() {
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: not inside a git repository."
    exit 1
  fi

  local repo_root
  repo_root="$(git rev-parse --show-toplevel)"

  create_or_update_config

  if ! $AUTO_YES && ! $DRY_RUN; then
    echo ""
    read -rp "Proceed with rewrite? This rewrites git history! [y/N]: " confirm
    [[ "$confirm" =~ ^[yY] ]] || { echo "Aborted."; exit 0; }
  fi

  rewrite_repo "$repo_root"
}

# ─────────────────── audit helpers ───────────────────

# Audits a single repo directory. Prints emails found.
# Returns 1 if flagged emails are found (for exit code tracking).
audit_repo() {
  local repo_dir="$1"
  local repo_label="${2:-$(basename "$repo_dir")}"

  cd "$repo_dir"

  local total_commits
  total_commits="$(git rev-list --count --all 2>/dev/null || echo 0)"
  if [[ "$total_commits" -eq 0 ]]; then
    echo "  (empty repo)"
    return 0
  fi

  local all_emails
  all_emails="$(collect_emails)"

  local has_flagged=false

  if $NOREPLY_ONLY; then
    # Flag anything not matching GitHub noreply pattern
    local noreply_pattern="@users\.noreply\.github\.com$"
    while IFS= read -r email; do
      [[ -z "$email" ]] && continue
      if [[ ! "$email" =~ $noreply_pattern ]]; then
        local commit_count
        commit_count="$(git log --all --format='%H %ae %ce' | grep -F "$email" | awk '{print $1}' | sort -u | wc -l | tr -d ' ')"
        echo "  ⚠ $email ($commit_count commits)"
        has_flagged=true
      fi
    done <<< "$all_emails"

    if ! $has_flagged; then
      echo "  ✓ All emails are noreply"
    fi
  else
    # Report all emails with commit counts
    while IFS= read -r email; do
      [[ -z "$email" ]] && continue
      local commit_count
      commit_count="$(git log --all --format='%H %ae %ce' | grep -F "$email" | awk '{print $1}' | sort -u | wc -l | tr -d ' ')"

      # Check if this email is in the remap list
      local marker="  "
      if config_exists; then
        if read_config -e --arg e "$email" '.remap | has($e)' &>/dev/null; then
          marker="⚠ "
          has_flagged=true
        fi
      fi
      echo "  ${marker}$email ($commit_count commits)"
    done <<< "$all_emails"
  fi

  $has_flagged && return 1
  return 0
}

run_audit_single() {
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: not inside a git repository."
    exit 1
  fi

  local repo_root
  repo_root="$(git rev-parse --show-toplevel)"
  local repo_name
  repo_name="$(basename "$repo_root")"

  echo "━━━ $repo_name ━━━"
  audit_repo "$repo_root" "$repo_name"
}

run_audit_org() {
  [[ -z "$CLONE_DIR" ]] && CLONE_DIR="$HOME/org-repos/$ORG"

  if ! gh auth status &>/dev/null; then
    echo "Error: gh is not authenticated. Run 'gh auth login' first."
    exit 1
  fi

  echo "Fetching repos for org: $ORG ..."
  local repos
  repos="$(gh repo list "$ORG" --limit 1000 --json nameWithOwner,sshUrl,isArchived --jq '.[] | "\(.nameWithOwner)\t\(.sshUrl)\t\(.isArchived)"')"

  if [[ -z "$repos" ]]; then
    echo "No repos found for org '$ORG'."
    exit 0
  fi

  local repo_count
  repo_count="$(echo "$repos" | wc -l | tr -d ' ')"
  echo "Found $repo_count repos."
  echo ""

  mkdir -p "$CLONE_DIR"

  local clean=0 flagged=0 skipped=0
  local flagged_repos=()
  local cloned_this_run=()

  while IFS=$'\t' read -r name_with_owner ssh_url is_archived; do
    local repo_name="${name_with_owner#*/}"
    local repo_dir="$CLONE_DIR/$repo_name"

    echo "━━━ $name_with_owner ━━━"

    # Clone if needed (no need to unarchive for clone — archived repos are still cloneable)
    if [[ -d "$repo_dir/.git" ]]; then
      git -C "$repo_dir" fetch --all --quiet 2>/dev/null || true
    else
      if ! git clone --quiet "$ssh_url" "$repo_dir" 2>&1; then
        echo "  ⚠ Clone failed, skipping."
        skipped=$((skipped + 1))
        echo ""
        continue
      fi
      cloned_this_run+=("$repo_dir")
    fi

    if audit_repo "$repo_dir" "$name_with_owner"; then
      clean=$((clean + 1))
    else
      flagged=$((flagged + 1))
      flagged_repos+=("$name_with_owner")
    fi

    echo ""
  done <<< "$repos"

  # Cleanup
  if $CLEANUP && [[ ${#cloned_this_run[@]} -gt 0 ]]; then
    echo "Cleaning up ${#cloned_this_run[@]} repos cloned this run..."
    for cdir in "${cloned_this_run[@]}"; do
      rm -rf "$cdir"
    done
    echo ""
  fi

  # Summary
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Audited $repo_count repos: $clean clean, $flagged flagged, $skipped skipped."

  if [[ ${#flagged_repos[@]} -gt 0 ]]; then
    echo ""
    echo "Repos with flagged emails:"
    for r in "${flagged_repos[@]}"; do
      echo "  - $r"
    done
  fi
}

# ─────────────────── main ───────────────────

echo "╔═══════════════════════════════════════════════════╗"
echo "║         Git Email Rewrite Tool                    ║"
echo "╚═══════════════════════════════════════════════════╝"
echo ""

if $AUDIT; then
  if [[ -n "$ORG" ]]; then
    run_audit_org
  else
    run_audit_single
  fi
  exit 0
fi

if ! config_exists; then
  if [[ -n "$ORG" ]]; then
    echo "Error: config file required for org mode."
    echo "  Run once in a single repo first to create the config,"
    echo "  or create it manually at: $CONFIG_FILE"
    exit 1
  fi
fi

if [[ -n "$ORG" ]]; then
  AUTO_YES=true  # org mode is always non-interactive
  run_org_mode
else
  run_single_mode
fi
