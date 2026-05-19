---
purpose: Snapshot of what's working now, what's in progress, what changed recently. Re-derived on every /brain-update.
updated: <!-- filled by /brain-update -->
---

# Current State

> A snapshot, not an essay. Bulleted facts with file:line citations. Re-derived from git log + activity log + the brain's stable pages on every `/brain-update`.

## What Works Now

> User-observable outcomes that are shipped and verified. Each bullet: one outcome + one citation.

<!-- - Users can sign in with email/password (src/auth/password.ts:1-80, tested in src/auth/password.test.ts) -->

## What's In Progress

> Active sprint stories. Updated by `/sprint-start` and `/story-cycle`.

<!-- - E03-S04: OAuth login (sprint-12, in-progress, see docs/reference/backlog/E03.md#S04) -->

## What Changed Recently

> Last 10 commits + sprint outcomes. Updated on every /brain-update. Use for "what's the diff vs last time I touched this."

<!-- - 2026-05-19: Added OAuth provider abstraction (commit abc1234) -->

## Architectural Constraints

> Pulled forward from system-patterns.md when active. Use this when planning to know what's load-bearing.

<!-- - All data access goes through src/repositories/ (system-patterns.md:14) -->

## Known Discrepancies

> Brain claims that may be stale, pending re-verification. /brain-update flags these.

<!-- - [Assumed] system-patterns.md says "auth uses JWT" but src/auth/oauth.ts:1 imports session middleware — needs verification -->
