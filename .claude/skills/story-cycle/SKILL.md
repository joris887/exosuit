---
name: story-cycle
version: 3.1.0
description: Use when the user wants to implement a single story or deliver a backlog item.
trigger: manual
depends-on: [code-quality, test-validator, security-audit]
references: [references/story-types.md, references/self-review.md, references/disaster-prevention.md, references/reasoning-tools.md, references/elicitation-techniques.md, references/error-recovery.md, references/plan-template.md, references/parallel-streams.md]
micro-components:
  phase-0: [context-prime]
  phase-1: [discover-commands, verify-clean-git-state, wave-execution]
  phase-2.5: [confidence-gate]
  phase-3.5: [record-failure]
  phase-4: [quality-gate-sequence]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Edit, Write
argument-hint: "<story-description-or-id>"
---
______________________________________________________________________

## story-cycle

Delivering story: **$ARGUMENTS**

**Skill metrics:** Emit a start event to the activity log:
```bash
echo "{\"type\":\"skill\",\"event\":\"start\",\"skill\":\"story-cycle\",\"story\":\"$ARGUMENTS\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl
```

**Progress tracking:** At the start, create a task list for phase tracking:

1. "Decompose intent and classify story" — activeForm: "Classifying story..."
2. "Plan implementation approach" — activeForm: "Planning..." — blockedBy: [1]
3. "Execute implementation" — activeForm: "Implementing..." — blockedBy: [2]
4. "Self-review and quality gates" — activeForm: "Running quality checks..." — blockedBy: [3]
5. "Verify completion and wrap up" — activeForm: "Verifying completion..." — blockedBy: [4]

At each phase boundary, mark the current task completed and the next task in_progress.

## Process Flow (authoritative — prose below is supporting detail)

```
START → Phase 0: Intent Decomposition (identify ALL deliverables, mark uncertainties)
  → Size Classification:
    → [TRIVIAL: single-file, <10 lines, no behavioral change]
      → Phase 3-lite: Make change → Run tests → Abbreviated self-review → Commit → DONE
    → [SMALL: single-file, <50 lines, clear AC]
      → Lightweight Phase 1 (skip 1f-1g) → Phase 2 → Phase 3 → Phase 4 → DONE
    → [STANDARD: everything else]
      → Phase 1: Plan Mode (research, identify type, write plan with WHAT/HOW separation)
        → Phase 1f: Clarification Check (ambiguity_scan across 7 categories)
          → [Clarifications needed?]
            → YES: Present questions → integrate answers → update plan
            → NO: Continue
        → Phase 1g: Plan Completeness (verify spec/implementation sections)
        → [User approved?]
          → NO: Revise plan → back to approval
          → YES: Phase 2: Context Transition (keep insights, discard bulk)
            → Phase 2.5: Confidence Gate (score 5 dimensions, ≥85 proceed, 70-84 clarify, <70 stop)
            → Phase 3a: Parallel Stream Analysis (optional, STANDARD + low/medium risk only)
              → Phase 3: Execute by Story Type (TDD/reproduce/characterize/etc.)
              → Phase 3.5: Self-Review (completeness, quality, testing, discipline)
                → [Review passes?]
                  → NO: Fix issues → back to Phase 3
                  → YES: Phase 4: Wrap Up (tests, docs, commit)
                    → Phase 4.5: Completion Verification (re-check ALL acceptance criteria)
                      → [All criteria met with evidence?]
                        → NO: Loop back to Phase 3 for gaps (max 2 extra passes)
                        → YES: Report → DONE
```

## Phase 0: Intent Decomposition

Before any exploration, decompose the user's request. Apply the `scope_analysis` reasoning tool from `references/reasoning-tools.md`:

1. List ALL distinct outcomes the user expects (implementation, tests, docs, PR, etc.)
2. For each: identify type, files likely affected, complexity (1-5), and dependencies
3. Flag any deliverable rated complexity ≥4 as candidate for splitting
4. If the request contains multiple independent stories, suggest splitting and confirm scope
5. Confirm the full scope with the user before proceeding to planning

