# Phase 1: Story Analysis (Plan Mode)

Reference loaded by `/story-cycle` Phase 1. Enter plan mode to research and design the approach.

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

**Architecture rules check:** If `docs/architecture/ARCHITECTURE.md` exists and is non-template, read ONLY the Module Map (Dependency Rules subsection) and Known Landmines sections. For each module this story touches, note any applicable rules or landmines in the exploration summary. This avoids wrong-direction implementations and repeat mistakes.

**Debt register cross-reference (skip for TRIVIAL stories):** If `docs/technical-debt.md` has active items, grep its Location fields for files identified in exploration. If any explored files appear in active debt items:
- **Low severity + Hours effort** in files being modified → suggest addressing as a "boy scout" improvement alongside the story (leave code better than you found it). Note: do not expand story scope — only fix if genuinely trivial.
- **Higher severity or effort** → note in exploration summary for awareness ("TD-NNN affects this file"), but do not expand scope. The debt register tracks these for future sprints.

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

<IF condition="docs/adr/ contains ADR files">
Scan ADR YAML frontmatter for `status: accepted` records with tags relevant to this story's domain. Check that no proposed approach matches a `rejected-options` value in any accepted ADR. If a match is found, note the ADR reference and use the chosen alternative instead. Check `Reconsider when` conditions only if circumstances have materially changed.
</IF>

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
sprint_number: [N]
sprint_goal: "[from Phase 0a.5 — one sentence]"
sprint_alignment: "[aligned/peripheral — from Size & Risk Classification]"
phase: "plan-approved — proceed to Phase 2 Context Transition + Confidence Gate"
stepsCompleted: [0-intent, 0a5-sprint-context, 1a-type, 1b-discovery, 1c-research, 1c5-online-verify, 1d-skills, 1d5-discovery-gate, 1d7-refinement, 1e-plan, 1f-clarification, 1g-completeness, 1h-depth-check]
remaining_steps:
  - "BOOTSTRAP (do this FIRST): Read .claude/skills/story-cycle/SKILL.md starting from '## Phase 2' to reload the full story-cycle workflow. You are mid-workflow — planning is done, implementation phases remain. Do NOT stop after reading the plan."
  - "Phase 2 — CONTEXT + CONFIDENCE GATE (HARD-GATE): Prune context (keep plan + paths + gotchas, discard bulk). Read .claude/prompts/confidence-gate.md. Score 5 dimensions 0-20 each. ≥85 proceed, 70-84 clarify, <70 return to planning. Output the score table."
  - "Phase 3 — IMPLEMENT (TDD HARD-GATE for Feature/Bug Fix/Refactoring): Read .claude/skills/story-cycle/references/phase-3-execution.md for full details. Read references/story-types.md for [storyType] execution steps. Load relevant sections of docs/reference/CODING_STANDARDS.md and docs/reference/TESTING_STRATEGY.md. Re-read all target files from plan before editing. CRITICAL: For Feature/Bug Fix/Refactoring stories, write and run a failing test BEFORE writing implementation code. Show test failure output. Only then write implementation. Follow story-type methodology (TDD: RED → GREEN → REFACTOR)."
  - "Phase 4a — SELF-REVIEW (HARD-GATE): Read .claude/skills/story-cycle/references/phase-4-verification.md for full details. Read .claude/skills/story-cycle/references/self-review.md — complete ALL checklist items including ground rules re-check. Read .claude/skills/story-cycle/references/disaster-prevention.md — check for wheel reinvention, spec drift, integration wiring, file structure, regression surface, architecture doc staleness. Dispatch quality skills per risk level (Low: code-quality+test-validator+security-audit-lightweight, Medium: +security-audit-full, High: +architecture-check). At Medium+ risk, also dispatch integration-tester native agent (.claude/agents/integration-tester.md) with test commands + acceptance criteria for independent dynamic verification. If ANY item fails → fix in Phase 3 before proceeding."
  - "Phase 4b — QUALITY GATES (HARD-GATE): Run the project's quality command (from CLAUDE.md Commands section: lint → typecheck → test). Stop on first failure, fix, re-run. Show passing output in the current turn — do NOT claim tests pass without evidence. Do NOT proceed until all gates pass."
  - "Phase 4c — UAT (optional, Feature/Bug Fix only): If project has UAT directory, generate UAT test case + sense check per references/phase-4-verification.md. Skip for Spike/Research, Infrastructure, Documentation, Testing, Refactoring, Performance, Skill/Tooling stories. Also skip if no UAT directory exists."
  - "Phase 4d — COMPLETION VERIFICATION (HARD-GATE): Re-read original AC from plan. For EACH criterion, provide concrete evidence (test output, file:line, command output). Max 2 extra loop passes if gaps found. Do NOT print completion report until every AC has evidence."
  - "Phase 4e — DOCS + COMMIT: (1) Update epic file (mark story DONE in heading, check all AC boxes). (2) Update BACKLOG_INDEX.md (increment Done, decrement TODO for epic row, update Total row). (3) Update docs/progress.md (story status ✅). (4) Update sprint spec (docs/sprints/sprint-N.md): set story Status to ✅, Session column to today's date. (5) Update CLAUDE.md if it contains backlog counts or epic progress that changed. (6) Emit skill metrics event to docs/sessions/.activity-log.jsonl. (7) Invoke /commit skill. Do NOT merge or create PR — that is sprint-end."
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
