# Plan Template

Use this structure for story-cycle Phase 1e plans. The two-section split (Specification vs Implementation) prevents premature technical decisions and improves plan review quality.

## Workflow State Frontmatter

When saving plans to `docs/plans/`, include YAML frontmatter for workflow state persistence. Update `phase` and `stepsCompleted` at each phase transition to enable mid-workflow resume:

```yaml
---
workflow: story-cycle
storyType: feature
phase: plan-approved
stepsCompleted: [0-intent, 1a-type, 1b-discovery, 1c-research, 1d-skills, 1e-plan]
planApproved: false
lastUpdated: 2026-02-23
remaining_steps:
  - "Phase 2.5 — CONFIDENCE GATE (HARD-GATE): Read .claude/prompts/confidence-gate.md. Score 5 dimensions 0-20 each. ≥85 proceed, 70-84 clarify, <70 return to planning."
  - "Phase 3 — IMPLEMENT: Read references/story-types.md for [storyType]. Load CODING_STANDARDS.md + TESTING_STRATEGY.md. Re-read target files. Follow TDD."
  - "Phase 3 — UPDATE STATE: Update .failure-state.md with phase: 3."
  - "Phase 3.5 — SELF-REVIEW (HARD-GATE): Read references/self-review.md + references/disaster-prevention.md. Fix issues before proceeding."
  - "Phase 3.5 — PHASE COMPLETION TRACKER: Output completion table for phases 0-3.5."
  - "Phase 4 — QUALITY GATES: Run lint → typecheck → test in order."
  - "Phase 4 — DOCS: Update docs/progress.md. Update other docs if AC requires."
  - "Phase 4 — UAT (optional): Generate + sense check if Feature/Bug Fix with visible behavior."
  - "Phase 4 — LEARNINGS (optional): Save to docs/solutions/ if non-obvious patterns."
  - "Phase 4 — COMMIT: Conventional format. Do NOT merge or create PR."
  - "Phase 4.5 — COMPLETION VERIFICATION (HARD-GATE): Evidence for EACH AC. Max 2 loops."
  - "COMPLETION REPORT + DELETE .failure-state.md"
error_recovery: ".claude/skills/story-cycle/references/error-recovery.md"
skill_file: ".claude/skills/story-cycle/SKILL.md"
---
```

When `/continue` or story-cycle is re-invoked, check `docs/plans/` for an existing plan with this frontmatter. If found with `planApproved: true`, offer to resume from the last completed step. The `remaining_steps` field is the authoritative execution checklist — for full details on any step, read the `skill_file`.

## Plan Structure

```markdown
## Specification (WHAT/WHY)

**Story:** [user-facing title — NO technical terms]
**Type:** [story type from Phase 1a]

**User-visible behavior changes:**
- [Describe from user perspective — what changes they will see/experience]

**Acceptance Criteria:**
1. **Given** [state], **When** [action], **Then** [outcome]
2. **Given** [state], **When** [action], **Then** [outcome]
3. ...

**Non-goals:** [explicitly out of scope — prevents scope creep during execution]

## Implementation Approach (HOW)

**Files to modify/create:**
- `path/to/file` — [what changes and why]

**Testing strategy:** [test type, location, approach — from test_strategy_selection tool]

**Skills to load:** [/code-quality, /test-validator, etc.]

**Technical approach:**
[Strategy with rationale — reference CODING_STANDARDS.md patterns]

## Architectural Violations (if any)

| Principle Violated | Why Needed | Rejected Alternative |
|-------------------|------------|---------------------|
| [from GROUND_RULES.md] | [justification] | [what was considered and rejected] |
```

## Anti-Patterns

- **Specification section mentions file paths** — move to Implementation
- **Implementation section lacks traceability** — every acceptance criterion should map to a file change
- **No non-goals stated** — always list at least one to anchor scope
- **Acceptance criteria use technical language** — rewrite from user perspective
