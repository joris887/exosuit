---
name: sprint-end
version: 2.9.0
description: Use when the user wants to ship a sprint's work to main via PR.
trigger: manual
depends-on: [code-quality, test-validator, security-audit]
references: [references/quality-gates.md, references/error-recovery.md]
micro-components:
  step-1: [discover-commands, verify-clean-git-state]
  step-2: [quality-gate-sequence]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Edit, Write
---
______________________________________________________________________

## sprint-end

Ending the sprint. Discovering and wrapping up all work on the current branch.

**Progress tracking:** Create step-level tasks:

1. "Discover sprint state" — activeForm: "Discovering sprint state..."
2. "Run quality gates" — activeForm: "Running quality gates..." — blockedBy: [1]
3. "Update documentation" — activeForm: "Updating docs..." — blockedBy: [2]
4. "Push and create PR" — activeForm: "Creating PR..." — blockedBy: [3]
5. "Wait for CI" — activeForm: "Waiting for CI..." — blockedBy: [4]
6. "Merge and clean up" — activeForm: "Merging to main..." — blockedBy: [5]

At each step boundary, mark current task completed and next task in_progress.

## Process Flow (authoritative — prose below is supporting detail)

```
START → 1. Discover Sprint State (from git, no assumptions)
  → [On main or no commits?] → STOP (nothing to ship)
  → 2. Quality Gates (tests, test protection, quality agents)
    → [All gates pass?]
      → NO: Fix issues → re-run gates
      → YES: 3. Documentation Updates (epics, backlog, progress)
        → 4. Push and Create PR
          → 5. Wait for CI
            → [CI green?]
              → NO: Fix → push → re-check
              → YES: 6. Merge and Clean Up (squash, delete branch, worktree)
                → 7. Sprint Complete Summary → DONE
```

## 1. Discover Sprint State

No assumptions about previous context. Discover everything from git.

**Check story completion status:** Read `docs/progress.md` for the current story status. If it shows a phase earlier than "DONE" (e.g., "Phase 3 — tests pass, self-review pending"), the last story was only partially completed. Factor this into quality gates — run the missing steps as part of sprint-end rather than flagging them as new issues.

Discover from git:

```bash
git branch --show-current
git log main..HEAD --oneline
git diff --stat main...HEAD
git diff --name-only main...HEAD
```

**If on main:** There is no sprint to end. Inform user and stop.

**If no commits ahead of main:** Nothing to ship. Inform user and stop.

**If in a worktree:** Detect with `git rev-parse --git-common-dir`. Note the worktree path for cleanup in step 6.

Analyze: branch name, all commits since branching, all files changed, stories completed (parse from commit messages).

## 2. Quality Gates

**Mindset:** Assume there are problems. Your job is to find them. Your first assessment is almost never "all clear."

Before running gates, present available checks using AskUserQuestion with `multiSelect: true`:

- **Run test suite** — description: "Execute all tests, verify zero failures"
- **Test count protection** — description: "Verify test count did not decrease from last sprint"
- **Code quality analysis** — description: "Complexity, duplication, patterns via code-quality agent"
- **Test quality validation** — description: "Coverage, TDD compliance via test-validator agent"
- **Security audit** — description: "CWE checklist, phantom packages, secrets via security-audit agent"
- **Ground rules compliance** — description: "Check against GROUND_RULES.md principles"

All gates selected by default. If the user deselects any: "Note: skipping gates may allow issues to reach main. All gates recommended for production sprints."

Run only selected gates. The HARD-GATE still applies: if any selected gate fails, do NOT proceed.

Read `references/quality-gates.md` for detailed checks (tests, test protection, quality agents with scope-based scaling, recovery). For error recovery during this step, consult `references/error-recovery.md` — search for `## Step 2`.

<IF condition="docs/reference/GROUND_RULES.md exists and has principles defined">
**Ground rules compliance:** Verify sprint changes don't introduce untracked ground rules violations. Check commit diffs against MUST principles. Any violations must have been documented in story plans with justification.

**Compliance ledger:** After checking, record results in `docs/progress.md` under the `## Ground Rule Compliance` section:

```markdown
| Sprint | Rules Checked | Violations | Details |
|--------|--------------|------------|---------|
| N      | X/Y          | Z          | [description or "Clean"] |
```

This builds a longitudinal compliance profile. Over time, frequently violated rules may need reinforcement or clarification; never-tested rules may be dead rules to review.
</IF>

<HARD-GATE>
Do NOT proceed to documentation updates, PR creation, or merge if ANY quality gate has failed. All gates must pass. "It's probably fine" is not a pass.
</HARD-GATE>

## 3. Documentation Updates

Based on what was done in the sprint, update relevant documentation:

