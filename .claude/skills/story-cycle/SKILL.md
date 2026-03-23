---
name: story-cycle
version: 4.3.0
description: Use when the user wants to implement a single story or deliver a backlog item.
trigger: manual
depends-on: [code-quality, test-validator, security-audit]
requires: [git]
optional-requires: [test-command, lint-command, typecheck-command]
references: [references/story-types.md, references/self-review.md, references/disaster-prevention.md, references/reasoning-tools.md, references/elicitation-techniques.md, references/error-recovery.md, references/plan-template.md, references/parallel-streams.md]
micro-components:
  phase-0: [context-prime]
  phase-1: [discover-commands, verify-clean-git-state, wave-execution, grep-first-explore]
  phase-2: [confidence-gate]
  phase-4: [record-failure, quality-gate-sequence, capture-learnings, capture-outcome]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Edit, Write, WebSearch, WebFetch, Agent
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

1. "Phase 0+1: Decompose intent, research, plan" — activeForm: "Planning..."
2. "Phase 2: Context transition + confidence gate" — activeForm: "Preparing..." — blockedBy: [1]
3. "Phase 3: Implement by story type" — activeForm: "Implementing..." — blockedBy: [2]
4. "Phase 4: Verify, quality gates, commit" — activeForm: "Verifying..." — blockedBy: [3]

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
        → Phase 1c.5: Online Verification → `*** HARD GATE: must print Research Decision block ***`
          → 1c.5+: Dependency Freshness Check (always, if story touches external deps)
        → Phase 1d.7: Story Refinement & Forward Context (gap analysis, cross-story notes)
        → Phase 1f: Clarification Check (ambiguity_scan across 7 categories)
        → Phase 1g: Plan Completeness (verify spec/implementation sections)
        → [User approved?] → NO: Revise → YES: Continue
      → Phase 2: Context Transition + Confidence Gate
        → (prune context, score 5 dimensions, ≥85 proceed, 70-84 clarify, <70 return to Phase 1)
      → Phase 3: Execute by Story Type
        → `*** HARD GATE: TDD ordering — tests BEFORE implementation (Feature/Bug Fix/Refactoring) ***`
        → Web-Assisted Error Recovery (on build/test failure involving external libraries)
        → Bug Fix Web Research (always for bug fix stories — search error patterns first)
      → Phase 4: Verify + Wrap Up
        → Self-review + disaster prevention + ground rules re-check
        → Quality agents dispatched per risk level
        → Security web verification (security-scoped stories — CWE + CVE check)
        → Quality gates `*** HARD GATE: all configured gates must pass ***`
        → UAT generation + sense check (optional — Feature/Bug Fix only)
        → Completion verification (evidence for every AC)
        → Docs + commit
        → [All criteria met?] → NO: Fix + re-verify (max 2 passes) → YES: Report → DONE