This prevents missing later parts of compound requests (e.g., "refactor auth AND add rate limiting AND create a PR").

## Size & Risk Classification (Fast-Track Gate)

After Phase 0 decomposition, classify by **size** then **risk**:

**Size classification:**

| Size | Criteria | Default Workflow |
|------|----------|----------|
| **TRIVIAL** | Single-file, <10 lines changed, no behavioral change (typo, config, comment) | Phase 3-lite (below) |
| **SMALL** | Single-file, <50 lines changed, clear acceptance criteria | Lightweight Phase 1 (skip 1f, 1g) → Phase 2 → Phase 3 → Phase 4 |
| **STANDARD** | Everything else | Full workflow (unchanged) |

**Adaptive calibration:** If `docs/sessions/.activity-log.jsonl` contains 10+ skill execution records, check historical data for this story type/scope:
- If stories matching this type consistently required full workflow despite SMALL classification → escalate to STANDARD
- If STANDARD stories in this area consistently completed without issues → note as candidate for lightweight treatment
- Log calibration adjustment in plan for transparency: `Depth calibration: [escalated/standard/downgraded] based on [N] prior executions`

**Risk classification** (apply `risk_classification` reasoning tool from `references/reasoning-tools.md`):

Score domain risk, integration surface, and reversibility (1-3 each). Sum determines risk level:

| | Low risk (3-4) | Medium risk (5-6) | High risk (7-9) |
|---|---|---|---|
| **TRIVIAL** | Phase 3-lite | Phase 3-lite + full test suite | Reclassify as SMALL |
| **SMALL** | Lightweight Phase 1 | Standard workflow | Standard + mandatory security-audit |
| **STANDARD** | Standard workflow | Standard + all quality agents | Standard + all agents + architecture-check |

<HARD-GATE>
**Red flag:** If editing multiple files or changing observable behavior, STOP and reclassify as STANDARD. Fast-track is for genuinely trivial changes only.
</HARD-GATE>

### Phase 3-lite (TRIVIAL only)

1. Make the change
2. Run tests (if test command configured)
3. Abbreviated self-review: Does the diff match intent? Any unintended side effects?
4. Commit with conventional format
5. Print completion report

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

If the story type is ambiguous after checking indicators, ask the user using AskUserQuestion with `description` fields explaining workflow implications:

- **Feature** — description: "Full TDD (RED-GREEN-REFACTOR). AC in Given/When/Then. Heaviest testing."
- **Bug Fix** — description: "Reproduce first, then fix. Creates regression test. Lighter planning."
- **Refactoring** — description: "No behavior change. Characterization tests first, then restructure."
- **Spike/Research** — description: "Time-boxed exploration. Output is a decision doc, not code. No TDD."
- **Infrastructure** — description: "CI/CD, tooling, config. Smoke test verification. Lighter AC."
- **Testing** — description: "Pure test code. Design strategy, generate tests, validate coverage."
- **Documentation** — description: "Non-code deliverable. Gather, generate, review cycle."
- **Security** — description: "Threat model first. Mandatory security-audit agent. CWE checklist."
- **Performance** — description: "Baseline measurement required. Optimize, then benchmark."
- **Skill/Tooling** — description: "Developer experience. Design, build, document pattern."

### 1b. Parallel Codebase Exploration

Launch 2-3 codebase-explorer agents in parallel, each with a different focus:

1. **Architecture focus:** "Find files related to the module structure, boundaries, and dependencies for: [story description]. Check ARCHITECTURE.md and any .claude-context.md files first."
2. **Implementation focus:** "Find source files that implement or relate to: [story description]. Focus on the primary implementation files and related utilities."
3. **Test focus:** "Find test files, test utilities, and fixtures related to: [story description]. Include both unit and integration test locations."

Collect results from all agents. Deduplicate and synthesize into a single focused file list (10-15 files max). This list drives all subsequent phases.

