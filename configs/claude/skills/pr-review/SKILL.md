---
name: pr-review
description: Exhaustive Bitbucket PR code review with interactive comment approval
user-invocable: true
---

# Bitbucket PR Code Review

You are performing an exhaustive code review on a Bitbucket pull request. Follow this multi-phase workflow exactly.

## Phase 0: Pre-flight Checks

Before anything else, verify the local environment is ready:

1. **Confirm you are inside a git repository.** Run `git rev-parse --show-toplevel`. If this fails, stop and tell the user they must run the command from within a git repo.
2. **Confirm there are no uncommitted changes.** Run `git status --porcelain`. If there is any output (staged, unstaged, or untracked files that matter), stop and tell the user to commit, stash, or discard their local changes before proceeding.
3. Parse the PR URL (see Phase 1) and fetch PR details to determine the **source branch**.
4. **Switch to the PR's source branch and sync with origin:**
   - `git fetch origin`
   - `git checkout {source_branch}`
   - `git reset --hard origin/{source_branch}` — ensure the local branch exactly matches the remote
5. Confirm the checkout succeeded. If it fails, report the error and stop.

## Phase 1: Parse Input & Fetch PR

The user's argument is a Bitbucket PR URL (e.g. `https://bitbucket.org/{workspace}/{repo}/pull-requests/123` or with trailing segments like `/diff`, `/activity`).

1. Parse the URL to extract `workspace`, `repo_slug`, and `pull_request_id`:
   - Pattern: `https://bitbucket.org/{workspace}/{repo_slug}/pull-requests/{pull_request_id}[/...]`
2. Use `mcp__bitbucket__getPullRequest` to fetch the PR details with the extracted `workspace`, `repo_slug`, and `pull_request_id`.
3. Display a summary:
   ```
   **PR #{id}: {title}**
   Author: {author}
   Branch: {source_branch} -> {destination_branch}
   State: {state}
   ```

## Phase 2: Fetch Diff & Perform Exhaustive Review

1. Use `mcp__bitbucket__getPullRequestDiff` to fetch the full diff with the same `workspace`, `repo_slug`, and `pull_request_id`.
2. **Scope guard:** Build a list of files changed in the PR diff. All review comments MUST be limited to these files only. Do NOT flag issues in files outside the diff, even if the PR's changes interact with them.
3. Analyze the diff **exhaustively**. For every changed file and every changed line, look for issues across ALL of these categories:

   ### Code Quality & Data Flow
   - Incorrect conditions, off-by-one errors, null/undefined access, race conditions, wrong variable usage
   - Poor naming, DRY violations, readability issues, excessive complexity, dead code
   - Missing types, incorrect casts, `any` usage, type narrowing gaps
   - Missing error handling, boundary conditions, empty states, loading states
   - Data flow correctness — are values transformed, passed, and consumed correctly end-to-end?

   ### Security
   - XSS, injection (SQL, command, template), exposed secrets, unsafe patterns, missing sanitization
   - Insecure deserialization, broken access control, CSRF, SSRF
   - Sensitive data exposure in logs, error messages, or client bundles

   ### Accessibility (a11y)
   - Missing or incorrect ARIA attributes, roles, labels
   - Keyboard navigation gaps, focus management issues
   - Color contrast, screen reader compatibility, semantic HTML misuse

   ### Architecture
   - Violations of existing architectural patterns in the codebase
   - Tight coupling, wrong layer for the logic, separation of concerns issues
   - Missing abstraction or premature abstraction
   - Impact on testability, maintainability, and scalability

   ### Performance
   - Unnecessary re-renders, N+1 queries, missing memoization
   - Expensive operations in loops, bundle size impact
   - Missing pagination, unbounded data fetching

4. Build an internal list of review comments. Each comment must have:
   - `file`: the file path (relative, as shown in the diff)
   - `line`: the line number in the **new** version of the file (the `to` line)
   - `snippet`: the relevant code snippet (1-3 lines)
   - `severity`: one of the tags below
   - `comment`: a clear, actionable review comment explaining the issue and suggesting a fix

### Severity Tags

Every comment MUST be tagged with exactly one of these severity levels:

| Tag | Meaning |
|-----|---------|
| **CRITICAL** | Bug, security vulnerability, data loss risk, or broken functionality — must fix before merge |
| **WARNING** | Likely problem that could cause issues in production — strongly recommended to fix |
| **SUGGESTION** | Improvement to code quality, readability, or maintainability — recommended but not blocking |
| **NICE-TO-HAVE** | Minor polish, stylistic preference, or optional enhancement — take it or leave it |
| **QUESTION** | Clarification needed — reviewer does not fully understand the intent and wants confirmation |

### Accuracy Guidelines