```

## Plan Mode for Phases 0-2 (Optional)

For STANDARD stories, consider entering Plan Mode at the start of Phase 0 and remaining in it through Phase 2 (Context Transition). This prevents accidental implementation during the planning phases and provides a natural approval checkpoint.

**When to use:** Complex stories, high-risk changes, or when the user requests careful planning.

**How:** Enter Plan Mode before Phase 0. The existing Phase 1 already operates in Plan Mode. Exit Plan Mode after plan approval — just before Phase 2 (Context Transition + Confidence Gate) and Phase 3 (Execution).

**CRITICAL — After ExitPlanMode:** Plan Mode exit wipes the story-cycle skill from context. After ExitPlanMode, you MUST immediately:

1. Read the plan file's `remaining_steps` list — it is your execution checklist
2. The first step (BOOTSTRAP) tells you to re-read this skill file from Phase 2 onwards
3. Continue executing all remaining phases (2 → 3 → 4) — do NOT stop

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
- [ ] Phase 1: Lightweight analysis + plan (includes 1c.5 Research Decision — MANDATORY output) → `*** HARD GATE: user approval ***`
- [ ] Phase 2: Context transition + confidence gate (score ≥85) → `*** HARD GATE ***`
- [ ] Phase 3: Implementation (TDD by story type)
- [ ] Phase 4: Self-review + quality gates + completion verification with evidence → `*** HARD GATE ***`

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

| Type | Indicators | Approach |
|------|-----------|----------|
| **Feature** | New user-facing capability, "As a user..." | TDD: RED-GREEN-REFACTOR |
| **Bug Fix** | Defect, "fix", error report, reproduction steps | Reproduce → Test → Fix → Verify |
| **Refactoring** | "Refactor", "restructure", no behavior change | Characterization tests → Refactor → Verify |
| **Spike/Research** | "Investigate", "evaluate", "prototype", time-boxed | Explore → Document → Decide |
| **Infrastructure** | CI/CD, tooling, build, config, environment | Plan → Implement → Smoke Test |
| **Testing** | "Add tests", "coverage", "E2E tests" | Design strategy → Generate → Validate |
| **Documentation** | "Document", "write docs", "update README" | Gather → Generate → Review |
| **Security** | "Harden", "audit", "vulnerability", "encrypt" | Threat model → Implement → Audit |
| **Performance** | "Optimize", "benchmark", "speed up", "latency" | Baseline → Optimize → Benchmark |
| **Skill/Tooling** | "Create skill", "add tool", "developer experience" | Design → Build → Document |

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
- Check for `CLAUDE.md` files in the target directory and parent directories — these contain module-specific patterns and conventions that supplement global CLAUDE.md

### 1c.5. Online Verification

<HARD-GATE>
**This phase produces MANDATORY output.** You MUST print a `## Research Decision` block (format below) before proceeding to Phase 1d. The plan CANNOT be written without this block. Skipping this phase silently is a workflow violation.
</HARD-GATE>

**Step 1 — Classify research requirement:**

| Story type | Research requirement | Depth |
|---|---|---|
| **Spike/Research** | **MANDATORY** | **DEEP** |
| **Security** | **MANDATORY** | **STANDARD** |
| **Bug Fix** | **MANDATORY** (error pattern search) | **QUICK** |
| All other types | Conditional (evaluate 3 signals below) | Auto-select |

**Step 2 — For conditional stories, evaluate these three signals:**

| Signal | Research needed | Skip research |
|--------|----------------|---------------|
| **Risk level** | High-risk topics: security, payments, auth, external APIs, new dependencies | Low-risk internal changes |
| **Local context strength** | Weak: unfamiliar library, no existing patterns, no prior solutions in `docs/solutions/` | Strong: established patterns, existing tests, prior solution docs cover this area |
| **Uncertainty level** | Approach is unclear, multiple valid strategies exist | Approach is obvious from codebase conventions |

**Decision:** If ANY signal points to "research needed" → proceed. Otherwise → skip with justification.

**Step 3 — Execute research (when proceeding):**

Compose the `deep-research` methodology (`.claude/prompts/deep-research.md`) at the depth from Step 1:

| Story context | Research depth |
|---|---|
| Spike/Research | **DEEP** |
| Security, new external dependencies | **STANDARD** |
| Bug fix, standard story with research signals | **QUICK** |

The research engine handles: query decomposition, parallel subagent dispatch, source evaluation, reflection-based compression. See `.claude/prompts/deep-research.md`.

**For Spike/Research stories specifically:** Generate sub-questions from the spike's questions. Research current state of reference technologies, recent publications, competitor approaches, and relevant patterns. All claims MUST cite sources with URLs. Training data alone is NEVER sufficient for spikes.

**Step 4 — Print the Research Decision block (MANDATORY):**

```markdown
## Research Decision

**Story type:** [type from 1a]
**Research requirement:** [MANDATORY / Conditional]
**Decision:** [PERFORMED at [depth] / SKIPPED]
**Justification:** [why — for skips: which signals were evaluated and why all pointed to skip]

### Findings (if research was performed)
- [Key finding 1 with source URL]
- [Key finding 2 with source URL]
- [Finding N...]

**Research confidence:** [score]/100
**Impact on plan:** [how findings affect the approach — or "No findings that change approach"]
```

