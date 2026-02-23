# Plan Template

Use this structure for story-cycle Phase 1e plans. The two-section split (Specification vs Implementation) prevents premature technical decisions and improves plan review quality.

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
