# Story Template

Stories are the unit of AI implementation. Each story must be completable in a single context window, have machine-verifiable acceptance criteria, and include explicit scope boundaries. This template produces zero-ambiguity stories that an AI agent implements correctly on the first attempt.

## Full Story Structure (STANDARD)

```markdown
---
id: [PROJECT]-[NUMBER]
title: [Clear, one-line summary of what changes]
type: feature|bugfix|refactor|spike|infra|testing|docs|security|performance|skill
priority: P0|P1|P2|P3
size: TRIVIAL|SMALL|STANDARD|LARGE|XL
status: draft|ready|in-progress|review|done|blocked
created: YYYY-MM-DD
---

# [Title]

## Why
[1-2 sentences: What problem does this solve? What user/business value?]

## Context
- **Current state**: [What exists now — behavior, relevant code, prior decisions]
- **Affected files**: [Explicit list of files/modules that will change. Keep it short for TRIVIAL–STANDARD; LARGE and XL stories legitimately touch more]
- **Follow patterns in**: [Path to exemplar file the AI should read and follow]
- **Dependencies**: [Story IDs that must be complete first, or "None"]
- **Personas**: [P1 (Name — Role), P2 (Name — Role) | or "internal" for infra/refactoring]

## Acceptance criteria
- [ ] [Specific, testable outcome — state WHAT not HOW]
- [ ] [Edge case or error condition]
- [ ] [Another testable outcome]
- [ ] Given [precondition], when [action], then [verifiable result]

## Verification
```bash
# Targeted tests pass
[test command] -- --grep "[feature-name]"
# No lint errors
[lint command]
# Build succeeds
[build command]
```

## Out of scope
- [Thing that might seem related but is NOT part of this story]
- [Future enhancement tracked in PROJ-XXX]
- [Constraint: Must NOT modify X]

## Relevant Decisions
<!-- Auto-populated from DECISION_LOG.md during story generation. Omit section if no discovery was run. -->
- D003: Database — PostgreSQL on Supabase (CONFIRMED)
- D007: Auth — Supabase Auth with magic links (CONFIRMED)

## Relevant Assumptions
<!-- Auto-populated from ASSUMPTION_REGISTER.md. Omit section if no discovery was run. -->
- A002: Users prefer email auth over social (MEDIUM confidence)

## No-Gos for This Story
<!-- Auto-populated from vision/project-pitch.md. Omit section if no discovery was run. -->
- Do NOT implement social login (Phase 2)
- Do NOT add admin dashboard (Phase 2)

## Notes
[Optional: implementation hints, known gotchas, links to designs or ADRs]
```

## Acceptance Criteria Guidelines

**Checklist-style AC is the default.** Each item maps to a discrete testable assertion. Use 3–7 criteria for TRIVIAL through STANDARD stories — fewer means insufficient guidance.

For **LARGE and XL** stories, criteria count scales with the mechanism: group them under sub-headings by the mechanism's parts rather than forcing a split. A long AC list is only a splitting signal when the criteria describe *unrelated topics* — see the cohesion test under Size Classification.

**Use Given/When/Then only when preconditions matter** — complex behavioral scenarios involving multiple states or setup steps. Most AC should be direct outcome statements.

**The Goldilocks zone:**
- Specify (always): expected behavior, edge cases, error conditions, data formats, verification commands
- Don't specify (usually): implementation approach, internal architecture, specific algorithms

**Anti-patterns:**
- "Should be fast" → Replace with measurable: "Response time < 200ms at p95"
- "Handle errors properly" → Replace with specific: "Returns 400 with validation error body when email is missing"
- "Make it work" → Replace with observable: "User sees confirmation message after form submission"

## Type-Specific Variations

### Bug Fix
Replace the `## Why` section with:

```markdown
## Bug
- **Current behavior**: [What happens now — include error message if applicable]
- **Expected behavior**: [What should happen]
- **Steps to reproduce**: 1. ... 2. ... 3. ...
- **Root cause** (if known): [Description or "Unknown — investigate first"]
```

### Spike / Research
Replace `## Acceptance criteria` with:

```markdown
## Research questions
1. [Specific question to answer]
2. [Specific question to answer]

## Output
- [ ] Decision document at [path] with recommendation
- [ ] Timebox: [X hours]
```

### Refactoring
Add after `## Acceptance criteria`:

```markdown
## Constraints
- No changes to external behavior (refactor only)
- All existing tests must pass without modification
```

### Performance
Add after `## Acceptance criteria`:

```markdown
## Metrics
- **Current**: [Measured baseline, e.g., p95 = 450ms]
- **Target**: [Required outcome, e.g., p95 < 200ms]
- **Benchmark command**: `[benchmark command]`
```

## Size Classification

**Size follows conceptual cohesion, not file count.**

The old ceiling — "more than 5 files, must split" — was a proxy for context-window limits that no
longer bind. A story is one coherent unit of work with a single conceptual center; splitting it by
an arbitrary file count produces artificial seams and broken intermediate states.

### The test

> If I split this story, do I get two independently meaningful pieces — or artificial seams and a
> broken intermediate state?