This block is included in the plan and feeds into Phase 2b confidence scoring.

**Record findings:**

- If official docs reveal a deprecation or API change: note it in the plan as a "Doc Finding" and update relevant reference docs after implementation
- If a better approach is found: incorporate it into the plan
- If everything checks out: note "Online verification: APIs confirmed current" and move on

### 1c.5+. Dependency Freshness Check (Always-On for External Deps)

**Trigger:** The story creates, modifies, or directly calls any external dependency (not internal modules). This runs even when the main 1c.5 research gate was skipped.

**Quick check (~30 seconds):**

1. Identify the external libraries the story will use (from plan or codebase grep)
2. For each, `WebSearch` for: `"<library> <pinned-version> deprecation OR breaking change OR CVE"` (batch into 1-2 searches)
3. If a result looks relevant, `WebFetch` the specific page to confirm

**Outcomes:**

| Finding | Action |
|---------|--------|
| No issues | Note `"Dep freshness: all clear"` in plan, move on |
| Deprecation notice | Note in plan, use recommended replacement API |
| Known CVE | Flag to user immediately — may change story scope |
| Breaking change in newer version | Note in plan for awareness; no action if pinned version is stable |

**Skip when:** Story only touches internal code with no external library calls.

### 1d. Define Required Skills

Determine which skills benefit this story. If the story metadata already defines skills, use those. Otherwise select from:

| Skill | Load When |
|-------|-----------|
| `/code-quality` | Feature, refactoring, infrastructure stories |
| `/test-validator` | Feature, bug fix, refactoring, testing stories |
| `/security-audit` | Security stories, code touching auth/credentials/data |

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
- **Research Decision block is present** (from Phase 1c.5) — if missing, HALT and go back to 1c.5

**CRITICAL — Story-Cycle Context Preservation:**

After plan approval, context resets and only the plan survives. The plan MUST start with a "Story-Cycle Context" section so Claude Code knows what workflow it's in and what steps remain. **Update the `phase` and `stepsCompleted` fields at each phase transition** — this enables true mid-workflow resume if the session is interrupted or context compacts.

Use this exact format at the TOP of the plan:

