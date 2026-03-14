---
name: story-cycle
version: 3.6.0
description: Use when the user wants to implement a single story or deliver a backlog item.
trigger: manual
depends-on: [code-quality, test-validator, security-audit]
references: [references/story-types.md, references/self-review.md, references/disaster-prevention.md, references/reasoning-tools.md, references/elicitation-techniques.md, references/error-recovery.md, references/plan-template.md, references/parallel-streams.md]
micro-components:
  phase-0: [context-prime]
  phase-1: [discover-commands, verify-clean-git-state, wave-execution, grep-first-explore]
  phase-2.5: [confidence-gate]
  phase-3.5: [record-failure]
  phase-4: [quality-gate-sequence, capture-learnings]
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
        → Phase 1c.5: Online Verification (conditional — research decision gate)
        → Phase 1d.7: Story Refinement & Forward Context (gap analysis, cross-story notes)
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

## Plan Mode for Phases 0-2 (Optional)

For STANDARD stories, consider entering Plan Mode at the start of Phase 0 and remaining in it through Phase 2 (Context Transition). This prevents accidental implementation during the planning phases and provides a natural approval checkpoint.

**When to use:** Complex stories, high-risk changes, or when the user requests careful planning.

**How:** Enter Plan Mode before Phase 0. The existing Phase 1 already operates in Plan Mode. Remain in Plan Mode through Phase 2, exiting after plan approval and context transition — just before Phase 2.5 (Confidence Gate) and Phase 3 (Execution).

## Phase 0: Intent Decomposition

Run the `context-prime` micro-component from `.claude/prompts/context-prime.md` to load project context (intent-aware ordering based on the story description).

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

### SMALL Story Checklist

SMALL stories skip Phase 1f (clarification check) and 1g (plan completeness) **only**.
All other phases are **REQUIRED** — do NOT skip them because the story feels simple:

- [ ] Phase 0: Intent decomposition
- [ ] Phase 1: Lightweight analysis + plan (includes 1c.5 online verification if APIs involved) → `*** HARD GATE: user approval ***`
- [ ] Phase 2: Context transition
- [ ] Phase 2.5: Confidence gate (score ≥85) → `*** HARD GATE ***`
- [ ] Phase 3: Implementation (TDD by story type)
- [ ] Phase 3.5: Self-review + disaster prevention → `*** HARD GATE ***`
- [ ] Phase 4: Quality gates + optional UAT generation/sense check + commit
- [ ] Phase 4.5: Completion verification with evidence → `*** HARD GATE ***`

**Why this matters:** Testing proved that SMALL stories get their quality gates skipped when the agent optimizes for speed. The code may be fine, but the process guarantees are missing. Every gate exists for a reason.

### Phase 3-lite (TRIVIAL only)

1. Make the change
2. Run tests (if test command configured)
3. Abbreviated self-review: Does the diff match intent? Any unintended side effects?
4. Commit with conventional format
5. Print completion report

## Phase 1: Story Analysis (Plan Mode)

Enter plan mode to research and design the approach.

**Pre-flight:** Run the `discover-commands` micro-component from `.claude/prompts/discover-commands.md` to extract configured commands (test, lint, format, build, typecheck) from CLAUDE.md. Run the `verify-clean-git-state` micro-component from `.claude/prompts/verify-clean-git-state.md` to confirm no uncommitted changes and correct branch.

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

### 1b. Codebase Exploration (Grep-First)

Use the `grep-first-explore` micro-component from `.claude/prompts/grep-first-explore.md` to efficiently identify relevant files before reading them. The number of exploration streams scales with story size:

| Size | Exploration Strategy |
|------|---------------------|
| **TRIVIAL** | Skip Phase 1b entirely (already fast-tracked) |
| **SMALL** | Single grep-first pass: extract terms from the story, run parallel Grep calls, read top 5-7 files |
| **STANDARD** | Grep-first pass + 1-2 codebase-explorer agents for broader context (architecture focus, test focus) |
| **STANDARD + High-risk** | Grep-first pass + 2 agents + security-focused grep (search for auth patterns, input validation, trust boundaries in affected modules) |

