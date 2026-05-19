---
name: brain-update
version: 1.0.0
description: Distill recent conversation into brain page edits with file:line citations + a log entry. Plumbing for other skills, not user-invocable.
trigger: auto
depends-on: []
references: [references/brain-update-protocol.md]
disable-model-invocation: true
user-invocable: false
allowed-tools: Read, Glob, Grep, Edit, Write, Bash
argument-hint: "<caller-skill> <event-type> [subject]"
---
______________________________________________________________________

## brain-update

**Plumbing skill.** Called by `/story-cycle`, `/sprint-end`, `/brainstorm`, `/ideate`, `/discover`. Distills the relevant slice of conversation into edits on `docs/brain/` with file:line citations, plus one new entry in `docs/brain/log.md`.

**Skill metrics:** Emit a start event:
```bash
echo "{\"type\":\"skill\",\"event\":\"brain-update\",\"caller\":\"$1\",\"event_type\":\"$2\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl
```

## Inputs

- `$1` — caller skill name (`story-cycle`, `sprint-end`, `brainstorm`, `ideate`, `discover`)
- `$2` — event type (`done`, `shipped`, `decided`, `stories-added`, `seeded`)
- `$3` — subject (story id, sprint number, brainstorm topic, epic id, phase name)

## Pre-flight

Verify `docs/brain/` exists. If not, abort silently — the project hasn't been bootstrapped yet and the brain isn't applicable.

```bash
[ -d docs/brain ] || { echo "brain-update: docs/brain not found, skipping"; exit 0; }
```

## Step 1: Collect Change Candidates

Pull from the active session, scoped to the caller's event:

| Caller | What to collect |
|--------|----------------|
| `story-cycle done` | The story's outcome + Acceptance Criteria, what files were edited (run `git diff --stat HEAD~1..HEAD` or use the story's tracked file list), and any new patterns/recipes that emerged. Also any new error-pattern recorded via `record-failure`. |
| `sprint-end shipped` | Sprint goal, list of stories shipped this sprint (from progress.md sprint section), aggregate file:line evidence from the sprint's commits. |
| `brainstorm decided` | Final design decision, rejected alternatives with reasons, the path to the brainstorm doc in `docs/brainstorms/`. |
| `ideate stories-added` | Epic id + the outcomes (not implementation hints) of the new stories. This seeds intent into `current-state.md` "What's coming". |
| `discover seeded` | Already handled in `/discover` Phase 7D — this caller just appends the log entry. |

## Step 2: Decide Which Pages to Touch

Apply this routing table. Touch only what's affected — never blanket-update all pages.

| Signal | Page to edit |
|--------|--------------|
| New persistent pattern (e.g. "all auth now goes through `middleware/auth.ts`") | `system-patterns.md` |
| Dependency added/removed/upgraded, API surface changed | `tech-context.md` |
| Directory layout shift, new top-level module | `project-structure.md` |
| User-observable feature shipped or removed | `product-context.md` + `current-state.md` |
| Misdiagnosis or rework recorded | `error-patterns.md` (append-only) |
| New persona discovered or persona role shift | `personas.md` |
| Outcome-level intent for upcoming work | `current-state.md` (What's In Progress / What's Coming) |
| Architectural constraint discovered (load-bearing invariant) | `system-patterns.md` + `current-state.md` (Architectural Constraints) |

If no signal fires, **do not write** — there's nothing to capture. Skip to Step 5 to append a log entry noting the no-op.

## Step 3: Apply Edits

For each page touched:

1. Re-read the current page (don't trust stale context).
2. Replace stale claims in place — never accumulate contradictions.
3. **Every new technical claim must carry a `file:line` citation.** If you cannot cite, do not write — surface a request for the user to confirm.
4. Update the page's YAML frontmatter `updated:` field to today's date.

**Refusal cases** (do not write the entry, log a `refused` event instead):
- A technical claim has no file:line or commit citation.
- The change is purely conversational ("we discussed X") with no concrete state delta.
- The same claim is already in the brain with a fresher date.

## Step 4: Refresh Volatile Pages

- `current-state.md` "What Works Now" — add or amend the bullet for what just shipped, with citation.
- `current-state.md` "What Changed Recently" — prepend a one-line entry with date + commit hash if available.
- `current-state.md` "Architectural Constraints" — only update if a new load-bearing constraint emerged.

- `index.md` Pages tables — update last-updated dates for any touched page.
- `index.md` Coverage — adjust if a previously-uncovered area now has a brain page entry.
- `index.md` Gaps — remove entries that this update closed.

## Step 5: Append Log Entry

Append (never edit prior entries) to `docs/brain/log.md`:

```markdown
## [YYYY-MM-DD HH:MM] <caller> <event-type> | <subject>
- **Pages touched:** <page1.md>, <page2.md>
- **Citations:** <file:line>, <file:line>, <commit:hash>
- **Summary:** One sentence describing the change.
```

For a no-op (Step 2 found nothing to capture):

```markdown
## [YYYY-MM-DD HH:MM] <caller> <event-type> | <subject>
- **No-op:** No persistent state change detected.
```

For a refusal:

```markdown
## [YYYY-MM-DD HH:MM] <caller> <event-type> | <subject>
- **Refused:** <reason — e.g. "claim 'auth now stateless' had no file:line citation">
```

## Step 6: Emit Completion Event

```bash
echo "{\"type\":\"skill\",\"event\":\"brain-update-done\",\"caller\":\"$1\",\"pages_touched\":N,\"result\":\"<wrote|noop|refused>\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl
```

## What This Skill Does NOT Do

- Does not ask the user questions — runs silently as plumbing.
- Does not read the entire codebase — uses only what's already in context from the caller skill.
- Does not run agents — fast, deterministic, ≤ 30 seconds.
- Does not edit code — only `docs/brain/` markdown files.
- Does not refresh stable pages just because they exist — only on actual state change.

## Rules

- **One log entry per call.** Even no-ops and refusals get a log entry — the absence of an entry would itself be a state mystery.
- **No file:line, no write.** This is the load-bearing rule. Drift in the brain is worse than gaps in the brain.
- **Newest first** in `current-state.md` "What Changed Recently"; oldest stays. Trim entries older than 30 days when adding new ones if the section exceeds 20 entries.
- See `references/brain-update-protocol.md` for the citation format, page routing details, and examples.