```yaml
## Story-Cycle Context

workflow: story-cycle
storyType: "[from Phase 1a]"
phase: "plan-approved — proceed to Phase 2 Context Transition + Confidence Gate"
stepsCompleted: [0-intent, 1a-type, 1b-discovery, 1c-research, 1c5-online-verify, 1d-skills, 1d5-discovery-gate, 1d7-refinement, 1e-plan, 1f-clarification, 1g-completeness, 1h-depth-check]
remaining_steps:
  - "BOOTSTRAP (do this FIRST): Read .claude/skills/story-cycle/SKILL.md starting from '## Phase 2: Context Transition + Confidence Gate' to reload the full story-cycle workflow. You are mid-workflow — planning is done, implementation phases remain. Do NOT stop after reading the plan."
  - "Phase 2 — CONTEXT + CONFIDENCE GATE (HARD-GATE): Prune context (keep plan + paths + gotchas, discard bulk). Read .claude/prompts/confidence-gate.md. Score 5 dimensions 0-20 each. ≥85 proceed, 70-84 clarify, <70 return to planning. Output the score table."
  - "Phase 3 — IMPLEMENT (TDD HARD-GATE for Feature/Bug Fix/Refactoring): Read .claude/skills/story-cycle/references/story-types.md for [storyType] execution steps. Load relevant sections of docs/reference/CODING_STANDARDS.md and docs/reference/TESTING_STRATEGY.md. Re-read all target files from plan before editing. CRITICAL: For Feature/Bug Fix/Refactoring stories, write and run a failing test BEFORE writing implementation code. Show test failure output. Only then write implementation. Follow story-type methodology (TDD: RED → GREEN → REFACTOR)."
  - "Phase 4a — SELF-REVIEW (HARD-GATE): Read .claude/skills/story-cycle/references/self-review.md — complete ALL checklist items including ground rules re-check. Read .claude/skills/story-cycle/references/disaster-prevention.md — check for wheel reinvention, spec drift, integration wiring, file structure, regression surface, architecture doc staleness. Dispatch quality agents per risk level (Low: code-quality+test-validator, Medium: +security-audit, High: +architecture-check). If ANY item fails → fix in Phase 3 before proceeding."
  - "Phase 4b — QUALITY GATES (HARD-GATE): Run the project's quality command (from CLAUDE.md Commands section: lint → typecheck → test). Stop on first failure, fix, re-run. Show passing output in the current turn — do NOT claim tests pass without evidence. Do NOT proceed until all gates pass."
  - "Phase 4c — UAT (optional, Feature/Bug Fix only): If project has UAT directory, generate UAT test case + sense check per Phase 4c/4c.1 in SKILL.md. Skip for Spike/Research, Infrastructure, Documentation, Testing, Refactoring, Performance, Skill/Tooling stories. Also skip if no UAT directory exists."
  - "Phase 4d — COMPLETION VERIFICATION (HARD-GATE): Re-read original AC from plan. For EACH criterion, provide concrete evidence (test output, file:line, command output). Max 2 extra loop passes if gaps found. Do NOT print completion report until every AC has evidence."
  - "Phase 4e — DOCS + COMMIT: (1) Update epic file (mark story DONE in heading, check all AC boxes). (2) Update BACKLOG_INDEX.md (increment Done, decrement TODO for epic row, update Total row). (3) Update docs/progress.md (current story status, test counts). (4) Update CLAUDE.md if it contains backlog counts or epic progress that changed. (5) Emit skill metrics event to docs/sessions/.activity-log.jsonl. (6) Invoke /commit skill. Do NOT merge or create PR — that is sprint-end."
  - "COMPLETION REPORT: Print story, type, approach, files modified, test counts, commit hash, verification evidence. Include Next Steps (next story / sprint-end / handoff)."
error_recovery: ".claude/skills/story-cycle/references/error-recovery.md"
skill_file: ".claude/skills/story-cycle/SKILL.md"
```

### File Context (accumulates across compactions)

```
<files-read>
[List all files read during planning — one path per line]
</files-read>
<files-modified>
[Update as files are modified during execution — one path per line]
</files-modified>
```

When context compacts, MERGE new file paths into these lists — never discard previous entries.

<HARD-GATE>
**POST-PLAN-MODE EXECUTION — THIS IS NOT OPTIONAL**

When you exit Plan Mode (ExitPlanMode) during a story-cycle, you are NOT done.
Planning is only Phase 1 of 4. After Plan Mode exits, you MUST:

1. Read `.claude/skills/story-cycle/SKILL.md` starting from `## Phase 2: Context Transition + Confidence Gate`
2. Execute the `remaining_steps` from the plan's Story-Cycle Context block IN ORDER
3. Do NOT report completion until Phase 4d passes with evidence for every acceptance criterion

The plan approval is a checkpoint, not the finish line. If you stop after Plan Mode,
the story is incomplete — no code was written, no tests were run, nothing was committed.
</HARD-GATE>

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

## Phase 2: Context Transition + Confidence Gate

After plan approval, prune context and score confidence in a single pass.

### 2a. Context Pruning

**KEEP:** The approved plan (with Story-Cycle Context header), file paths from research, edge cases/gotchas, pattern snippets.
**DISCARD:** Full file contents from exploration, dead-end investigations, irrelevant search results.
**RELOAD for Phase 3 (section-specific to save context):**
- `docs/reference/CODING_STANDARDS.md` — load ONLY the section for the story's language/stack (e.g., `## Python` or `## TypeScript`), plus the `## Shared Conventions` section. Skip other language sections.
- `docs/reference/TESTING_STRATEGY.md` — load ONLY the `## Test Infrastructure` section (project-specific commands) and the section matching the story type (e.g., `## Feature Story` or `## Bug Fix`). Skip unrelated story-type sections.
- Target source/test files from the plan.
**SKIP until Phase 4:** `docs/progress.md`, `docs/architecture/ARCHITECTURE.md`, backlog files, `docs/reference/GROUND_RULES.md` (already checked in Phase 1e).