**Grep-first process:**
1. Extract key terms from the story description (function names, module names, API endpoints, error messages)
2. Run parallel Grep calls: imports/usage, definitions, and test references
3. Rank files by match density, select top 5-10
4. If fewer than 3 files match (greenfield or entirely new feature): fall back to codebase-explorer agents

**If sub-agents are available (STANDARD stories):** Use the `wave-execution` micro-component from `.claude/prompts/wave-execution.md` to dispatch codebase-explorer agents in parallel with focused prompts:
- **Implementation focus:** "Find source files that implement or relate to: [story description]."
- **Test focus:** "Find test files, test utilities, and fixtures related to: [story description]."

**Prior learnings check:** Search `docs/solutions/` for prior learnings on affected modules. Grep frontmatter fields (tags, module, component) for terms from the story. Read matching solution documents to avoid rediscovering known patterns or gotchas.

Collect all results. Deduplicate and synthesize into a focused file list (10-15 files max). Read ONLY the files identified. If during implementation you need additional files, read them then — don't front-load.

**If sub-agents are NOT available:** Use grep-first only — it's efficient enough for most stories without agent support.

### 1c. Research Codebase

- Deep-read the files identified in step 1b
- Understand patterns, conventions, and existing tests in the area
- Identify files to modify and files to create
- Check for `.claude-context.md` files in the target directory and parent directories — these contain module-specific patterns and conventions that supplement global CLAUDE.md

### 1c.5. Online Verification (Conditional)

Before planning, decide whether external research is needed. This gate prevents wasting context on unnecessary research for routine stories while ensuring thorough verification when it matters.

**Research Decision Gate — evaluate these three signals:**

| Signal | Research needed | Skip research |
|--------|----------------|---------------|
| **Risk level** | High-risk topics: security, payments, auth, external APIs, new dependencies | Low-risk internal changes |
| **Local context strength** | Weak: unfamiliar library, no existing patterns, no prior solutions in `docs/solutions/` | Strong: established patterns, existing tests, prior solution docs cover this area |
| **Uncertainty level** | Approach is unclear, multiple valid strategies exist | Approach is obvious from codebase conventions |

**Decision:** If ANY signal points to "research needed" → proceed with online verification. Otherwise → skip with a note: `"Online verification: skipped — [strong local patterns / low-risk internal logic / well-understood area]"`.

Announce the decision to the user so it's transparent.

**Step 1 — Official documentation** (when proceeding):

- Use `WebFetch` to check the official docs for any framework/library APIs you plan to use
- Focus on: current API signatures, deprecation notices, migration guides, changelog entries for the pinned version
- Compare against what the codebase currently uses and what any technology-specific skill references recommend

**Step 2 — Broader research** (when the story involves unfamiliar territory, new integrations, or complex patterns):

- Use `WebSearch` to find recent blog posts, GitHub issues, or Stack Overflow answers about the approach
- Look for: known pitfalls, better alternatives, community-recommended patterns
- Search for the specific error patterns or edge cases others have encountered

**Step 3 — Record findings:**

- If official docs reveal a deprecation or API change: note it in the plan as a "Doc Finding" and update relevant reference docs after implementation
- If a better approach is found: incorporate it into the plan
- If everything checks out: note "Online verification: APIs confirmed current" and move on

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

- If YES: proceed to 1d.7
- If NO: present the 3 most critical unknowns to the user as focused questions with 2-4 answer options each. Integrate answers, then proceed to 1d.7.

**Red flag:** If you're about to write "Assuming X..." in the plan, STOP — ask the user about X instead. Facilitate discovery; don't generate assumptions.

### 1d.7. Story Refinement & Forward Context

With codebase understanding from 1b-1c, pressure-test the story before planning:

1. **Map to application**: For each acceptance criterion, identify the concrete components, endpoints, services, and modules involved. If a criterion is vague, make it specific to the project's architecture.
2. **Gap analysis**: What's needed for this to work that the story doesn't mention? Check if gaps are covered by other TODO stories in the epic.
   - Small uncovered gap → propose expanding this story's AC (confirm with user)
   - Large uncovered gap → flag it, don't silently absorb scope