Before finalizing each comment, double-check:
- Is the line number correct? Cross-reference with the diff hunk headers.
- Is the issue real? Re-read the surrounding context (at least 10 lines above and below) to make sure you are not misunderstanding the code.
- Is the suggestion valid? Make sure your proposed fix would actually compile/run and not introduce new issues.
- Could this be intentional? Consider whether the author may have a reason for the pattern — if so, use **QUESTION** instead of flagging it as a bug.

If no issues are found, skip to Phase 5 (approve the PR).

## Phase 3: Interactive Batch Review

Present ALL comments at once for fast triage. Format the list as a numbered table:

```
## Review Summary: {N} comments found

| # | Severity | File | Line | Issue |
|---|----------|------|------|-------|
| 1 | CRITICAL | src/foo.ts | 42 | Null pointer access on `user.name` |
| 2 | WARNING | src/bar.ts | 17 | Missing error handling in API call |
| 3 | SUGGESTION | src/baz.ts | 88 | Consider extracting to a helper |
| ... | ... | ... | ... | ... |
```

Then, for each comment, show the full detail below the table:

```
### Comment #{n} [{severity}]
**File:** `{file}` **Line:** {line}
**Code:**
\`\`\`
{snippet}
\`\`\`
**Comment:** {comment}
```

Then use `AskUserQuestion` to present these options:

1. **Accept All** — post every comment as-is
2. **Reject All** — discard all comments, skip to Phase 5
3. **Select** — provide a comma-separated list of comment numbers to accept as-is (e.g. `1,3,5`). The remaining comments will be presented one-by-one in Phase 3b.

### Phase 3b: Individual Review of Remaining Comments

For each comment NOT accepted or rejected in the batch step, present it one at a time using `AskUserQuestion`:

```
**[{severity}] Comment #{n} of {remaining}**
**File:** `{file}` **Line:** {line}
**Code:**
\`\`\`
{snippet}
\`\`\`
**Comment:** {comment}
```

Options:
1. **Accept** — post this comment as-is
2. **Reject** — discard this comment
3. **Edit** — provide instructions to modify the comment

**If the user chooses "Edit":**
- The user provides modification instructions (a prompt) in their response.
- Rewrite the comment based on those instructions.
- Display the updated comment and present Accept/Edit/Reject again.
- Repeat until the user either Accepts or Rejects.

After all comments have been reviewed, display a summary:
```
Review complete: {N} approved, {M} rejected, {E} edited & approved
```

If no comments were approved, skip to Phase 5.

## Phase 4: Post Approved Comments to Bitbucket

For each approved comment, post it as an **inline** comment. The comment body must be prefixed with the severity tag in bold, e.g.:

```
**[CRITICAL]** Your comment text here...
```

### Posting Strategy: MCP with Retry, then API Fallback

**Attempt 1 — MCP inline comment:**
Use `mcp__bitbucket__addPullRequestComment` with:
- `workspace`, `repo_slug`, `pull_request_id`: from Phase 1
- `content`: the severity-tagged comment text (markdown formatted)
- `inline`: `{ "path": "{file}", "to": {line} }` — this attaches the comment to the specific line
- `pending`: `false` — post immediately

**If Attempt 1 fails — Attempt 2 — MCP retry:**
Retry the exact same `mcp__bitbucket__addPullRequestComment` call once more.

**If Attempt 2 fails — Attempt 3 — REST API fallback:**
Use the Bitbucket REST API directly via `curl` or equivalent:
```
POST https://api.bitbucket.org/2.0/repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/comments
Content-Type: application/json

{
  "content": { "raw": "{severity-tagged comment}" },
  "inline": { "path": "{file}", "to": {line} }
}
```
The comment MUST still be inline. Never fall back to a non-inline (general PR) comment.

Report the result of each comment: posted successfully, or failed after all attempts (with error details).

After posting all comments, display a final summary:
```
Posted {X}/{Y} comments to PR #{id}. ({F} failed)
```

## Phase 5: Set PR Status

After all comments are handled:

- **If 1 or more comments were posted** (any severity), use `mcp__bitbucket__updatePullRequest` or the appropriate MCP/API call to **request changes** on the PR. Display:
  ```
  PR #{id} marked as **Changes Requested**.
  ```

- **If zero comments were posted** (either none found or all rejected), **approve** the PR using `mcp__bitbucket__approvePullRequest`. Display:
  ```
  PR #{id} **Approved**. No issues found.
  ```

## Important Notes

- Be thorough — do not skip files or gloss over changes. Review every meaningful change.
- Be specific — reference exact variable names, line numbers, and code patterns.
- Be actionable — every comment should clearly explain what's wrong and how to fix it.
- Do NOT post comments the user has not explicitly approved.
- Do NOT flag issues in files outside the PR diff.
- If a tool call fails (e.g. posting a comment), report the error and continue with the remaining comments.
- Always switch back to the original branch after the review is complete: `git checkout {original_branch}`.
