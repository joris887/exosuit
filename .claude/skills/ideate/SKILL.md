---
name: ideate
version: 2.10.0
description: Use when the user has an idea or requirement to decompose into backlog stories.
trigger: manual
depends-on: []
references: [references/story-template.md]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Edit, Write, WebSearch, WebFetch, Agent
argument-hint: "<idea-or-requirement>"
---
______________________________________________________________________

## ideate

**Skill metrics:** Emit a start event to the activity log:
```bash
echo "{\"type\":\"skill\",\"event\":\"start\",\"skill\":\"ideate\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl
```

Transforming idea into backlog stories: **$ARGUMENTS**

## Step 0: Check Discovery State

<IF condition="vision/project-pitch.md exists">
Discovery has been completed. Load `docs/reference/DECISION_LOG.md` and `docs/reference/ASSUMPTION_REGISTER.md` for story generation context. When generating stories, include relevant entries in each story under "Relevant Decisions", "Relevant Assumptions", and "No-Gos" sections.
</IF>
<IF condition="vision/idea-capture.md exists BUT vision/project-pitch.md does NOT exist">
Discovery hasn't been completed. Warn the user:
> "Discovery hasn't been completed. Run `/discover` first for thorough guided discovery, or proceed with `/ideate` for quick decomposition (less guidance, more assumptions)."
Wait for user decision before proceeding.
</IF>
<ELSE>
No vision files found — proceed with current behavior (no change).
</ELSE>

## Phase 0: Validate Prerequisites

Before starting, verify:
- `docs/reference/backlog/` directory exists (create if missing)
- `docs/reference/BACKLOG_INDEX.md` is readable
- No conflicting ideation in progress (check for uncommitted backlog changes)

If prerequisites fail, inform the user and stop — don't consume context on doomed work.

### Sprint Scope Awareness

Check if a sprint is currently active (branch matches `sprint-*` or `docs/progress.md` shows an in-progress sprint). If so, display a notice:

> **Sprint [N] is in progress** (goal: "[sprint goal]"). New stories will be added to the backlog, not the current sprint. Adding stories to a running sprint increases sprint churn — target is <20%.

This is informational, not blocking. The user may legitimately need to ideate during a sprint. But it prevents accidental scope creep where new stories get silently mixed into active sprint work.

## 1. Gather Input

**Check for prior brainstorm artifacts:** Search `docs/brainstorms/` for existing design documents matching the topic. If a brainstorm doc exists with `status: decided`, load it as context — the design exploration and key decisions have already been made.

Understand the idea or requirement from `$ARGUMENTS` and any additional context the user provides.

Ask clarifying questions if the idea is too vague:

- What problem does this solve?
- Who benefits from this?
- What does "done" look like?
- Are there constraints or preferences?

## 2. Research Context

Explore the codebase to understand:

- Related existing code and patterns
- Architectural constraints (read `docs/architecture/ARCHITECTURE.md`)
- Ground rules (read `docs/reference/GROUND_RULES.md` if exists) — stories must not require MUST violations
- What already exists vs what needs to be built
- Testing patterns in the relevant area
- Dependencies on existing code

### Persona Context

Read `docs/context/personas.md` if it exists. When present, note each persona's goals, frustrations, and evaluation criteria — these inform story decomposition and acceptance criteria. Note the primary persona (★) for prioritization decisions.

### Product Requirements Context

Read `docs/reference/PRD_SUMMARY.md` if it exists. When present, extract:

- **Section 1 (Problem):** Does the idea align with the stated product problem? Flag divergence.
- **Section 3 (Success criteria):** Stories should trace to these — they become verification targets.
- **Section 5 (Requirements):** Check if the idea maps to existing requirements. If so, use their EARS acceptance criteria as story AC source. If not, note it as a scope addition.
- **Section 6 (NFRs):** Generate dedicated infrastructure stories for NFRs not yet covered in the backlog (observability, security, accessibility, etc.).
- **Section 7 (Scope boundaries):** Use non-goals as story non-goals. Use implementation boundaries to set guard rails on every story.
- **Section 9 (Open questions):** Generate Spike stories for unresolved questions with High impact.

## 2.5. Feasibility Research (Conditional)

If the idea involves external dependencies, unfamiliar technology, or integration with third-party services, perform a quick feasibility check before decomposition.

Compose the `deep-research` methodology (`.claude/prompts/deep-research.md`) at **QUICK** depth:

- **Query:** Generated from the idea's key technical requirements
- **Sub-questions** (1-2, focused on feasibility):
  1. "Does [key library/API] support [required capability]?"
  2. "Are there breaking changes or deprecations in [dependency] for [use case]?"
- **Output format:** `evidence-check` (yes/no/maybe with evidence)

