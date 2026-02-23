Pre-implementation confidence assessment. Run this AFTER plan approval and BEFORE writing any implementation code.

## Confidence Dimensions

Score each dimension 0–20. Sum for total confidence (0–100).

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

### 3. Existing Pattern Match (0–20)

- Implementation follows patterns found in the codebase during Phase 1c research?
- Naming conventions match existing code in the same module?
- Error handling follows established project patterns?
- No novel abstractions where existing patterns would work?

### 4. Test Strategy Clear (0–20)

- Specific tests identified for each acceptance criterion?
- Test type mapped (unit/integration/E2E) per criterion?
- Testing order defined (simple → edge → error)?
- Existing test patterns in the area understood?

### 5. Dependencies Verified (0–20)

- All APIs, libraries, and integrations confirmed to exist?
- Version compatibility checked for any new dependencies?
- No phantom packages (verified against registry if new)?
- Internal module interfaces confirmed (function signatures, types)?

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
