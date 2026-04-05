# Story Template

Stories are the unit of AI implementation. Each story must be completable in a single context window, have machine-verifiable acceptance criteria, and include explicit scope boundaries. This template produces zero-ambiguity stories that an AI agent implements correctly on the first attempt.

## Full Story Structure (STANDARD)

```markdown
---
id: [PROJECT]-[NUMBER]
title: [Clear, one-line summary of what changes]
type: feature|bugfix|refactor|spike|infra|testing|docs|security|performance|skill
priority: P0|P1|P2|P3
size: TRIVIAL|SMALL|STANDARD
status: draft|ready|in-progress|review|done|blocked
created: YYYY-MM-DD
---

# [Title]

## Why
[1-2 sentences: What problem does this solve? What user/business value?]

## Context
- **Current state**: [What exists now — behavior, relevant code, prior decisions]
- **Affected files**: [Explicit list of files/modules that will change — max 5]
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

**Checklist-style AC is the default.** Each item maps to a discrete testable assertion. Use 3–7 criteria per story. Fewer means insufficient guidance; more than 7 means the story needs splitting.

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

| Size | Criteria | AI Workflow |
|------|----------|-------------|
| **TRIVIAL** | Single-file, <10 lines, no behavioral change (typo, config, comment) | Direct implementation, minimal review |
| **SMALL** | 1-2 files, <50 lines, follows existing patterns, clear AC | Implement → test → review |
| **STANDARD** | 3-5 files, requires plan, integrates with existing code | Plan → review plan → implement → test → review |
| **Too large** | >5 files or scope unclear | **Must split** before implementation |

Key sizing factors: number of files (context window pressure), degree of implicit knowledge required, whether established patterns exist, integration surface area.

## Splitting Strategy (SPIDR)

When a story is too large, split in this order of preference:

1. **Paths** — Separate happy path from alternate/error flows
2. **Data** — Restrict data scope (one type first, add others later)
3. **Rules** — Defer complex business rules (simplified validation first)
4. **Interface** — Minimal UI first, enhance later
5. **Spike** — If unknowns prevent splitting, research first

Each resulting story must be a **vertical slice** (UI + logic + data), not a horizontal layer.

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
- [ ] Size is classified — TRIVIAL, SMALL, or STANDARD
- [ ] Acceptance criteria exist — 3-7 specific, testable conditions
- [ ] Verification commands specified — exact commands that prove completion
- [ ] Out of scope is defined — at least one explicit exclusion
- [ ] Affected files listed — max 5 files
- [ ] Pattern references included — "Follow patterns in [file]" where applicable
- [ ] Dependencies resolved or documented — no unresolved blockers
- [ ] No ambiguous language — no "should be fast," "handle errors properly," "make it work"
- [ ] Self-contained — all referenced context is included or linked