**If feasibility is uncertain:** Add a Spike/Research story to the decomposition to resolve the uncertainty before implementation stories begin.

**Skip when:** The idea uses only well-understood, established technologies already present in the codebase, or when a prior brainstorm/research doc already covers feasibility.

## 3. Decompose into Stories

### Splitting Strategy (SPIDR)

When a requirement is too large for a single story, apply these five splitting patterns in order of preference:

1. **Spike** — Uncertainty exists → create a time-boxed research story first
2. **Path** — Multiple user flows → split by happy path, alternate paths, error paths
3. **Interface** — Multiple devices/platforms → split by interface variant
4. **Data** — Data variations → split by data complexity (basic fields first, advanced later)
5. **Rules** — Business rules → split by happy path first, edge cases later

Each resulting story must be a **vertical slice** (UI + logic + data), not a horizontal layer.

### EARS → Given/When/Then Conversion

When PRD requirements use EARS acceptance criteria, convert them to story-level Given/When/Then:

`WHEN [trigger] THE SYSTEM SHALL [behavior]` → `Given [precondition state], When [trigger occurs], Then [behavior is observed]`

PRD Properties (invariants) become test assertions. PRD edge case tables become additional test scenarios.

Break the idea into properly typed stories. For each story, determine the best type:

| Story Type         | Template                                                                      | Output                        |
| ------------------ | ----------------------------------------------------------------------------- | ----------------------------- |
| **Feature**        | "As a \[user\], I want \[capability\], so that \[benefit\]."                  | Working code + tests          |
| **Bug Fix**        | "Fix: \[defect description\]. Expected: \[behavior\]. Actual: \[behavior\]."  | Fix + regression test         |
| **Refactoring**    | "Refactor \[component\] to \[improvement\] without changing behavior."        | Restructured code             |
| **Spike/Research** | "Investigate \[question\]. Time-box: \[hours\]. Decision criteria: \[list\]." | Decision document or ADR      |
| **Infrastructure** | "Set up \[tooling/config\] to enable \[capability\]."                         | Scripts/config + verification |
| **Testing**        | "Add \[test type\] coverage for \[component/feature\]."                       | Test code + coverage          |
| **Documentation**  | "Document \[topic\] for \[audience\]."                                        | Updated docs                  |
| **Security**       | "Harden \[component\] against \[threat\]. Verify with \[method\]."            | Hardened code + audit         |
| **Performance**    | "Optimize \[operation\] to meet \[target\]. Baseline: \[current\]."           | Optimized code + benchmarks   |
| **Skill/Tooling**  | "Create \[skill/tool\] to automate \[workflow\]."                             | New skill + docs              |

### Story Sizing Constraint

**Each story must fit within a single Claude Code context window.** This means:

- 1-3 hours of focused work maximum
- Touches no more than 5-8 files
- Has a clear, atomic deliverable
- Can be fully tested within the story

If a story feels too large, split it further. Prefer many small stories over few large ones.

### Story Structure

Follow the story template in `references/story-template.md`. Use YAML frontmatter for machine-parseable metadata, checklist-style AC as the default, and explicit verification commands.

For each story, produce:

```markdown
---
id: [PROJECT]-[NUMBER]
title: [Clear, one-line summary of what changes]
type: feature|bugfix|refactor|spike|infra|testing|docs|security|performance|skill
priority: P0|P1|P2|P3
size: TRIVIAL|SMALL|STANDARD
status: draft
created: YYYY-MM-DD
---

# [Title]

## Why
[1-2 sentences: What problem does this solve? What user/business value?]

## Context
- **Current state**: [What exists now — behavior, relevant code, prior decisions]
- **Affected files**: [Explicit list — max 5 files]
- **Follow patterns in**: [Path to exemplar file in codebase]
- **Dependencies**: [Story IDs that must be complete first, or "None"]
- **Personas**: [P1 (Name — Role), P2 (Name — Role) | or "internal" for infra/refactoring stories]

## Acceptance criteria
- [ ] [Specific, testable outcome — WHAT not HOW]
- [ ] [Edge case or error condition]
- [ ] Given [precondition], when [action], then [verifiable result]

## Verification
```bash
[exact commands that prove completion]
```

## Out of scope
- [Explicit exclusion to prevent scope creep]
- [Constraint: Must NOT modify X]
```

**Checklist AC is the default** — each item maps to a testable assertion. Use Given/When/Then only for complex behavioral scenarios with multiple preconditions. Target 3–7 AC per story; more than 7 means the story needs splitting.

For TRIVIAL/SMALL stories, use the lightweight template in `references/story-template-lightweight.md`.

Apply type-specific variations from `references/story-template.md` (Bug Fix → Bug section, Spike → Research questions, Refactoring → Constraints, Performance → Metrics).

