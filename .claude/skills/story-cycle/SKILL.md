---
name: story-cycle
version: 2.4.0
description: Use when the user wants to implement a single story or deliver a backlog item.
trigger: manual
depends-on: [code-quality, test-validator, security-audit]
references: [references/story-types.md, references/self-review.md]
---
______________________________________________________________________

## name: story-cycle description: Use when the user wants to implement a single story or deliver a backlog item. argument-hint: <story-description-or-id> disable-model-invocation: true user-invocable: true allowed-tools: Read, Glob, Grep, Bash, Edit, Write

Delivering story: **$ARGUMENTS**

## Process Flow (authoritative — prose below is supporting detail)

```
START → Phase 1: Plan Mode (research, identify type, write plan)
  → [User approved?]
    → NO: Revise plan → back to approval
    → YES: Phase 2: Context Transition (keep insights, discard bulk)
      → Phase 3: Execute by Story Type (TDD/reproduce/characterize/etc.)
        → Phase 3.5: Self-Review (completeness, quality, testing, discipline)
          → [Review passes?]
            → NO: Fix issues → back to Phase 3
            → YES: Phase 4: Wrap Up (tests, docs, commit, report)
              → DONE
```

## Phase 1: Story Analysis (Plan Mode)

Enter plan mode to research and design the approach.

### 1a. Identify Story Type

Determine the story type from the description, backlog entry, or user input:

| Type               | Indicators                                         | Approach                                   |
| ------------------ | -------------------------------------------------- | ------------------------------------------ |
| **Feature**        | New user-facing capability, "As a user..."         | TDD: RED-GREEN-REFACTOR                    |
| **Bug Fix**        | Defect, "fix", error report, reproduction steps    | Reproduce → Test → Fix → Verify            |
| **Refactoring**    | "Refactor", "restructure", no behavior change      | Characterization tests → Refactor → Verify |
| **Spike/Research** | "Investigate", "evaluate", "prototype", time-boxed | Explore → Document → Decide                |
| **Infrastructure** | CI/CD, tooling, build, config, environment         | Plan → Implement → Smoke Test              |
| **Testing**        | "Add tests", "coverage", "E2E tests"               | Design strategy → Generate → Validate      |
| **Documentation**  | "Document", "write docs", "update README"          | Gather → Generate → Review                 |
| **Security**       | "Harden", "audit", "vulnerability", "encrypt"      | Threat model → Implement → Audit           |
| **Performance**    | "Optimize", "benchmark", "speed up", "latency"     | Baseline → Optimize → Benchmark            |
| **Skill/Tooling**  | "Create skill", "add tool", "developer experience" | Design → Build → Document                  |

If unclear, ask the user to clarify the story type.

### 1b. File Discovery (Context Optimization)

Before deep-reading files, dispatch a lightweight Explore agent to identify the most relevant files:

**Agent task:** "Given this story: [description]. And this project architecture: [read ARCHITECTURE.md]. Identify the 5–10 files most relevant to implementing this story. Return ONLY file paths with a one-line explanation of why each matters. Do NOT return file contents."

Read ONLY the files the agent identified. If during implementation you need additional files, read them then — don't front-load.

**If sub-agents are NOT available:** Explore manually, but be selective — read file listings and imports first to narrow down before reading full files.

### 1c. Research Codebase

- Deep-read the files identified in step 1b
- Understand patterns, conventions, and existing tests in the area
- Identify files to modify and files to create

### 1d. Define Required Skills

Determine which skills benefit this story. If the story metadata already defines skills, use those. Otherwise select from:

| Skill               | Load When                                             |
| ------------------- | ----------------------------------------------------- |
| `/code-quality`     | Feature, refactoring, infrastructure stories          |
| `/test-validator`   | Feature, bug fix, testing stories                     |
| `/security-audit`   | Security stories, code touching auth/credentials/data |

### 1e. Write the Plan

Keep the plan concise — **under 50 lines**. Save complex plans to `docs/plans/` for persistence across compaction. Reference files by path rather than inlining content.

Write a plan covering:

- **Story type** and methodology to use
- **Files to modify/create** (specific paths)
- **Testing strategy** (what tests, where, what approach)
- **Skills to load** during execution
- **Acceptance criteria** (how to verify completion)
- **Non-goals** — what is explicitly out of scope

**CRITICAL — Story-Cycle Context Preservation:**

After plan approval, context resets and only the plan survives. The plan MUST start with a "Story-Cycle Context" section so Claude Code knows what workflow it's in and what steps remain. Use this exact format at the TOP of the plan:

```markdown
## Story-Cycle Context

This plan is part of a `/story-cycle` execution. After implementing the plan below, complete these remaining story-cycle steps:

1. **Run tests:** Use the project's test command (from CLAUDE.md Commands section)
2. **Update documentation** if the story's AC requires it
3. **Commit:** Stage relevant files and commit with conventional format: `<type>(<scope>): <description>`
4. **Do NOT merge or create PR** — that's `/sprint-end`'s job
5. **Print completion report** with: story description, type, approach, files modified, test count, and commit hash

### File Context (accumulates across compactions)
<files-read>
[List all files read during planning — one path per line]
</files-read>
<files-modified>
[Update as files are modified during execution — one path per line]
</files-modified>

When context compacts, MERGE new file paths into these lists — never discard previous entries.
```

For complex stories, use `ultrathink` to reason through architectural decisions before writing the plan.

Present the plan for user approval.

<HARD-GATE>
Do NOT write any implementation code, edit source files, or take any implementation action until the plan has been presented and the user has explicitly approved it. "I already know what to do" is NOT approval. Wait for the user.
</HARD-GATE>

## Phase 2: Context Transition

After plan approval, selectively prune the context — keep discovery metadata, discard bulk content.

**KEEP (low token cost, high value):**
1. The approved plan (with Story-Cycle Context header and file tracking tags)
2. File paths discovered during research (as a list, not full file contents)
3. Edge cases or gotchas noted during exploration
4. Pattern examples found in existing code (brief snippets only, not full files)

**DISCARD (high token cost, low ongoing value):**
- Full file contents from exploration reads
- Dead-end investigation paths
- Irrelevant code discovered during broad searches
- Search results that didn't lead anywhere

**THEN RELOAD fresh:**
1. `docs/reference/CODING_STANDARDS.md` (coding standards)
2. Files identified in the plan as relevant (re-read for fresh content)
3. Skill-specific context (if skills were defined)

The goal: preserve the *insights* from Phase 1 without the *bulk*. A list of 20 file paths costs ~200 tokens; the contents of those 20 files costs ~20,000.

## Phase 3: Execute by Story Type

Read `references/story-types.md` for detailed execution instructions for each story type. Follow the methodology matching your identified type from Phase 1.

## Phase 3.5: Self-Review Before Wrap-Up

Read `references/self-review.md` and complete the full checklist honestly. Do NOT skip items.

**If sub-agents are available (Claude Code with Task tool):** Dispatch quality agents (`/code-quality`, `/test-validator`) in forked context for independent review.

**If sub-agents are NOT available:** Perform the self-review checklist manually — do not skip quality checks just because agents aren't available.

<HARD-GATE>
If any checklist item fails, go back to Phase 3 and fix the issue before proceeding.
</HARD-GATE>

## Phase 4: Wrap Up

After execution is complete:

1. **Run tests:** Use the project's test command (from CLAUDE.md Commands section)
1. **Update documentation** if the story's AC requires it (but only what's relevant)
1. **Commit:** Stage relevant files and commit with conventional format:
   ```
   <type>(<scope>): <description>
   ```
1. **Do NOT merge or create PR** — that's `/sprint-end`'s job

### Completion Report

```markdown
### Story Complete

**Story:** [description]
**Type:** [story type]
**Approach:** [methodology used]
**Files modified:** [list]
**Tests:** [count] passing, [new tests added]
**Commit:** [hash and message]

**Ready for next story or sprint-end.**
```

## Recovery

When a step fails during execution:

- **Test failure (new code):** Read the error, fix the implementation, re-run. Do not weaken the test.
- **Test failure (pre-existing):** Inform user. Do not mask it. Log to `docs/technical-debt.md` if out of scope.
- **Context exhaustion:** Save current progress to `docs/plans/`, commit work-in-progress, inform user to start a new session with `/continue`.
- **Git conflict:** Show conflict to user. Do NOT auto-resolve without approval.
- **Skill not found:** If a required skill (e.g., `/code-quality`) is not available, skip it and note in the completion report.

## Rules

- NEVER skip the plan phase — always enter plan mode first
- NEVER carry exploration context into execution — clear and reload
- NEVER merge to main or create a PR — that's sprint-end
- NEVER add features not in the acceptance criteria
- NEVER weaken or delete existing tests
- Follow coding standards in `docs/reference/CODING_STANDARDS.md`
- Follow testing strategy in `docs/reference/TESTING_STRATEGY.md`
- Follow architecture constraints in `docs/architecture/ARCHITECTURE.md`
