# Story Template (v5.0 — Outcome-First)

Stories are the unit of AI implementation. **The outcome is stable; the implementation is volatile.** This template separates the two so stories can be written at backlog-time and re-refined against the current codebase at sprint-start without losing their meaning.

## Four-section structure

1. **Outcome** (stable): Why, Acceptance Criteria, Out of Scope, Personas. Never re-written between ideate and execution.
2. **Verification** (stable): commands and observables that prove the outcome was met.
3. **Implementation Hints** (STALE BY DEFAULT — refined at sprint-start): file lists, exemplar patterns, dependencies. Frozen at write-time; will be re-derived.
4. **Frontmatter**: machine-parseable metadata.

## Full Story Structure (STANDARD)

```markdown
---
id: [PROJECT]-[NUMBER]
title: [Clear, one-line summary of the OUTCOME the user gets]
type: feature|bugfix|refactor|spike|infra|testing|docs|security|performance|skill
priority: P0|P1|P2|P3
size: TRIVIAL|STANDARD|LARGE
status: draft|ready|in-progress|review|done|blocked
created: YYYY-MM-DD
refined_at: <!-- set by /sprint-start step 3.5 when story is picked for a sprint -->
outcome_invalidated_by: <!-- set by /sprint-start if user kept an invalidated story -->
---

# [Title]

## Outcome

### Why
[1-2 sentences: What user/business value does this deliver? Anchor on the user, not the implementation.]

### Acceptance Criteria
- [ ] [Outcome-asserting, testable condition — WHAT the user can do or observe, not HOW the system does it]
- [ ] [Edge case or error condition the user might hit]
- [ ] [Another outcome the user gets]
- [ ] Given [precondition], when [action], then [verifiable result]

### Out of Scope
- [Thing that might seem related but is NOT part of this outcome]
- [Future enhancement tracked in PROJ-XXX]

### Personas
[P1 (Name — Role), P2 (Name — Role) | or "internal" for infra/refactoring stories]

## Verification

```bash
# Commands that prove the outcome is met. These do not change between sprint-start refinements.
[test command] -- --grep "[feature-name]"
[lint command]
```

## Implementation Hints (STALE BY DEFAULT — refined at sprint-start)

<!-- These hints freeze at ideate time and rot as the code changes. /sprint-start step 3.5 re-derives them against the current brain. Until refined_at is set, treat as starting suggestions only. -->

- **Affected files (suggested):** [explicit list — re-derived at sprint-start]
- **Pattern to follow:** [Path to exemplar `file:line` — re-derived at sprint-start]
- **Existing helpers to reuse:** [helpers found at ideate time — re-derived at sprint-start]
- **Dependencies:** [Story IDs that must be complete first, or "None"]

## Relevant Decisions
<!-- Auto-populated from DECISION_LOG.md during story generation. Omit section if no discovery was run. -->
- D003: Database — PostgreSQL on Supabase (CONFIRMED)

## Relevant Assumptions
<!-- Auto-populated from ASSUMPTION_REGISTER.md. Omit section if no discovery was run. -->
- A002: Users prefer email auth over social (MEDIUM confidence)

## No-Gos for This Story
<!-- Auto-populated from vision/project-pitch.md. Omit section if no discovery was run. -->
- Do NOT implement social login (Phase 2)
```

## Acceptance Criteria Guidelines — Outcome-Asserting, Not Implementation-Prescriptive

Each AC must describe **what the user gets or observes**, not **how the code does it**. If the AC names a class, function, or file, it's prescriptive — rewrite as observable behavior.

### Anti-patterns and replacements

