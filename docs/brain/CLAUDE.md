# Repo Brain

The LLM-maintained, persistent source of truth about this repository's technical and product state. The brain is the artifact every other skill reads from and writes to. It is **not** the codebase — the code remains authoritative — but the brain is the structured projection of the codebase that other skills can consult without re-deriving it every session.

## Pages

| Page | What It Holds | Stable / Volatile |
|------|---------------|-------------------|
| `index.md` | Catalog of every brain page with one-line summary + last-updated date. Read first when navigating. | Volatile — refreshed on every brain update |
| `log.md` | Append-only chronological record of brain updates. Each entry starts `## [YYYY-MM-DD HH:MM] <skill> <event> \| <subject>`. Grep this for "what changed and when". | Append-only |
| `current-state.md` | What is working now, what is in progress, what changed in recent stories. Derived from git log + activity log. | Volatile — re-derived on update |
| `project-overview.md` | Mission, users, scope. Rarely changes. | Stable |
| `product-context.md` | Domain terms, feature areas, NFRs. | Stable, slow drift |
| `personas.md` | User personas in lean 6-field format. Drives `/ideate`, `/story-cycle`, `/manual-test`. | Stable |
| `project-structure.md` | Directory layout, module duties, file conventions. | Stable, drifts with refactoring |
| `tech-context.md` | Stack, dependencies, APIs, integration points. | Stable, drifts with deps changes |
| `system-patterns.md` | Implementation patterns, conventions, recipes for adding common things. | Stable — this is where compounding value lives |
| `error-patterns.md` | Past mistakes, root causes, prevention rules. Append-only across stories. | Append-only |

## How the Brain Stays Accurate

Every claim in a brain page that asserts a technical fact (a class exists, a function does X, a route lives at path Y) **must cite a file:line or commit hash**. Claims without citations are flagged `[Assumed]` and must be re-verified or removed at next brain-update.

The `/brain-update` skill is the only writer. It is called by:

| Caller | When | What it captures |
|--------|------|------------------|
| `/story-cycle` Phase 4 | After capture-learnings, before commit | What shipped, what patterns changed, what file:lines moved |
| `/sprint-end` Step 3 | After tests pass, before PR | Sprint outcomes, architectural changes, NFR impacts |
| `/brainstorm` Step 6 | When status becomes `decided` | Design decisions, rejected alternatives, scoring rationale |
| `/ideate` Step 7 | After backlog write | Outcome-level intent for the new stories |
| `/discover` Phase 7D | After vision synthesis | Seed the brain from discovery decisions |

Casual conversation that uncovers important state should ask the user "should I update the brain with this?" — and only update when confirmed.

## How to Read the Brain

When a skill needs project context, it should:

1. Read `index.md` first to find the relevant pages.
2. Read those pages — but only the sections relevant to the current task.
3. Trust the citations: if a claim links to `src/auth/login.ts:42`, that's the source. If it conflicts with current code, the brain is stale — surface the discrepancy and trigger a `/brain-update`.

Skills that read the brain heavily: `/story-cycle` (via context-prime), `/sprint-start` (re-refinement), `/brainstorm` (pattern fit scoring), `/ideate` (NFR derivation).

## Update Protocol

Brain updates must:

1. Lead with a `log.md` entry — append, never edit prior entries.
2. Edit the affected page(s) inline. If a claim changes, replace it; don't accumulate contradictions.
3. Cite every new technical claim with `file:line` or `commit:<hash>`.
4. Refresh `index.md` last-updated dates for any touched page.
5. Refresh `current-state.md` "Recent changes" section.

Refuse to write an entry that lacks a citation or that's purely conversational (no concrete state change). Casual chat does not belong in the brain.

## Conventions

- One claim per bullet. No essay paragraphs.
- Use positive formulation ("uses X" not "doesn't use Y" except in non-goals).
- file:line citations use the format `src/path/to/file.ts:42` — no markdown link.
- Dates in `log.md` use ISO 8601 with minute precision.
- When in doubt, **the codebase wins**. The brain is a projection, not the source.
