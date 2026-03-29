# Phase 0: Intent Decomposition

Reference loaded by `/story-cycle` Phase 0. Decomposes user intent before planning.

Run the `context-prime` micro-component from `.claude/prompts/context-prime.md` to load project context (intent-aware ordering based on the story description).

### 0a. Backlog Story Lookup

If `$ARGUMENTS` matches a story ID pattern (e.g., `PROJ-001`, `S01`, `E01-S03`), search `docs/reference/backlog/E*.md` for the story:

1. Find the story in the epic checklist: `- [ ] ID — Title (Priority, Status)`
2. Find the detailed story section: `### ID: Title` with inline metadata
3. Extract metadata: **Type**, **Size**, **Priority**, **Status**, **Dependencies**, **Affected files**, **Acceptance criteria**, **Verification commands**
4. Use extracted type/size/priority as starting classification (validated in the Size & Risk Classification step)

**Definition of Ready check:** If the story has `status: draft` or is missing verification commands, affected files, or out-of-scope section, warn the user:
> "This story doesn't meet the Definition of Ready. Missing: [list]. Consider running `/ideate` to refine it, or proceed with caution."

**Dependency check:** If the story has dependencies listed, verify each dependency story has status `done` in its epic file. If any dependency is not done, warn:
> "Dependency [ID] is not complete (status: [status]). This story may be blocked."

**Status update:** Set the story's status to `in-progress` in the epic file (both checklist and detail section). Emit a story lifecycle event:
```bash
echo "{\"type\":\"story\",\"event\":\"status-change\",\"id\":\"<story-id>\",\"from\":\"<previous>\",\"to\":\"in-progress\",\"story_type\":\"<type>\",\"size\":\"<size>\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl
```

### 0a.5. Sprint Context Load

If on a sprint branch (branch name matches `sprint-*`), load the sprint spec for decision context:

1. Find `docs/sprints/sprint-<number>.md` (derive number from branch name)
2. Extract and hold in context:
   - **Sprint goal** — the primary decision-making context for this story. When implementation choices are ambiguous, the sprint goal breaks the tie.
   - **Boundaries** — out-of-scope items. If this story drifts toward an out-of-scope area, flag it.
   - **Remaining capacity** — count stories by status and size (S=1, M=2, L=4 sessions). Compare against total available sessions to determine sprint health.
   - **Decisions log** — prior decisions in this sprint that may constrain this story's approach.

**Sprint-aware risk modifier:** If the sprint goal explicitly relates to this story's domain (e.g., sprint goal is "auth integration" and story is about auth), note "sprint-aligned" — this story is goal-critical and deserves full depth. If the story is peripheral to the sprint goal (e.g., sprint goal is "auth integration" but story is "update error messages"), note "sprint-peripheral" — keep scope minimal.

**Capacity check:** If remaining stories (🔲 + 🔄) require more sessions than remain in sprint capacity:
> "⚠️ Sprint capacity at risk — [N] stories remaining ([M] sessions needed), [K] sessions available. Consider carrying over the lowest-priority ⏭️ story."

**M/L story session guidance:** If this story is sized M or L, suggest the three-session pattern:
> "This is a [M/L] story (~[2-3/3-5] sessions). Consider: Session 1 = Phase 0-1 (plan + approve), Session 2 = Phase 3 (implement), Session 3 = Phase 4 (verify + commit). Use `/handoff` at natural break points to preserve context."

This is guidance, not enforcement — the developer may complete it in fewer sessions.

### 0b. PRD Scope Guard

If `docs/reference/PRD_SUMMARY.md` exists, load Section 7 (scope boundaries) and Section 3 (success criteria). Use scope boundaries as guard rails throughout implementation — if the story drifts toward a stated non-goal or violates an implementation boundary, flag it. Use success criteria to verify the story contributes to measurable product outcomes.

### 0c. Scope Analysis

Before any exploration, decompose the user's request. Apply the `scope_analysis` reasoning tool from `references/reasoning-tools.md`:

1. List ALL distinct outcomes the user expects (implementation, tests, docs, PR, etc.)
2. For each: identify type, files likely affected, complexity (1-5), and dependencies
3. Flag any deliverable rated complexity ≥4 as candidate for splitting
4. If the request contains multiple independent stories, suggest splitting and confirm scope
5. Confirm the full scope with the user before proceeding to planning

This prevents missing later parts of compound requests (e.g., "refactor auth AND add rate limiting AND create a PR").
