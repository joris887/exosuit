# Brain Update Protocol

Detailed rules for the `/brain-update` skill. Read this when the SKILL.md decision tree doesn't cover a case.

## Citation Format

Every new technical claim in a brain page must end with a citation. Acceptable forms:

- `src/path/to/file.ts:42` — single line
- `src/path/to/file.ts:42-58` — range
- `commit:abc1234` — when the claim is "this changed in commit X" but the resulting file:line isn't a single anchor
- `docs/brainstorms/topic.md` — when the claim originates from a recorded design decision
- `DECISION_LOG:D05` — when the claim originates from a tracked decision

Forbidden:
- `<file>` — descriptive but unsearchable
- "the auth module" — descriptive prose
- "earlier in the codebase" — vague
- No citation at all

## Page Routing — Examples

| Conversation signal | Routing decision | Reason |
|---------------------|------------------|--------|
| "We switched the password hash from bcrypt to argon2id" | `tech-context.md` + `current-state.md` | Stack changed |
| "All new endpoints now use the Zod validator pattern" | `system-patterns.md` | Convention enshrined |
| "We discovered the worker pool blocks on DB connections" | `error-patterns.md` + `system-patterns.md` (preventive note) | Mistake + prevention |
| "Marcus (power user) prefers keyboard-only navigation" | `personas.md` | Persona refinement |
| "Sprint 12 shipped OAuth login" | `current-state.md` ("What Works Now") | Feature shipped |
| "Sprint 12 was hard, we burned out" | (do not write) | Not persistent state |
| "We considered Redis but stuck with PostgreSQL" | `system-patterns.md` (rejected alternative) + cite `docs/brainstorms/storage.md` | Decision worth preserving |

## What Counts as a "Persistent State Change"

YES (write):
- A pattern is now mandatory or now banned.
- An external API contract changed.
- A file moved, a module renamed, a layer split.
- A new error pattern was learned (with prevention).
- A persona profile changed.
- A user-observable feature shipped or was removed.

NO (do not write):
- We discussed an option but didn't decide.
- A test was added (covered by AC coverage check, not brain-worthy unless it reveals a pattern).
- Implementation detail at function granularity (single function refactored without cross-file impact).
- Sprint emotional state.

## When to Trim

`current-state.md` "What Changed Recently" should not become an essay. When appending a new entry and the section exceeds 20 entries, remove entries older than 30 days. The git log is the durable record; this section is a short-window view.

`log.md` is never trimmed. If it grows unwieldy, suggest archiving the older half to `docs/brain/log-archive-<year>.md` during `/weekly-maintenance`.

## Failure Modes

| Failure | Action |
|---------|--------|
| Caller passed an unknown event type | Append a refused log entry, exit 0 |
| `docs/brain/` doesn't exist | Exit 0 silently (pre-bootstrap project) |
| Multiple pages need editing but one fails | Roll back the partial write, append a refused log entry with the reason |
| The claim being written conflicts with a brain claim from the same day | Surface to user — "today the brain says X, you're proposing Y, which is correct?" |
| The activity log file doesn't exist | Create it with the standard JSON-Lines header and proceed |

## Examples (Full Entries)

**Story-cycle done, feature shipped:**

```markdown
## [2026-05-19 14:32] story-cycle done | E03-S04 OAuth login
- **Pages touched:** system-patterns.md, tech-context.md, current-state.md, index.md
- **Citations:** src/auth/oauth.ts:1-120, src/middleware/auth.ts:18, package.json:34 (added passport)
- **Summary:** Added OAuth provider abstraction with recipe; passport added as dep; current-state lists OAuth login as working.
```

**Brainstorm decided:**

```markdown
## [2026-05-12 09:10] brainstorm decided | session storage strategy
- **Pages touched:** system-patterns.md
- **Citations:** docs/brainstorms/session-storage.md, DECISION_LOG:D07
- **Summary:** Chose Redis with httpOnly cookies; rejected JWT-in-localstorage (XSS risk per brainstorm). Recipe for adding new session-bound features documented.
```

**Sprint-end no-op:**

```markdown
## [2026-05-22 18:00] sprint-end shipped | sprint-13
- **No-op:** Sprint shipped 4 bug fixes — none introduced or removed patterns. error-patterns.md updated by individual story-cycle calls.
```

**Refusal:**

```markdown
## [2026-05-19 15:01] story-cycle done | E03-S05 caching
- **Refused:** Claim "redis caching now active globally" had no file:line citation. Requested clarification: which middleware enables it?
```
