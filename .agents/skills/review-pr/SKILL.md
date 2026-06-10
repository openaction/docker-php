---
name: review-pr
description: Review a GitHub pull request by number with GitHub CLI. Use when asked to review, analyze, or check a PR (for example "review PR #123", "code review pull request 123", or "check this PR"). Check out the PR branch in the current repository with `gh pr checkout`, inspect metadata/diff/comments/commits/checks with `gh`, analyze findings by severity, return the review in chat, and post the same review on GitHub with `gh pr review`.
---

# Review PR

Review one pull request deeply, publish actionable findings, and submit the
review on GitHub in the same run.

## Inputs

Require:
- PR number (integer)

Optional:
- Repository (`owner/repo`); default to current repository from `gh repo view`
- Review mode override: `approve`, `comment`, or `request-changes`

## Workflow

1. Resolve repository and validate CLI/auth:
   - `gh auth status`
   - `gh repo view --json nameWithOwner -q .nameWithOwner`
2. Check out the PR branch in the current repository.
3. Fetch and read metadata, diff, commits, reviews, comments, and checks.
4. Analyze using `references/review-criteria.md`.
5. Produce a structured review with priorities:
   - `Blocker`
   - `Important`
   - `Nit`
   - `Question`
   - `Praise`
6. Return the review text in chat.
7. Post the same text to GitHub using `gh pr review`.
8. Confirm what was posted (mode + PR URL + summary counts).

## Command Pattern

```bash
PR="<number>"
REPO="${REPO:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"

gh pr checkout "$PR" --repo "$REPO"

gh pr view "$PR" --repo "$REPO" \
  --json number,title,body,url,isDraft,author,baseRefName,headRefName,headRefOid, \
changedFiles,additions,deletions,commits,labels,assignees,reviewDecision \
  > pr-metadata.json

gh pr diff "$PR" --repo "$REPO" > pr-diff.patch
gh pr checks "$PR" --repo "$REPO" > pr-checks.txt || true
gh api --paginate "repos/$REPO/pulls/$PR/comments?per_page=100" \
  > pr-inline-comments.json
gh api --paginate "repos/$REPO/pulls/$PR/reviews?per_page=100" \
  > pr-reviews.json
```

## Review Output Format

Use this structure both in chat and in the GitHub review body:

```markdown
## Summary
<1-3 lines overall assessment>

## Findings
### Blocker
- [path:line] <issue, impact, how to fix>

### Important
- [path:line] <issue, impact, how to fix>

### Nit
- [path:line] <optional improvement>

## Questions
- <clarification question>

## Positive Notes
- <what is good>
```

Skip empty sections except `Summary` and `Findings`.

## Posting Rules

Always post the content as a GitHub comment (not an approval/refusal):

```bash
gh pr review "$PR" --repo "$REPO" --comment --body-file pr-review.md
```

For targeted inline comments, use:

```bash
gh api "repos/$REPO/pulls/$PR/comments" \
  -f body='Use a parameterized query here.' \
  -f commit_id='<head-sha>' \
  -f path='src/file.php' \
  -F line=42
```

## Guardrails

- Use only `gh` plus local git/shell commands; do not rely on external review services.
- Cite concrete file paths and line numbers for every non-trivial finding.
- Focus on correctness, regressions, security, tests, and maintainability first.
- Keep tone direct, specific, and respectful.