- **Epic file** (`docs/reference/backlog/E##-*.md`): Mark completed stories as `[DONE]`
- **BACKLOG_INDEX.md**: Update Done/In Progress/TODO counts
- **progress.md**: Add sprint entry, update metrics
- **CLAUDE.md**: Update Current Focus if epic status changed
- **Project context** (`docs/context/`): If sprint changes affect architecture, patterns, or tech stack, incrementally update the relevant context files (use `git diff main...HEAD --name-only` to identify affected areas). Update `updated:` timestamps in YAML frontmatter.

Commit documentation updates:

```bash
git add docs/ CLAUDE.md
git commit -m "docs: update progress and backlog for sprint completion"
```

## 4. Push and Create PR

```bash
git push -u origin $(git branch --show-current)
```

Create PR with GitHub CLI. The repository includes a PR template (`.github/pull_request_template.md`) — fill in its sections rather than providing a raw body:

```bash
gh pr create --title "<type>(<scope>): <summary>" --body "$(cat <<'EOF'
## Type of Change

- [x] <matching type from template>

## Summary
<1-3 sentences summarizing what was done and why>

## Changes
<list of key changes, grouped by area>

## Test Evidence
<paste test output from step 2>

## Quality Gates
- [x] All tests pass
- [x] Test count did not decrease
- [x] Code quality agent reviewed
- [x] Test validator agent reviewed
- [x/n/a] Security audit reviewed
- [x] No hardcoded secrets introduced
- [x] Coding standards followed

## Self-Review Checklist
- [x] I read the diff and it matches the intent
- [x] No debug code or TODOs left behind
- [x] Error handling is appropriate
- [x] New code follows existing patterns
- [x/n/a] Documentation updated where needed

Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

## 5. Wait for CI

<IF condition="CI is configured (.github/workflows/, .gitlab-ci.yml, etc. detected)">
```bash
gh pr checks --watch
```
If CI fails, diagnose and fix. Commit fixes and push.

**Note:** The framework includes a Claude PR Review workflow (`.github/workflows/claude-pr-review.yml`). If configured with an `ANTHROPIC_API_KEY` secret, it runs automated code review on PRs. Check its status alongside other CI checks.
</IF>
<ELSE>
No CI detected — the local quality gates in step 2 serve as verification. Proceed to merge.
</ELSE>

## 6. Merge and Clean Up

Once CI is green (or local gates passed) and any required reviews are complete:

```bash
gh pr merge --squash --delete-branch
git checkout main
git pull origin main
```

**Worktree cleanup** (if running in a worktree detected in step 1):

```bash
WORKTREE_PATH=$(pwd)
cd <main-worktree-path>
git worktree remove "$WORKTREE_PATH"
git worktree prune
```

Inform the user that the worktree has been removed and they should close the Claude Code instance that was using it.

Verify clean state:

```bash
git status
git log --oneline -3
```

## 7. Sprint Complete

```markdown
### Sprint Complete

**Branch:** `sprint-<number>` (merged and deleted)
**PR:** #<number> (<url>)
**Stories delivered:** [list]
**Commits squashed:** [count]
**Tests:** [total count] passing ([delta] vs main)
**Documentation:** Updated [list of docs updated]

**Main is clean and up to date.**

**Next Steps:**
→ `/sprint-start` — begin the next sprint
→ `/retrospective` — review what worked and what to improve
→ `/handoff` — if ending the session
```

## Graceful Degradation

| Dependency   | If Missing                                          |
|--------------|-----------------------------------------------------|
| Sub-agents   | Run quality checks manually in the main context     |
| CI pipeline  | Local quality gates (step 2) serve as verification  |
| Test runner  | Warn user, skip test count delta, note in PR body   |
| Linter       | Skip lint check, note in PR body                    |
| Type checker | Skip typecheck, note in PR body                     |
| `gh` CLI     | Push manually, create PR via web UI                 |

## Project State Adaptation

Read CLAUDE.md Commands section before running quality gates (or use the `discover-commands` micro-component from `.claude/prompts/discover-commands.md`):

<IF condition="test command exists in CLAUDE.md Commands">
Run full test suite as part of quality gates.
</IF>
<ELSE>
Skip test gate, note "No test command configured" in PR body.
</ELSE>

<IF condition="build command exists in CLAUDE.md Commands">
Include build verification in quality gates.
</IF>
<ELSE>
Skip build step.
</ELSE>

## Rules

- NEVER merge without CI passing (or local gates if no CI)
- NEVER force push or skip hooks
- NEVER merge without running quality agents
- NEVER merge if test count decreased (without explicit user approval)
- ALWAYS discover state from git — assume no prior context
- ALWAYS update documentation for completed stories
- ALWAYS squash merge to keep main history clean
- ALWAYS clean up worktrees after merge
- Follow coding standards in `docs/reference/CODING_STANDARDS.md`