Re-read target files before editing — context may have changed since Phase 1.

### 2b. Confidence Gate

Run the `confidence-gate` micro-component from `.claude/prompts/confidence-gate.md`. Score 5 dimensions (ambiguity, architecture, patterns, test strategy, dependencies) on a 0–20 scale each.

| Total Score | Action |
|-------------|--------|
| **85–100** | Proceed to Phase 3 |
| **70–84** | Flag low-scoring dimensions, ask user for clarification before proceeding |
| **< 70** | Return to Phase 1 for additional research on the weakest dimensions |

<HARD-GATE>
Do NOT skip the confidence gate for ANY story size. Output the 5-dimension score table before proceeding to Phase 3.
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

## Session Recovery

The Stop hook auto-saves git state to `docs/sessions/.auto-save.md` (branch, recent commits, uncommitted files). The `/continue` skill uses this plus git state to resume interrupted workflows. No manual state file management needed.

## Phase 3: Execute by Story Type

### 3.pre. Git Checkpoint

Before writing any implementation code, create a checkpoint so the entire implementation can be cleanly rolled back if verification fails:

```bash
git tag "story-checkpoint-$(date +%s)" HEAD
```

Record the tag name in `.failure-state.md` under a `checkpoint_tag` field. This tag is used by Phase 4 if verification fails — see "Checkpoint Rollback" in Phase 4d.

On successful story completion (Phase 4e commit), delete the checkpoint tag:
```bash
git tag -d "story-checkpoint-*"  # Clean up
```

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

### Web-Assisted Error Recovery (Phase 3)

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

## Phase 4: Verify + Wrap Up

This phase combines self-review, quality gates, UAT, and completion verification into a single pass. All checks are mandatory — none are skipped because the story feels simple.

### 4a. Self-Review + Disaster Prevention

Read `references/self-review.md` and complete the checklist (completeness, quality, testing, discipline).

Then read `references/disaster-prevention.md` — check for: wheel reinvention, spec drift, integration wiring, file structure, regression surface.

**Security web verification (security-scoped stories only):** If the story was tagged with intent-based security activation (Phase 1d) or is a Security story type, perform a targeted web check before quality gates. See `references/self-review.md` → "Security Web Verification" section for the protocol.

<HARD-GATE>
Do NOT skip self-review for ANY story size. If any checklist item fails, go back to Phase 3 and fix before continuing.
</HARD-GATE>

**Ground rules re-check:** If `docs/reference/GROUND_RULES.md` exists, re-read it and verify the IMPLEMENTATION (not just the plan) complies. Plans can comply while implementation drifts. Check `git diff --name-only` against ground rules — any MUST violation requires fixing before proceeding.

**If sub-agents are available:** Dispatch quality agents in forked context based on the risk matrix from Size & Risk Classification:

| Risk Level | Agents to Dispatch |
|---|---|
| **Low (3-4)** | `/code-quality`, `/test-validator` |
| **Medium (5-6)** | `/code-quality`, `/test-validator`, `/security-audit` (if security-scoped) |
| **High (7-9)** | `/code-quality`, `/test-validator`, `/security-audit`, `/architecture-check` |

For medium-risk STANDARD stories, the risk matrix promises "all quality agents" — dispatch accordingly. For high-risk, add `/architecture-check` as the risk matrix specifies "all agents + architecture-check."

**If sub-agents are NOT available:** Complete self-review checklist manually. Do NOT skip quality checks.

**Error learning:** If self-review caught a wrong approach requiring significant rework, invoke the `record-failure` micro-component from `.claude/prompts/record-failure.md`.

### 4b. Quality Gates

