Pre-implementation readiness check. Run AFTER plan approval and BEFORE writing any implementation code.

## Objective Pre-Conditions

Verify each check as PASS or FAIL with specific evidence. All 5 must pass to proceed. Failed checks require addressing the specific gap — not a generic retry.

### 1. Files Read (have I examined what I plan to change?)

- Compare the plan's list of files to modify against files actually read this session
- Every file the plan touches MUST have been read (at least the relevant sections)
- PASS: all planned files read. FAIL: list which planned files have NOT been read

### 2. Tests Baseline (do existing tests pass?)

- If a test command is configured in CLAUDE.md, it must have been run this session with passing output
- If no test command is configured, PASS by default (no baseline to verify)
- PASS: test output shows green/passing in current session. FAIL: tests not run, or tests failing

### 3. Pattern Match (am I following existing conventions?)

- The plan must reference at least one existing file as a pattern source ("following the pattern in src/auth/middleware.ts")
- If `docs/brain/system-patterns.md` is populated: the plan's "patterns to follow" section should align with documented patterns. New patterns must be noted as intentional.
- For new projects with no existing code, PASS by default
- PASS: plan cites existing code as pattern, and aligns with system-patterns.md (if populated). FAIL: plan introduces patterns without referencing existing ones or contradicts documented patterns without justification

### 4. Scope Bounded (is the change appropriately sized?)

- Count files the plan will create or modify
- ≤5 files: PASS
- 6-10 files: PASS with advisory ("larger change — consider splitting if possible")
- >10 files: FAIL — requires explicit user approval before proceeding

### 5. No Conflicts (does the plan respect project rules?)

- If `docs/reference/GROUND_RULES.md` exists: verify no MUST rule violations in the plan
- If `docs/adr/` has ADR files: verify no contradictions with recorded architectural decisions
- If neither exists: PASS by default
- PASS: zero conflicts found. FAIL: list specific rule/ADR conflicts

## Story-Type Adjustments

- **TRIVIAL stories:** Skip this gate entirely (fast-track)
- **Spike / Research stories:** Check 1 (Files Read) becomes "Have I identified where to look?" and Check 2 (Tests Baseline) is skipped
- **Documentation stories:** Check 2 (Tests Baseline) is skipped

## Overrides

The user can override a failed check by acknowledging the specific gap. The gate is a speed bump, not a wall. When overridden, note which checks were overridden and why in the plan.

## Output Format

```
Readiness Gate:
  [✓] Files read: 4/4 planned files examined
  [✓] Tests baseline: 23 passing (from test run at turn 12)
  [✓] Pattern match: following pattern in src/auth/middleware.ts
  [✗] Scope bounded: plan touches 8 files — larger change, consider splitting
  [✓] No conflicts: 0 ground rule violations

Decision: 4/5 pass — proceed (scope advisory noted)
```