| Implementation-prescriptive (WRONG) | Outcome-asserting (RIGHT) |
|--------------------------------------|---------------------------|
| `LoginController.handle()` returns a session token | User who submits valid credentials receives a session and lands on the home screen |
| Add a `validateEmail()` function in `src/auth/validators.ts` | An invalid email format is rejected at form submit with a visible error message |
| Refactor `UserService` to use Repository pattern | (this is a refactor — the outcome should be observable behavior unchanged; if there's no user-facing outcome, type this as a refactor story, not a feature) |
| Tests call `mockOAuthProvider.success()` | Users can sign in with Google and Apple |
| Response time should be fast | Search returns first results in <200ms p95 over 100 trial queries |
| Handle errors properly | When the upstream API returns 5xx, the user sees a retry button and the request is queued |
| Use Redis for caching | Sessions survive a single backend restart (verified by restart-and-recall test) |
| Should work | Listed concrete observable: e.g. "user can complete checkout end-to-end with a single test card" |

### When prescription is OK

- **Infra/Refactor stories** — these have no user-facing outcome by definition. AC can reference internal contracts.
- **Bug fix stories** — AC includes the regression test which IS prescriptive (file:test name).
- **Spike stories** — AC is "a decision is documented" not user-observable; that's the outcome.

### How specific is "specific enough"

Specify (always): expected behavior, edge cases, error conditions, data formats, verification commands.
Don't specify (usually): which file, which class, which algorithm.

The rule of thumb: **if a future code refactor would invalidate the AC even though the user-visible behavior is unchanged, the AC is too prescriptive.**

## Type-Specific Variations

### Bug Fix
Replace the `### Why` section with:

```markdown
### Bug
- **Current behavior**: [What happens now — include error message if applicable]
- **Expected behavior**: [What should happen — user-observable]
- **Steps to reproduce**: 1. ... 2. ... 3. ...
```

### Spike / Research
Replace `### Acceptance Criteria` with:

```markdown
### Research questions
1. [Specific question to answer]
2. [Specific question to answer]

### Output
- [ ] Decision document at [path] with recommendation
- [ ] Stopping condition: [observable condition that ends the spike — not a clock value]
```

### Refactoring
Add inside `### Out of Scope`:

```markdown
### Constraints
- No changes to external behavior (refactor only)
- All existing tests must pass without modification
```

### Performance
Add after `### Acceptance Criteria`:

```markdown
### Metrics
- **Current**: [Measured baseline, e.g., p95 = 450ms]
- **Target**: [Required outcome, e.g., p95 < 200ms]
- **Benchmark command**: `[benchmark command]`
```

## Size Classification (v5.0 — verification-budget bounds)

Sizing is by **what the outcome can be re-verified against** at completion, not by hours or files.

| Size | When to use | /story-cycle path |
|------|-------------|-------------------|
| **TRIVIAL** | Single-file change, no AC needed beyond observation (rename, typo, config tweak) | Fast-track (skip Phase 1, 2, 2.5) |
| **STANDARD** | One vertical user-observable outcome. 3-7 AC, each individually verifiable in Phase 4.5 with command output or file:line evidence. PR target ≤500 LOC, ceiling 1000 LOC. Default. | Full phases |
| **LARGE** | Exceeds STANDARD intentionally (big migration, multi-module feature that doesn't usefully split). 8-12 AC. Requires explicit user approval at ideate-time. Adds per-AC checkpoints and mandatory integration-tester dispatch. | Full phases + extra checkpoints |

Beyond LARGE — split. No story should exceed the verification budget where every AC can be re-checked in one Phase 4.5 pass.

**No estimation in hours, days, or "sessions."** Those anchor to human pace and produce systematically wrong predictions for Claude Code.

## Splitting Strategy (SPIDR)

When a story exceeds the size bounds, split in this order:

1. **Paths** — Separate happy path from alternate/error flows
2. **Data** — Restrict data scope (one type first, add others later)
3. **Rules** — Defer complex business rules (simplified validation first)
4. **Interface** — Minimal UI first, enhance later
5. **Spike** — If unknowns prevent splitting, research first

Each resulting story must be a **vertical slice** (UI + logic + data), not a horizontal layer.

## Embedded Format (Stories in Epic Files)

When stories are embedded in epic files (`docs/reference/backlog/E##-*.md`), use inline metadata instead of YAML frontmatter:

**Epic story checklist** (top of epic, for quick scanning):
```markdown
## Stories
- [ ] PROJ-001 — User login with email (P0, ready)
- [ ] PROJ-002 — Fix session timeout crash (P1, in-progress)
- [x] PROJ-003 — Password reset flow (P0, done)
```

Format: `- [ ] ID — Title (Priority, Status)` — mark done stories with `[x]`.

**Detailed story sections** (below the checklist):
```markdown
### PROJ-001: User login with email
**Type:** feature · **Size:** STANDARD · **Priority:** P0 · **Status:** ready · **Created:** 2026-03-25 · **Refined:** —

#### Outcome
##### Why
[content]
##### Acceptance Criteria
- [ ] [outcome-asserting criterion]
##### Out of Scope
- [exclusion]

#### Verification
[commands]

#### Implementation Hints (STALE BY DEFAULT — refined at sprint-start)
- Affected files: ...
- Pattern: ...
```

## Story Quality Checklist (Definition of Ready)

A story is ready when ALL of these are true:

- [ ] Title describes the OUTCOME, not the implementation
- [ ] Type assigned (one of the 10 types)
- [ ] Size classified (TRIVIAL/STANDARD/LARGE)
- [ ] 3-7 (STANDARD) or 8-12 (LARGE) acceptance criteria — all outcome-asserting
- [ ] No AC names a specific file, class, or function (unless type is infra/refactor/bugfix)
- [ ] Verification commands specified
- [ ] Out of scope includes at least one explicit exclusion
- [ ] Implementation Hints section present (even if "TBD at sprint-start")
- [ ] Personas linked (or marked "internal")
- [ ] No ambiguous language ("should be fast", "handle errors properly", "make it work")