Read ONLY the files identified by the agents. If during implementation you need additional files, read them then — don't front-load.

**If sub-agents are NOT available:** Explore manually, but be selective — read file listings and imports first to narrow down before reading full files.

### 1c. Research Codebase

- Deep-read the files identified in step 1b
- Understand patterns, conventions, and existing tests in the area
- Identify files to modify and files to create
- Check for `.claude-context.md` files in the target directory and parent directories — these contain module-specific patterns and conventions that supplement global CLAUDE.md

### 1d. Define Required Skills

Determine which skills benefit this story. If the story metadata already defines skills, use those. Otherwise select from:

| Skill               | Load When                                             |
| ------------------- | ----------------------------------------------------- |
| `/code-quality`     | Feature, refactoring, infrastructure stories          |
| `/test-validator`   | Feature, bug fix, testing stories                     |
| `/security-audit`   | Security stories, code touching auth/credentials/data |

**Intent-based security activation:** If the story touches user input, API endpoints, database queries, file uploads, sessions, or network calls, treat the security rule as active for ALL files in this story — not just files matching security path patterns. Note this in the plan: `Security scope: story-wide (intent-based)`.

### 1d.5. Discovery Gate (Facilitator Check)

Before writing the plan, check: do you have enough information to write a plan without assumptions?

- If YES: proceed to 1e
- If NO: present the 3 most critical unknowns to the user as focused questions with 2-4 answer options each. Integrate answers, then proceed to 1e.

**Red flag:** If you're about to write "Assuming X..." in the plan, STOP — ask the user about X instead. Facilitate discovery; don't generate assumptions.

### 1e. Write the Plan

Keep the plan concise — **under 50 lines**. Save complex plans to `docs/plans/` for persistence across compaction. Reference files by path rather than inlining content.

Follow the plan template structure in `references/plan-template.md`. The plan MUST have two distinct sections:

1. **Specification (WHAT/WHY)** — User-visible behavior changes, acceptance criteria in Given/When/Then format. NO file paths, NO function names, NO framework references.
2. **Implementation Approach (HOW)** — Files to modify/create, patterns to follow, technical strategy with rationale.

For any requirement where the user's intent is ambiguous or multiple valid interpretations exist, insert `[NEEDS CLARIFICATION: specific question]` in the plan. Maximum 3 markers before triggering a hard gate for user input.

Apply the `test_strategy_selection` reasoning tool for the testing section.

<IF condition="docs/reference/GROUND_RULES.md exists">
Check the plan against `docs/reference/GROUND_RULES.md`. Any MUST violation → HALT. Any SHOULD violation → document justification in an Architectural Violations table (see `references/plan-template.md`).
</IF>

### 1f. Clarification Check

Apply the `ambiguity_scan` reasoning tool from `references/reasoning-tools.md`. Scan the plan for assumptions across 7 categories (scope, data model, UX, non-functional, integration, edge cases, constraints).

<IF condition="ambiguity_scan produces questions OR plan contains [NEEDS CLARIFICATION] markers">
Present questions to user. Integrate answers into the plan. Remove resolved `[NEEDS CLARIFICATION]` markers.
</IF>

### 1g. Plan Completeness

Apply the `plan_completeness` reasoning tool from `references/reasoning-tools.md` to verify:
- All deliverables from Phase 0 have implementation steps
- All acceptance criteria have verification approaches
- Specification section contains zero implementation details
- Implementation section traces to every acceptance criterion

**CRITICAL — Story-Cycle Context Preservation:**

After plan approval, context resets and only the plan survives. The plan MUST start with a "Story-Cycle Context" section so Claude Code knows what workflow it's in and what steps remain. **Update the `phase` and `stepsCompleted` fields at each phase transition** — this enables true mid-workflow resume if the session is interrupted or context compacts.

Use this exact format at the TOP of the plan:

```yaml
## Story-Cycle Context

workflow: story-cycle
phase: "plan-approved — proceed to execution"
stepsCompleted: [0-intent, 1a-type, 1b-discovery, 1c-research, 1d-skills, 1e-plan, 1f-clarification, 1g-completeness, 2-transition]
remaining_steps:
  - "Run tests: use project test command from CLAUDE.md Commands"
  - "Update documentation if AC requires it"
  - "Commit: conventional format <type>(<scope>): <description>"
  - "Do NOT merge or create PR — that is sprint-end"
  - "Print completion report: story, type, approach, files, tests, commit hash"
error_recovery: "references/error-recovery.md"

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

### 1h. Depth Check (Optional)

Before presenting for approval, offer the user a depth option if the plan contains areas with complexity ≥4 or unresolved uncertainties:

- **[D] Deep dive** — Explore design alternatives for uncertain areas using the `depth_exploration` reasoning tool and elicitation techniques from `references/elicitation-techniques.md`
- **[C] Continue** — Plan is ready for approval as-is

If [D]: apply the most relevant elicitation technique, integrate findings into the plan, then present for approval.
If [C] or no uncertainties exist: proceed directly to approval.

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

**RELOAD for Phase 3** (prescriptive — load these, skip the rest):
1. `docs/reference/CODING_STANDARDS.md` — coding conventions for implementation
2. `docs/reference/TESTING_STRATEGY.md` — TDD workflow and test quality criteria
3. Files identified in the plan's Implementation Approach as targets (re-read for fresh content)
4. Skill-specific context (if skills were defined in Phase 1d)

**SKIP until Phase 4:** `docs/progress.md`, `docs/architecture/ARCHITECTURE.md` (decisions already captured in plan), backlog files, `docs/reference/GROUND_RULES.md` (already checked in Phase 1e)

The goal: preserve the *insights* from Phase 1 without the *bulk*. A list of 20 file paths costs ~200 tokens; the contents of those 20 files costs ~20,000.

**DO / DON'T:**
- DO reload coding standards and relevant files fresh after context transition.
- DON'T carry over full file contents from Phase 1 — keep only paths, edge cases, and patterns.
- DO re-read files from the plan's file list before editing them.
- DON'T assume you remember file contents from Phase 1 — context may have changed.

## Phase 2.5: Confidence Gate

Before writing any implementation code, run the `confidence-gate` micro-component from `.claude/prompts/confidence-gate.md`. Score 5 dimensions (ambiguity, architecture, patterns, test strategy, dependencies) on a 0–20 scale each.

| Total Score | Action |
|-------------|--------|
| **85–100** | Proceed to Phase 3 |
| **70–84** | Flag low-scoring dimensions, ask user for clarification before proceeding |
| **< 70** | Return to Phase 1 for additional research on the weakest dimensions |

This gate prevents wrong-direction implementations that waste the entire Phase 3 execution budget. A few tokens spent on confidence assessment saves thousands on rework.

## Phase 3a: Parallel Stream Analysis (Optional)

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

## Failure State Persistence

At each phase transition, update `docs/sessions/.failure-state.md` with current progress. This enables `/continue` to resume precisely where work stopped if a session ends unexpectedly.

```markdown
# Active Skill State
- Skill: story-cycle
- Story: [description]
- Phase: [current phase number and name]
- Sub-step: [what is being done right now]
- Files modified: [list of files changed so far]
- Tests status: [passing count / total, or "not yet run"]
- Last action: [what was just done or attempted]
- Recovery hint: [what to do next to resume]
```

**On successful completion (Phase 4.5 passes):** Delete `.failure-state.md` — clean state means no failure to recover from.

## Phase 3: Execute by Story Type

**State update:** If the plan is saved to `docs/plans/`, update the Story-Cycle Context: `phase: "3-executing"`, append `3-started` to `stepsCompleted`. Also update `docs/sessions/.failure-state.md` with Phase 3 entry.

In `references/story-types.md`, search for the `## [Your Story Type]` heading matching Phase 1 — load only that section, not the entire file.

