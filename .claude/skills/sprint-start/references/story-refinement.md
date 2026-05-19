# Story Re-Refinement Reference

Detailed rules for sprint-start Step 3.5 — how to re-derive Implementation Hints against the current brain.

## Why this step exists

Stories written by `/ideate` capture two things:

1. **Outcome** — Why, Acceptance Criteria, Out of Scope, Personas. These are stable. They describe what the user gets.
2. **Implementation Hints** — file lists, exemplar patterns, dependency stories. These freeze at write-time and rot.

Without re-refinement, `/story-cycle` Phase 1 reads stale hints and quietly recovers by re-exploring — burning context to do what should have been an upstream refinement step.

## What counts as the "outcome"

The Outcome sections must NOT be edited in this step. They are the contract with the user. If the outcome itself is wrong, the right action is to kill the story or send it back to `/ideate` — not to silently rewrite it during sprint-start.

The only frontmatter field that may be added at this step:

- `outcome_invalidated_by: <reason>` — set when user chose to keep an invalidated story; records the conflict.

## Refinement targets

Within `## Implementation Hints (refined at sprint-start)`:

| Sub-section | Source for re-derivation |
|-------------|--------------------------|
| Affected files | grep against current codebase + `docs/brain/project-structure.md` |
| Pattern to follow | `docs/brain/system-patterns.md` + cite a current exemplar `file:line` |
| Existing helpers to reuse | grep for utility functions in the affected area + `docs/brain/system-patterns.md` (recipes) |
| Dependencies | check `docs/reference/BACKLOG_INDEX.md` for current status of listed deps |

## Invalidation signals

Apply these checks before continuing:

| Signal | What it looks like | Action |
|--------|--------------------|--------|
| Already shipped | `current-state.md` "What Works Now" lists the outcome with a file:line citation | Flag [INVALID]: ask user kill/keep/edit |
| Now blocked | An in-progress sprint story or a recent constraint conflicts with the outcome | Flag [BLOCKED]: ask user defer/re-scope/proceed |
| Outcome too vague | Story has <3 ACs or ACs use implementation-prescriptive language | Flag [WEAK]: send back to `/ideate` |
| Implementation hints empty | Story was written under v4 format without hints structure | Generate fresh hints from outcome + brain |

## Speed budget

Per-story target: ≤2 minutes (grep + 3 brain page reads + small edit).

If a story needs longer:
- It might be too large (signal to split).
- Or the brain is too thin (signal: log a brain gap, run `/brain-update` after the sprint).

## Anti-patterns

- **Don't re-explore the codebase** — that's what `/story-cycle` Phase 1 is for. This step relies on the brain.
- **Don't rewrite the outcome** — only the Implementation Hints section is in scope.
- **Don't refine stories you didn't select** — re-refinement applies only to this sprint's chosen stories.
- **Don't skip the flag check** — invalidated stories that ship anyway create churn worse than backlog rot.

## Example

Story `PROJ-014` was written 5 weeks ago:

```markdown
## Implementation Hints (refined at sprint-start)
<!-- frozen at create date 2026-04-12 -->
- Affected files: src/auth/login.ts, src/middleware/session.ts
- Pattern to follow: cookie-based session (see middleware/session.ts:18)
- Dependencies: PROJ-010 (done), PROJ-011 (done)
```

In sprint-start step 3.5, the refiner:

1. Reads `docs/brain/log.md` — finds an entry: `## [2026-05-02] sprint-end shipped | sprint-12 — session storage migrated to Redis (src/cache/session-store.ts:1)`.
2. Reads `current-state.md` — confirms Redis session store is now load-bearing.
3. Re-derives:

```markdown
## Implementation Hints (refined at sprint-start)
<!-- refined 2026-05-19 — original hints were pre-Redis migration -->
- Affected files: src/auth/login.ts, src/cache/session-store.ts (NEW vs original hints — session moved here)
- Pattern to follow: Redis session pattern (src/cache/session-store.ts:1-42)
- Existing helpers to reuse: SessionStore.create(), SessionStore.validate()
- Dependencies: PROJ-010 (done), PROJ-011 (done) — no new deps
```

The outcome (Why, AC) was untouched. Only the hints changed.