- **Two meaningful pieces → split.**
- **Artificial seams → keep it whole**, however many files it touches.

| Size | Criteria | AI Workflow |
|------|----------|-------------|
| **TRIVIAL** | Single file, <10 lines, no behavioral change (typo, config, comment) | Direct implementation, minimal review |
| **SMALL** | One clear change following an existing pattern | Implement → test → review |
| **STANDARD** | One coherent feature, requires a plan, integrates with existing code | Plan → review plan → implement → test → review |
| **LARGE** | One coherent mechanism whose parts interlock and cannot be meaningfully tested in isolation | Plan → review plan → implement → integration test → review |
| **XL** | A complete subsystem with a single conceptual center | Plan → review plan → staged implementation → full test suite → review |
| **Bundle** | Multiple *unrelated* topics sharing one story ID | **Not a size — split by topic** |

### Worked examples

**Legitimately XL** — *"The complete lease lifecycle: claim, heartbeat, renewal, expiry, watchdog,
fencing-token validation, revocation."*
Every part interlocks. A claim that cannot expire is not half a feature; it is a non-feature that
cannot be meaningfully tested. Splitting produces broken intermediate states.

**Not a story, just a bundle** — *"Lease lifecycle + OAuth + CLI output formatting."*
Three unrelated topics sharing one ID. Worse than three stories, not better.

**Correctly SMALL** — *"Add `--json` flag to CLI read commands."*
Small because it genuinely is. Do not inflate a small story to look substantial.

### Rules

- **Large is permitted, never mandated.** Do not create XL stories because they are allowed.
- **Split by topic, not by layer.** Every story stays a vertical slice — never "the database part"
  and "the API part" of one feature.
- **Acceptance criteria scale with size.** LARGE and XL stories may exceed the usual 3-7 criteria;
  group them under sub-headings by the mechanism's parts.
- **When genuinely uncertain, prefer the larger coherent story.** Re-splitting later is cheap;
  reassembling artificially severed work is not.

Remaining sizing factors: degree of implicit knowledge required, whether established patterns
exist, and integration surface area. File count is an input to judgement, never a threshold.

Projects may override this section — see `docs/reference/STORY_SIZING.md` in the project scaffold.

## Splitting Strategy (SPIDR)

When a story fails the cohesion test above, split in this order of preference:

1. **Paths** — Separate happy path from alternate/error flows
2. **Data** — Restrict data scope (one type first, add others later)
3. **Rules** — Defer complex business rules (simplified validation first)
4. **Interface** — Minimal UI first, enhance later
5. **Spike** — If unknowns prevent splitting, research first

Each resulting story must be a **vertical slice** (UI + logic + data), not a horizontal layer.

## Self-Contained by Default

Shape every story to stand on its own: one complete outcome, minimal dependence on
other stories, no shared hot files where avoidable. **Outcome over output** — one
story that ships a whole small outcome beats two half-stories that only work together.

- Prefer a vertical slice that is independently shippable and testable
- Use the Dependencies field for genuine prerequisites only. A backlog where most
  stories depend on each other is a signal to reshape the stories, not a normal state
- Extract shared groundwork (schema, scaffolding, external accounts) into its own
  setup story that others depend on, instead of spreading it across feature stories
- Independent stories are what makes parallel work possible: two stories with no
  dependencies and no overlapping affected files can be built simultaneously in
  separate streams (`/parallel-work`). Dependent or overlapping stories should be
  worked sequentially in one branch
- Never force independence at the cost of cohesion: if splitting produces artificial
  seams (see the cohesion test above), keep the story whole and work it sequentially

## Embedded Format (Stories in Epic Files)

When stories are embedded in epic files (`docs/reference/backlog/E##-*.md`), use inline metadata instead of YAML frontmatter (since `---` becomes a horizontal rule in nested markdown):

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
**Type:** feature · **Size:** SMALL · **Priority:** P0 · **Status:** ready · **Created:** 2026-03-25

#### Why
[content]

#### Acceptance criteria
- [ ] [criterion]

#### Verification
[commands]

#### Out of scope
- [exclusion]
```

See `docs/reference/backlog/_EPIC_TEMPLATE.md` for the complete epic file structure.

## Story Quality Checklist (Definition of Ready)

A story is ready for AI implementation when ALL of these are true:

- [ ] Title is clear and specific — describes the change, not the problem
- [ ] Type is assigned — one of the 10 supported types
- [ ] Size is classified — TRIVIAL, SMALL, STANDARD, LARGE, or XL
- [ ] Story passes the cohesion test — splitting it would create artificial seams, not two meaningful pieces
- [ ] Acceptance criteria exist — 3-7 specific, testable conditions
- [ ] Verification commands specified — exact commands that prove completion
- [ ] Out of scope is defined — at least one explicit exclusion
- [ ] Affected files listed — proportionate to size, not capped at a fixed number
- [ ] Pattern references included — "Follow patterns in [file]" where applicable
- [ ] Dependencies resolved or documented — no unresolved blockers
- [ ] No ambiguous language — no "should be fast," "handle errors properly," "make it work"
- [ ] Self-contained — all referenced context is included or linked