3. **Forward context**: Check TODO stories in the same epic that depend on or relate to this one. If research clarifies anything for them (API shape they'll consume, patterns to follow, components to reuse), add a brief `> Context from [this story]: ...` note to those stories in the epic file.

Summarize: what was refined, what gaps were found, what forward context was added.

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
stepsCompleted: [0-intent, 1a-type, 1b-discovery, 1c-research, 1c5-online-verify, 1d-skills, 1d5-discovery-gate, 1d7-refinement, 1e-plan, 1f-clarification, 1g-completeness, 1h-depth-check, 2-transition]
remaining_steps:
  - "Run tests: use project test command from CLAUDE.md Commands"
  - "Update documentation if AC requires it"
  - "Generate UAT test case (if Feature/Bug Fix with user-visible behavior and UAT structure exists)"
  - "Sense check UAT case (if generated — trace steps through code)"
  - "Capture learnings (if non-obvious patterns discovered — save to docs/solutions/)"
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

<HARD-GATE>
Do NOT skip the confidence gate for ANY story size. SMALL stories require this gate. Output the 5-dimension score table before proceeding to Phase 3.
</HARD-GATE>

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

At each phase transition, write `docs/sessions/.failure-state.md` with YAML frontmatter so the Stop hook and `/continue` can programmatically detect incomplete workflows.

**At workflow start** (after Phase 0, before main work):

```yaml
---
status: active
skill: story-cycle
phase: "0"
phase_name: "Intent Decomposition"
started_at: "[ISO-8601 timestamp from date -u +%Y-%m-%dT%H:%M:%SZ]"
story: "[from $ARGUMENTS]"
branch: "[from git branch --show-current]"
next_action: "Classify story type and begin planning"
files_modified: []
---

## Context
[Free-form notes about current state — what has been done, what remains]
```

**At each phase transition:** Update the frontmatter fields: `phase`, `phase_name`, `next_action`, and append to `files_modified`. Update the Context section with current progress.

**On successful completion (Phase 4.5 passes):** Delete `.failure-state.md` — clean state means no failure to recover from.

## Phase 3: Execute by Story Type

**State update:** If the plan is saved to `docs/plans/`, update the Story-Cycle Context: `phase: "3-executing"`, append `3-started` to `stepsCompleted`. Also update `docs/sessions/.failure-state.md` with Phase 3 entry.

In `references/story-types.md`, search for the `## [Your Story Type]` heading matching Phase 1 — load only that section, not the entire file.

Before writing the first test, apply the `test_strategy_selection` reasoning tool from `references/reasoning-tools.md`.

When errors occur during execution, consult `references/error-recovery.md` — search for `## Phase 3` for the recovery table.

## Phase 3.5: Self-Review Before Wrap-Up

Read `references/self-review.md` and complete the full checklist honestly. Do NOT skip items.

Then read `references/disaster-prevention.md` and apply the adversarial checklist — check for: wheel reinvention (did you rebuild something that already exists?), spec drift (does the implementation match the plan?), integration wiring (are all connections actually hooked up?), file structure (are files in the right place following project conventions?), regression surface (could this break existing functionality?).

**If sub-agents are available (Claude Code with Task tool):** Dispatch quality agents (`/code-quality`, `/test-validator`) in forked context for independent review.

**If sub-agents are NOT available:** Perform the self-review checklist manually — do not skip quality checks just because agents aren't available.

<HARD-GATE>
Do NOT skip self-review for ANY story size. SMALL stories require this gate. If any checklist item fails, go back to Phase 3 and fix the issue before proceeding.
</HARD-GATE>

**Error learning:** If self-review caught a wrong approach that required significant rework (not routine TDD cycles), invoke the `record-failure` micro-component from `.claude/prompts/record-failure.md` to record the pattern in `docs/context/error-patterns.md`. This builds a cross-session knowledge base of mistakes to avoid.

### Phase Completion Tracker

Before proceeding to Phase 4, output this tracker to confirm all required phases completed:

```
Phase Completion:
✓ Phase 0: Intent decomposed — [N] deliverables identified
✓ Phase 1: Plan approved by user (includes 1c.5 online verification, 1d.7 refinement)
✓ Phase 2: Context transitioned
✓ Phase 2.5: Confidence score: [score]/100
✓ Phase 3: Implementation complete, tests passing
✓ Phase 3.5: Self-review clean, disaster check passed
→ Proceeding to Phase 4: Quality gates + wrap up (includes optional UAT generation + sense check)
```

If any line cannot be checked off, do NOT proceed — go back to the incomplete phase.

## Phase 4: Wrap Up

**Cross-skill status:** Update `docs/progress.md` with the current story status at each phase gate:
- Phase 3 complete: `- **Status**: Phase 3 — implementation complete, self-review pending`
- Phase 3.5 complete: `- **Status**: Phase 4 — tests pass, wrapping up`
- Phase 4.5 complete: `- **Status**: DONE`

This allows `/sprint-end` to understand partial completion if the session ends unexpectedly.

After execution is complete, run the `quality-gate-sequence` micro-component from `.claude/prompts/quality-gate-sequence.md` (lint → typecheck → test, in order — skip any that aren't configured):

<IF condition="test command exists in CLAUDE.md Commands">
1. **Run quality gates:** Execute lint, typecheck, and test commands. Verify all pass with zero failures.
</IF>
<ELSE>
1. **Quality gates:** Run any configured commands (lint, typecheck). No test command configured — skip test verification, note in completion report.
</ELSE>

2. **Update documentation** if the story's AC requires it (but only what's relevant)
3. **Generate UAT test case** (if applicable — see Phase 4a below)
4. **Sense check UAT case** (if UAT case was generated — see Phase 4b below)
5. **Capture learnings** (if applicable): Run the `capture-learnings` micro-component from `.claude/prompts/capture-learnings.md`. Skip for TRIVIAL stories or when no non-obvious patterns were discovered. Save to `docs/solutions/<topic-slug>.md`.
6. **Commit:** Stage relevant files and commit with conventional format:
   ```
   <type>(<scope>): <description>
   ```
7. **Do NOT merge or create PR** — that's `/sprint-end`'s job

### Phase 4a: Generate UAT Test Case (Optional)

**Applies to:** Feature and Bug Fix stories that affect user-visible behavior, AND the project has a UAT structure (e.g., `docs/testing/uat/` or `tests/uat/`).
**Skip for:** Spike/Research, Infrastructure, Documentation, Testing, Refactoring, Performance, Skill/Tooling stories. Also skip if no UAT directory exists in the project.

1. **Find the UAT directory:** Check for `tests/uat/scenarios/`, `docs/testing/uat/`, or similar. If none exists, skip this phase entirely.
2. **Find next UAT ID:** Check existing UAT files, increment the highest number, format as `UAT-###` (zero-padded to 3 digits).
3. **Generate test case file** (YAML or Markdown, matching existing project convention):
   - `id`: UAT-NNN
   - `title`: Descriptive name derived from story
   - `covers`: Story IDs (e.g., `[E3-S05]`)
   - `prerequisites`: What must be set up
   - `steps`: Derived from story acceptance criteria — each step has `action` and `assertion`
   - `acceptance_criteria`: List of pass/fail conditions
4. **Add entry to UAT index/area file** if one exists, with verification checkmarks:
   ```
   **Claude Sense Check**
   - [ ] Logic verified from code perspective
   - [ ] Notes:

   **Human UAT Check**
   - [ ] Tested by user
   - [ ] Notes:
   ```

### Phase 4b: Sense Check UAT Case (Optional)

**Applies when:** A UAT test case was generated in Phase 4a.
**Skip when:** No UAT case was generated.

Since the implementation code is fresh in context, immediately verify the UAT case logic:

1. **Trace each UAT step** through the code just written:
   - Does the action map to a real UI element / API endpoint / code path?
   - Is the assertion verifiable from the implementation?
   - Are there any steps that reference behavior not actually implemented?
2. **Verify acceptance criteria coverage:**
   - Each UAT acceptance criterion should correspond to tested, reachable code
   - Flag any criterion that assumes functionality beyond what was built
3. **Assign verdict:**
   - **Pass** — all steps and criteria trace to working code
   - **Warning** — potential gap found; note the issue in the UAT file and fix if trivial
   - **Fail** — step references non-existent behavior; fix the UAT case (not the code — the code was already tested)
4. **Update the UAT file:**
   - Check the box: `- [x] Logic verified from code perspective`
   - Fill in Notes with verdict and what was checked

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