Run the `quality-gate-sequence` micro-component from `.claude/prompts/quality-gate-sequence.md`: execute the project's quality commands (from CLAUDE.md Commands section) in order: lint → typecheck → test. Stop on first failure, fix, and re-run.

<IF condition="test command exists in CLAUDE.md Commands">
Execute the configured quality commands. Verify all pass with zero failures.
</IF>
<ELSE>
Run any configured commands (lint, typecheck). No test command configured — skip test verification, note in completion report.
</ELSE>

<HARD-GATE>
Do NOT proceed to Phase 4c/4d until ALL configured quality gates pass with zero failures. Show the passing output in the current turn. "It passed earlier" is not evidence — re-run if any code changed since the last run.
</HARD-GATE>

### 4c. Generate UAT Test Case (Optional)

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

### 4c.1. Sense Check UAT Case (Optional)

**Applies when:** A UAT test case was generated in Phase 4c.
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

### 4d. Completion Verification

Re-read the original acceptance criteria from the plan. For each criterion, provide concrete evidence: test output, code reference (file:line), or command output.

<LOOP max="2" until="all acceptance criteria have evidence">
If any criterion lacks evidence: identify the gap, loop back to Phase 3 for that specific item, re-verify.
</LOOP>

<HALT reason="max verification loops exhausted">
Report what IS complete with evidence, list remaining gaps.

**Checkpoint Rollback Option:** If verification has failed after 2 loop passes and the implementation appears fundamentally flawed (not just minor gaps), offer the user a rollback:

```
Verification failed after 2 passes. Options:
[R] Rollback — restore to pre-implementation checkpoint (git tag from Phase 3.pre) and re-plan
[C] Continue — keep current code and address remaining gaps in next session
[F] Force complete — mark as done with known gaps documented
```

If [R]: `git reset --hard <checkpoint-tag> && git tag -d <checkpoint-tag>`. Clear `.failure-state.md`. Suggest re-entering Phase 1 with lessons learned.
If [C]: Save state to `.failure-state.md` for `/continue` pickup.
If [F]: Document gaps in completion report, proceed to Phase 4e.
</HALT>

<HARD-GATE>
Do NOT print the completion report until every acceptance criterion has been verified with evidence. Show test output or code references — not assertions.
</HARD-GATE>

### 4e. Docs + Commit

1. **Capture story outcome:** Run the `capture-outcome` micro-component from `.claude/prompts/capture-outcome.md` to record measurable deltas (lines added/removed, test count, coverage, new deps) to `docs/sessions/.story-outcomes.tsv`. Skip for Spike/Research and Documentation stories.
2. **Update epic file** (`docs/reference/backlog/E##-*.md`): Mark the story status as DONE in the heading (`— TODO` → `— DONE`). Check all acceptance criteria boxes (`- [ ]` → `- [x]`).
3. **Update `docs/reference/BACKLOG_INDEX.md`**: Increment the Done count and decrement the TODO count for this epic's row in the status table.
4. **Update `docs/progress.md`** with story status (DONE)
5. **Update documentation** only if the story's AC requires it
6. **Architecture documentation check:** If this story added, removed, or significantly restructured components, modules, services, or data flows, update `docs/architecture/ARCHITECTURE.md` to reflect the change. Check: did the story add a new service/module? Change a data flow? Add a new external dependency or integration? If yes to any, update the architecture doc. If no architectural change, skip.
7. **Capture learnings** (optional): If non-obvious patterns discovered, run the `capture-learnings` micro-component from `.claude/prompts/capture-learnings.md` to save to `docs/solutions/<topic-slug>.md`
8. **Clean up checkpoint:** Delete the git checkpoint tag from Phase 3.pre: `git tag -l 'story-checkpoint-*' | xargs -r git tag -d`
9. **Commit:** Invoke the `/commit` skill. Do NOT merge or create PR — that's `/sprint-end`'s job.

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
- **Implementation fundamentally wrong:** If Phase 4 reveals the approach is flawed, use the checkpoint rollback option (Phase 4d) to cleanly revert to pre-implementation state.

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