### Persona Linkage

If `docs/context/personas.md` was loaded, link each story to persona(s):

1. For each story, determine which persona(s) it primarily serves based on the story's user value and the persona's goals/frustrations
2. Set the `Personas:` field in the story's Context section (e.g., `P1 (Marcus — Power User), P3 (Admin)`)
3. For infrastructure, refactoring, or tooling stories with no direct user: set `Personas: internal`
4. If ALL user-facing stories serve only ONE persona: flag potential imbalance — ask user if secondary personas are underserved in this decomposition
5. For stories serving a specific persona, weave their frustrations and evaluation criteria into acceptance criteria where natural (don't force it — only where it adds clarity)

**Skip when:** `docs/context/personas.md` doesn't exist or contains only template placeholders.

## 4. Identify Missing Skills

For each story, check if the required skills exist:

- Review `.claude/skills/SKILLS_INVENTORY.md`
- If a story needs a skill that doesn't exist, add a **Skill/Tooling** story to create it
- Skill creation stories should come before stories that depend on them

### NFR Story Generation

If PRD Section 6 (NFRs) exists and contains measurable thresholds, generate dedicated stories for each NFR not already covered in the backlog:

- Observability NFR → "Set up structured logging and error alerting" [Infrastructure]
- Accessibility NFR → "Implement [WCAG level] compliance for [component]" [Feature]
- Security NFR → "Configure [encryption/auth] for [scope]" [Security]
- Performance NFR → "Establish performance baseline and optimization for [target]" [Performance]

These stories ensure NFRs become tracked, tested work items rather than implicit expectations.

### Security Acceptance Criteria Generation

For stories touching authentication, authorization, user data handling, API endpoints, file uploads, or session management, auto-append security acceptance criteria using Given/When/Then format:

```gherkin
# Injection defense (for any story handling user input)
- [ ] Given a user submits input containing SQL/XSS/command injection payload, When the input is processed, Then the system rejects or sanitizes the input and returns a generic error

# Auth enforcement (for any story adding/modifying endpoints)
- [ ] Given an unauthenticated request to a protected endpoint, When the request is processed, Then the system returns 401/403 and logs the attempt

# Input validation (for any story accepting user data)
- [ ] Given input exceeding expected size/type/format constraints, When submitted, Then the system rejects with a clear validation error
```

Select 1-2 criteria relevant to the story type — not all three for every story. These are in addition to the story's functional acceptance criteria.

**Evil user stories** (for stories explicitly about security features): Generate an attacker-perspective story variant:
- *"As an attacker, I want to manipulate [input/ID/token] to access [resource] belonging to other users."*
- Use these to derive security test cases and red-team acceptance criteria.

## 5. Order for Testability

### External Service Setup Stories (conditional)

If `vision/external-dependencies.md` exists (generated by `/discover`), read it and generate an **Infrastructure** setup story for each external service listed.

Each setup story:
- Uses story type `infra` with clear setup instructions in the body
- Is sized `SMALL` (most setups take 15-30 min)
- Has acceptance criteria: account created, credentials stored in `.env` (or project secrets), connectivity verified with a smoke test
- Includes the setup steps, credentials needed, and free tier info from the external dependency summary
- Is ordered immediately BEFORE the first feature story that depends on that service — not all bunched at the start

If `vision/external-dependencies.md` doesn't exist, scan `docs/reference/DECISION_LOG.md` for dimension decisions (D05-D10) that selected external services — any service requiring an account, API keys, or external infrastructure. Generate setup stories for each external service found, using the same pattern above.

### Story Ordering

Organize stories in a logical order that enables incremental testing:

1. **Testing infrastructure first** — E2E test skeletons, fixtures, mocks
1. **Foundation stories** — core functionality that other stories depend on
1. **External service setup** — each setup story directly before the feature(s) that need it
1. **Feature stories** — build on the foundation, enable E2E tests incrementally
1. **Quality stories** — refactoring, performance, security hardening
1. **NFR stories** — infrastructure, observability, security, accessibility (from PRD Section 6)
1. **Documentation stories** — document what was built

**Key principle:** Each story should be independently verifiable. Tests from earlier stories should keep passing as later stories are delivered.

### E2E Test Strategy

If the idea involves multiple stories:

1. Create a testing story first that sets up E2E test skeleton (disabled tests)
1. As feature stories are delivered, enable corresponding E2E tests
1. This ensures integration is tested continuously, not just at the end

## 6. Output

Present the decomposed stories to the user:

```markdown
### Backlog: <Idea Title>

**Stories:** [count] | **Sizes:** [X TRIVIAL, Y SMALL, Z STANDARD]

#### Story Order (dependency-resolved):
| # | ID | Title | Type | Size | Priority | Depends On |
|---|-----|-------|------|------|----------|------------|
| 1 | PROJ-001 | [Title] | feature | SMALL | P0 | None |
| 2 | PROJ-002 | [Title] | feature | STANDARD | P1 | PROJ-001 |

#### Detailed Stories:
[Full story definitions using the template structure above]

#### Dependency Graph:
[Simple ASCII or description of dependencies]
```

### Definition of Ready Validation

Before presenting stories, validate each against the Definition of Ready checklist (from `references/story-template.md`):

- [ ] Title clear and specific
- [ ] Type assigned (one of 10 types)
- [ ] Size classified (TRIVIAL/SMALL/STANDARD)
- [ ] 3-7 acceptance criteria, all testable
- [ ] Verification commands specified
- [ ] Out of scope defined (at least one exclusion)
- [ ] Affected files listed (max 5)
- [ ] Pattern references included (where applicable)
- [ ] Dependencies resolved or documented
- [ ] No ambiguous language
- [ ] Self-contained

Stories passing all criteria → `status: ready`. Stories missing criteria → `status: draft` with a note listing what's missing.

### Document Quality Check

Before presenting for approval, dispatch a fresh sub-agent to test the story decomposition from a reader's perspective:

- **Agent type:** Explore (read-only, forked context)
- **Input:** ONLY the story decomposition output — no conversation history
- **Instructions:** "You are a developer who will implement these stories. For each story: (1) Is the description clear enough to start work? (2) Are acceptance criteria testable and unambiguous? (3) Are file hints specific enough? (4) Are non-goals clear? Flag any story that you'd need to ask questions about before starting."

Review findings. Fix genuine gaps in the stories before presenting to user.

Ask user for approval before writing to backlog files.

<HARD-GATE>
Do NOT write any stories to backlog files, create epic files, or update BACKLOG_INDEX.md until the user has explicitly approved the decomposition. Present the stories, wait for approval.
</HARD-GATE>

## 7. Write to Backlog

After user approval:

### Epic File Format

Use the epic template from `docs/reference/backlog/_EPIC_TEMPLATE.md`. Each epic file has:

1. **YAML frontmatter** at the top: `id`, `title`, `status`, `priority`, `target`
2. **Story checklist** for quick scanning: `- [ ] ID — Title (Priority, Status)`
3. **Detailed story sections** below with inline metadata (not YAML frontmatter — see `references/story-template.md` Embedded Format section)

### Writing Steps

- Create or update the epic file in `docs/reference/backlog/`
- Add each story to the checklist AND as a detailed subsection
- Update `docs/reference/BACKLOG_INDEX.md`:
  - Add stories to the appropriate priority table (P0/P1/P2/P3)
  - Update the Story ID to Epic Mapping table
  - Update Backlog Health counts
- Update CLAUDE.md Current Focus if appropriate
- Emit story creation events:
  ```bash
  echo "{\"type\":\"story\",\"event\":\"created\",\"id\":\"<id>\",\"story_type\":\"<type>\",\"size\":\"<size>\",\"priority\":\"<priority>\",\"status\":\"<ready|draft>\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl
  ```

## Example

```
Input:  /ideate "user authentication with email/password"
Output: 5 stories decomposed:
        S01: Testing infrastructure (fixtures, test helpers) [Testing]
        S02: User model + migration [Feature]
        S03: Registration endpoint with validation [Feature]
        S04: Login endpoint with JWT tokens [Feature]
        S05: Auth middleware for protected routes [Feature]
        Dependency graph: S01 → S02 → S03/S04 → S05

Next Steps:
→ /sprint-start — create a sprint branch to start implementing
→ /story-cycle "S01: Testing infrastructure" — deliver the first story
```

## Rules

- Each story must fit in a single AI context window — max 5 affected files, describable in one sentence with one measurable outcome
- Acceptance criteria must be machine-verifiable — exact commands in the Verification section that prove completion
- 3–7 acceptance criteria per story. Fewer = insufficient guidance. More than 7 = story needs splitting.
- Out of scope section is mandatory — at least one explicit exclusion to prevent AI scope creep
- No ambiguous language in AC — reject "should be fast", "handle errors properly", "make it work"
- Every story must have a size classification (TRIVIAL/SMALL/STANDARD) in frontmatter — this drives /story-cycle workflow depth
- Spike stories must have a time-box and explicit research questions
- Testing stories come before feature stories in the order
- Follow coding standards in `docs/reference/CODING_STANDARDS.md`
- Follow testing strategy in `docs/reference/TESTING_STRATEGY.md`
- Follow architecture constraints in `docs/architecture/ARCHITECTURE.md`
- Follow ground rules in `docs/reference/GROUND_RULES.md` (if exists) — no story should require a MUST violation
