Pre-implementation confidence assessment. Run this AFTER plan approval and BEFORE writing any implementation code.

## Confidence Dimensions

Score each dimension 0–20. Sum for total confidence (0–100).

### Story-Type Adjustments for Dimension 4

Dimension 4 adapts based on story type. The scoring weight (0–20) stays the same — only the criteria change:

- **Spike / Research stories:** Score based on "exploration strategy clear" — score 20 if the spike has clear questions to answer, defined information sources, and a time-box.
- **Documentation stories:** Score based on "review strategy clear" — score 20 if there is a clear plan for verifying accuracy (e.g., subject-matter review, cross-referencing sources, testing code examples).
- **Infrastructure stories:** Score based on "smoke test / verification strategy clear" — score 20 if there is a defined way to verify the infrastructure change works (health check, deployment test, rollback verification) even without full TDD coverage.
- **All other story types (feature, bug fix, refactoring):** Dimension 4 remains as defined below — full test strategy.

### 1. No Ambiguity Remaining (0–20)

- All Phase 1f clarification questions answered?
- No `[NEEDS CLARIFICATION]` markers remaining in the plan?
- No implicit assumptions stated as "Assuming X..."?
- All acceptance criteria are concrete and testable?

### 2. Architecture Compliance (0–20)

- Plan respects all MUST rules in `docs/reference/GROUND_RULES.md` (if exists)?
- No cross-layer violations identified?
- Dependency direction is correct (no circular imports introduced)?
- Module boundaries respected per `docs/architecture/ARCHITECTURE.md`?
- Plan respects Dependency Rules (MUST/NEVER statements) in the Module Map section?
- If the story touches modules listed in Known Landmines: does the plan account for the documented gotchas?

> **Note:** If `docs/reference/GROUND_RULES.md` and `docs/architecture/ARCHITECTURE.md` do not exist (e.g., new project without bootstrap), score based on general best practices. Do NOT penalize for missing docs that haven't been created yet.

### 3. Existing Pattern Match (0–20)

- Implementation follows patterns found in the codebase during Phase 1c research?
- Naming conventions match existing code in the same module?
- Error handling follows established project patterns?
- No novel abstractions where existing patterns would work?

### 4. Test Strategy Clear (0–20)

- Specific tests identified for each acceptance criterion?
- Test type mapped (unit/integration/E2E/property-based) per criterion?
- Expected values are hardcoded from specifications (not computed from production logic)?
- Negative/error tests planned proportional to happy-path tests?
- For critical business logic: property-based testing or integration tests included?
- Testing order defined (simple → edge → error)?

### 5. Dependencies Verified (0–20)

- All APIs, libraries, and integrations confirmed to exist?
- Version compatibility checked for any new dependencies?
- No phantom packages (verified against registry if new)?
- Internal module interfaces confirmed (function signatures, types)?

## Risk Awareness (not scored — advisory)

This is NOT a 6th dimension. The score remains 0–100 across the 5 dimensions above. However, before proceeding, consider:

- Do you understand the **blast radius** of this change? (Which users, services, or systems are affected?)
- Is there a **rollback plan** if this doesn't work? (Checkpoint tag, feature flag, reversible migration?)

**Security-relevant stories** (touching auth, crypto, user data, API endpoints, file uploads, sessions): AI-generated code in these areas has the highest vulnerability rate. Before proceeding, verify:
- Are you using established libraries for auth/crypto (not generating from scratch)?
- Have you checked the CWE top 15 from `.claude/rules/security.md` against the plan?
- Are all AI-suggested dependencies verified to exist in their registry?

If the answer to any question is unclear, flag to the user before proceeding — even if the total score is >=85.

## Scoring Thresholds

| Score | Action |
|-------|--------|
| **85–100** | Proceed to Phase 3 implementation |
| **70–84** | Flag low-scoring dimensions. Ask user for clarification on gaps before proceeding |
| **< 70** | Hard-stop. Return to Phase 1 for additional research on the weakest dimensions |

## Output Format

```
Confidence: [total]/100
  Ambiguity:    [score]/20 — [brief justification]
  Architecture: [score]/20 — [brief justification]
  Patterns:     [score]/20 — [brief justification]
  Test Strategy:[score]/20 — [brief justification]
  Dependencies: [score]/20 — [brief justification]

Decision: [PROCEED / CLARIFY: dimensions X, Y / STOP: return to Phase 1]
```
