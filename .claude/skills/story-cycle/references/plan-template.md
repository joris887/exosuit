# Plan Template

Use this structure for story-cycle Phase 1e plans. The two-section split (Specification vs Implementation) prevents premature technical decisions and improves plan review quality.

## Workflow State Frontmatter

When saving plans to `docs/plans/`, include YAML frontmatter for workflow state persistence. Update `phase` and `stepsCompleted` at each phase transition to enable mid-workflow resume:

```yaml
---
workflow: story-cycle
storyType: feature
phase: plan-approved
stepsCompleted: [0-intent, 1a-type, 1b-discovery, 1c-research, 1c5-online-verify, 1d-skills, 1d5-discovery-gate, 1d7-refinement, 1e-plan, 1f-clarification, 1g-completeness, 1h-depth-check]
planApproved: false
lastUpdated: 2026-02-23
remaining_steps:
  - "BOOTSTRAP (do this FIRST): Read .claude/skills/story-cycle/SKILL.md starting from '## Phase 2: Context Transition + Confidence Gate' to reload the full story-cycle workflow. You are mid-workflow — planning is done, implementation phases remain. Do NOT stop after reading the plan."
  - "Phase 2 — CONTEXT + CONFIDENCE GATE (HARD-GATE): Prune context (keep plan + paths + gotchas, discard bulk). Read .claude/prompts/confidence-gate.md. Score 5 dimensions 0-20 each. ≥85 proceed, 70-84 clarify, <70 return to planning. Output the score table."
  - "Phase 3 — IMPLEMENT: Read .claude/skills/story-cycle/references/story-types.md for [storyType] execution steps. Load docs/reference/CODING_STANDARDS.md and docs/reference/TESTING_STRATEGY.md. Re-read all target files from plan before editing. Follow story-type methodology (e.g., TDD: RED failing test → GREEN minimal impl → REFACTOR)."
  - "Phase 4a — SELF-REVIEW (HARD-GATE): Read .claude/skills/story-cycle/references/self-review.md — complete ALL checklist items. Read .claude/skills/story-cycle/references/disaster-prevention.md — check for wheel reinvention, spec drift, integration wiring, file structure, regression surface. If ANY item fails → fix in Phase 3 before proceeding."
  - "Phase 4b — QUALITY GATES: Run the project's quality command (from CLAUDE.md Commands section: lint → typecheck → test). Stop on first failure, fix, re-run. Show test output in the current turn — do NOT claim tests pass without evidence."
  - "Phase 4c — UAT (optional, Feature/Bug Fix only): If project has UAT directory, generate UAT test case + sense check per Phase 4c/4c.1 in SKILL.md. Skip for Spike/Research, Infrastructure, Documentation, Testing, Refactoring, Performance, Skill/Tooling stories. Also skip if no UAT directory exists."
  - "Phase 4d — COMPLETION VERIFICATION (HARD-GATE): Re-read original AC from plan. For EACH criterion, provide concrete evidence (test output, file:line, command output). Max 2 extra loop passes if gaps found. Do NOT print completion report until every AC has evidence."
  - "Phase 4e — DOCS + COMMIT: (1) Update epic file (mark story DONE in heading, check all AC boxes). (2) Update BACKLOG_INDEX.md (increment Done, decrement TODO for epic row, update Total row). (3) Update docs/progress.md (current story status, test counts). (4) Update CLAUDE.md if it contains backlog counts or epic progress that changed. (5) Emit skill metrics event to docs/sessions/.activity-log.jsonl. (6) Invoke /commit skill. Do NOT merge or create PR — that is sprint-end."
  - "COMPLETION REPORT: Print story, type, approach, files modified, test counts, commit hash, verification evidence. Include Next Steps (next story / sprint-end / handoff)."
error_recovery: ".claude/skills/story-cycle/references/error-recovery.md"
skill_file: ".claude/skills/story-cycle/SKILL.md"
---
```

When `/continue` or story-cycle is re-invoked, check `docs/plans/` for an existing plan with this frontmatter. If found with `planApproved: true`, offer to resume from the last completed step. The `remaining_steps` field is the authoritative execution checklist — for full details on any step, read the `skill_file`.

**CRITICAL:** The plan approval (ExitPlanMode) is NOT the end of the story-cycle. After Plan Mode exits, execute the `remaining_steps` list in order. The first step (BOOTSTRAP) reloads the skill file to restore full workflow context.

## Plan Structure

```markdown
## Research Decision

**Story type:** [type from Phase 1a]
**Research requirement:** [MANDATORY / Conditional]
**Decision:** [PERFORMED at [QUICK/STANDARD/DEEP] depth / SKIPPED]
**Justification:** [why — for skips: which signals were evaluated and why all pointed to skip]

### Findings (if research was performed)
- [Key finding 1 with source URL]
- [Key finding 2 with source URL]

**Research confidence:** [score]/100
**Impact on plan:** [how findings affect the approach — or "No findings that change approach"]

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

- **Missing Research Decision section** — every plan MUST start with this block (from Phase 1c.5). If absent, the plan is incomplete.
- **Research Decision says "SKIPPED" for Spike/Research/Security/Bug Fix stories** — these types require mandatory research. Go back to Phase 1c.5.
- **Specification section mentions file paths** — move to Implementation
- **Implementation section lacks traceability** — every acceptance criterion should map to a file change
- **No non-goals stated** — always list at least one to anchor scope
- **Acceptance criteria use technical language** — rewrite from user perspective