Before writing the first test, apply the `test_strategy_selection` reasoning tool from `references/reasoning-tools.md`.

When errors occur during execution, consult `references/error-recovery.md` — search for `## Phase 3` for the recovery table.

## Phase 3.5: Self-Review Before Wrap-Up

Read `references/self-review.md` and complete the full checklist honestly. Do NOT skip items.

**If sub-agents are available (Claude Code with Task tool):** Dispatch quality agents (`/code-quality`, `/test-validator`) in forked context for independent review.

**If sub-agents are NOT available:** Perform the self-review checklist manually — do not skip quality checks just because agents aren't available.

<HARD-GATE>
If any checklist item fails, go back to Phase 3 and fix the issue before proceeding.
</HARD-GATE>

**Error learning:** If self-review caught a wrong approach that required significant rework (not routine TDD cycles), invoke the `record-failure` micro-component from `.claude/prompts/record-failure.md` to record the pattern in `docs/context/error-patterns.md`. This builds a cross-session knowledge base of mistakes to avoid.

## Phase 4: Wrap Up

**Cross-skill status:** Update `docs/progress.md` with the current story status at each phase gate:
- Phase 3 complete: `- **Status**: Phase 3 — implementation complete, self-review pending`
- Phase 3.5 complete: `- **Status**: Phase 4 — tests pass, wrapping up`
- Phase 4.5 complete: `- **Status**: DONE`

This allows `/sprint-end` to understand partial completion if the session ends unexpectedly.

After execution is complete:

<IF condition="test command exists in CLAUDE.md Commands">
1. **Run tests:** Execute the project's test command. Verify all tests pass with zero failures.
</IF>
<ELSE>
1. **Tests:** No test command configured — skip test verification, note in completion report.
</ELSE>

2. **Update documentation** if the story's AC requires it (but only what's relevant)
3. **Commit:** Stage relevant files and commit with conventional format:
   ```
   <type>(<scope>): <description>
   ```
4. **Do NOT merge or create PR** — that's `/sprint-end`'s job

## Phase 4.5: Completion Verification

Before reporting done, re-check ALL acceptance criteria from the original request and Phase 0 decomposition:

1. Re-read the original acceptance criteria (from the plan or user request)
2. For each criterion, provide evidence: test output, code reference (file:line), or command output

<LOOP max="2" until="all acceptance criteria have evidence">
3. If any criterion lacks evidence: identify the gap, loop back to Phase 3 for that specific item
4. Re-verify all criteria after each fix pass
</LOOP>

<HALT reason="max verification loops exhausted">
If 2 extra passes are exhausted: report what IS complete with evidence, list remaining gaps, suggest continuing in next session.
</HALT>

5. Only report completion when ALL criteria have evidence

<HARD-GATE>
Do NOT print the completion report until every acceptance criterion has been verified with evidence. "I believe it works" is not evidence — show test output or code references.
</HARD-GATE>

**Skill metrics:** Emit a completion event:
```bash
echo "{\"type\":\"skill\",\"event\":\"end\",\"skill\":\"story-cycle\",\"outcome\":\"success\",\"story\":\"$ARGUMENTS\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl
```

### Completion Report

```markdown
### Story Complete

**Story:** [description]
**Type:** [story type]
**Approach:** [methodology used]
**Files modified:** [list]
**Tests:** [count] passing, [new tests added]
**Commit:** [hash and message]
**Verification:** [All N acceptance criteria verified — see evidence above]

**Next Steps:**
→ `/story-cycle "[next story from backlog]"` — deliver the next story
→ `/sprint-end` — if this was the last story in the sprint
→ `/handoff` — if ending the session
```

## Recovery

For phase-specific error recovery, consult `references/error-recovery.md` — search for the relevant `## Phase N` section.

General recovery:

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
- Follow project ground rules in `docs/reference/GROUND_RULES.md` (if exists)
