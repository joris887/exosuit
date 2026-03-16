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
  - "BOOTSTRAP (do this FIRST): Read .claude/skills/story-cycle/SKILL.md starting from '## Phase 2: Context Transition + Confidence Gate' to reload the full story-cycle workflow. You are mid-workflow — planning is done, implementation phases remain. Do NOT stop after reading the plan."
  - "Phase 2 — CONTEXT + CONFIDENCE GATE (HARD-GATE): Prune context. Score 5 dimensions 0-20 each. ≥85 proceed, 70-84 clarify, <70 return to planning."
  - "Phase 3 — IMPLEMENT: Read references/story-types.md for [storyType]. Load CODING_STANDARDS.md + TESTING_STRATEGY.md. Re-read target files. Follow TDD."
  - "Phase 4a — SELF-REVIEW (HARD-GATE): Read references/self-review.md + references/disaster-prevention.md. Fix issues before proceeding."
  - "Phase 4b — QUALITY GATES: Run the project's quality command (from CLAUDE.md Commands section: lint → typecheck → test). Stop on first failure."
  - "Phase 4c — UAT (optional, Feature/Bug Fix only): Generate UAT test case + sense check if project has UAT directory."
  - "Phase 4d — COMPLETION VERIFICATION (HARD-GATE): Evidence for EACH AC. Max 2 loops."
  - "Phase 4e — DOCS + COMMIT: Update docs/progress.md. Invoke /commit skill. Do NOT merge or create PR."
  - "COMPLETION REPORT"
error_recovery: ".claude/skills/story-cycle/references/error-recovery.md"
skill_file: ".claude/skills/story-cycle/SKILL.md"
---
```

When `/continue` or story-cycle is re-invoked, check `docs/plans/` for an existing plan with this frontmatter. If found with `planApproved: true`, offer to resume from the last completed step. The `remaining_steps` field is the authoritative execution checklist — for full details on any step, read the `skill_file`.

**CRITICAL:** The plan approval (ExitPlanMode) is NOT the end of the story-cycle. After Plan Mode exits, execute the `remaining_steps` list in order. The first step (BOOTSTRAP) reloads the skill file to restore full workflow context.

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
