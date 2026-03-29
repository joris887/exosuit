# Phase 3: Execute by Story Type

Reference loaded by `/story-cycle` Phase 3. Contains implementation execution details.

## 3a. Parallel Stream Analysis (Optional)

<IF condition="story is STANDARD size AND risk is Low or Medium (3-6) AND plan identifies ≥2 independent work units">
Analyze the approved plan for parallel execution opportunities. Read `references/parallel-streams.md` for the full protocol.

1. Map each work unit to its file scope (which files it creates/modifies)
2. Check for file overlaps — if ANY file appears in multiple streams, merge those streams
3. If ≥2 non-overlapping streams exist, present the stream analysis to the user
4. If user approves: create worktrees per stream, dispatch agents, coordinate merges
5. If user declines or streams overlap: proceed to serial Phase 3
</IF>
<ELSE>
Skip — proceed directly to Phase 3.
</ELSE>

## Session Recovery

The Stop hook auto-saves git state to `docs/sessions/.auto-save.md` (branch, recent commits, uncommitted files). The `/continue` skill uses this plus git state to resume interrupted workflows. No manual state file management needed.

## 3.pre. Git Checkpoint

Before writing any implementation code, create a checkpoint so the entire implementation can be cleanly rolled back if verification fails:

```bash
git tag "story-checkpoint-$(date +%s)" HEAD
```

Record the tag name in `.failure-state.md` under a `checkpoint_tag` field. This tag is used by Phase 4 if verification fails — see "Checkpoint Rollback" in Phase 4d.

On successful story completion (Phase 4e commit), delete the checkpoint tag:
```bash
git tag -d "story-checkpoint-*"  # Clean up
```

## Intermediate Commits During Implementation

After each completed TDD cycle (test written → implementation passes → tests green), create an intermediate commit:

```bash
git add <changed-files>
git commit -m "<type>(<scope>): <description of this unit>"
```

These intermediate commits:
- **Prevent data loss** if the session crashes mid-implementation
- Provide natural rollback points within a story
- Are **squashed at sprint-end** anyway — commit freely during development
- Should each leave the codebase in a working state (tests pass)

For TRIVIAL and SMALL stories, a single commit at Phase 4e is sufficient.

In `references/story-types.md`, search for the `## [Your Story Type]` heading matching Phase 1 — load only that section, not the entire file.

Before writing the first test, apply the `test_strategy_selection` reasoning tool from `references/reasoning-tools.md`.

<HARD-GATE>
**TDD Ordering Enforcement (Feature, Bug Fix, Refactoring stories):**

For story types that require tests (Feature, Bug Fix, Refactoring), you MUST write and run test code BEFORE writing implementation code. This is not optional — it is the framework's #1 principle.

**Feature stories (RED-GREEN-REFACTOR):**
1. Write a failing test for the first behavior (RED) — run it, show the failure output
2. Only THEN write the minimum implementation to make it pass (GREEN)
3. Refactor while keeping tests green
4. Repeat for each behavior in the acceptance criteria

**Bug Fix stories:**
1. Write a reproduction test that captures the bug (must FAIL) — run it, show the failure output
2. Only THEN implement the fix
3. Verify the reproduction test now passes

**Refactoring stories:**
1. Write characterization tests that capture current behavior (must PASS) — run them, show the output
2. Only THEN perform the refactoring
3. Verify characterization tests still pass after each step

**What "before" means concretely:** The first `Edit` or `Write` call to a source file (non-test) MUST be preceded by at least one `Edit` or `Write` call to a test file, AND a `Bash` call that ran the test and showed output. If you find yourself about to edit a source file without having written and run a test first, STOP and write the test.

**Exceptions:** Spike/Research, Infrastructure, Documentation, Testing, Performance, Security, Skill/Tooling stories follow their own methodology from `references/story-types.md` and are not subject to this gate.
</HARD-GATE>

When errors occur during execution, consult `references/error-recovery.md` — search for `## Phase 3` for the recovery table.

## Web-Assisted Error Recovery

When a build error, test failure, or runtime exception involves an **external library** (not internal logic), use the research engine before guessing:

**Trigger:** Error message contains a library name, unfamiliar API, or stack trace pointing outside the project's source tree. Does NOT trigger for purely internal logic errors (wrong variable, missing import of own module, etc.).

**Protocol:** Compose the `deep-research` methodology (`.claude/prompts/deep-research.md`) at **QUICK** depth:

- **Sub-questions** (1-2, generated from the error):
  1. "What does [error message snippet] mean in [library/framework] [version]?"
  2. "How to fix [error pattern] in [library] [version]?"
- **Output format:** `evidence-check` (fix or workaround with source citation)
- Apply the fix if found. If no results: fall back to normal error recovery (re-read code, check types, etc.)

**Time budget:** Max 60 seconds of web research per error. If nothing useful surfaces, move on — don't spiral.

**Bug fix stories — proactive search:** For bug fix story types, search the error pattern at the START of Phase 3 (before attempting a fix), not just after failure. The error message is the most valuable search query you have — use it early. See `references/story-types.md` for the updated Bug Fix workflow.
