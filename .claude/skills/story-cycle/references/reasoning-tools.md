# Reasoning Tools

Structured thinking scaffolds for critical decision points. Each tool is a compact sequence of steps that scaffolds reasoning at moments where unstructured thinking leads to shortcuts or errors.

**Usage:** When a skill phase says "Apply the `tool_name` reasoning tool", follow the steps in order and produce the output format before proceeding.

---

## Tool: scope_analysis

**Apply when:** story-cycle Phase 0 (Intent Decomposition), or any compound user request.

Steps:
1. List ALL explicit deliverables in the user's request (implementation, tests, docs, config, PR, etc.)
2. For each deliverable: identify type (feature/bug/refactor/infra), files likely affected, estimated complexity (1-5)
3. Identify dependencies between deliverables (which must complete before others can start)
4. Flag any deliverable rated complexity ≥4 as candidate for splitting into its own story
5. Check: are there implicit deliverables not stated but expected? (e.g., "add endpoint" implies tests)

**Output:** Numbered scope list with types, complexity ratings, and dependency arrows.

---

## Tool: test_strategy_selection

**Apply when:** story-cycle Phase 3, before writing the first test.

Steps:
1. Classify the change: new behavior / changed behavior / preserved behavior
2. For **new behavior**: identify inputs, outputs, edge cases, error paths
3. For **changed behavior**: identify what was true before, what should be true after, what should remain unchanged
4. For **preserved behavior**: identify invariants that must hold through the refactoring
5. Select test type per case: unit (isolated logic), integration (component boundaries), E2E (user flow)
6. Order tests: start with the simplest happy path, then edge cases, then error paths

**Output:** Ordered test list with type, description, and key assertion sketch.

---

## Tool: failure_diagnosis

**Apply when:** debug-session Phase 1, or any unexpected test failure during story-cycle Phase 3.

Steps:
1. Read the FULL error output — every line, including stack trace and surrounding context
2. Identify: what was expected vs. what actually happened
3. Trace backward: which function produced the wrong result? What were its inputs?
4. If inputs are correct: the bug is in this function — inspect its logic
5. If inputs are wrong: trace one level further back — where do those inputs come from?
6. Repeat until you find the point where correct data becomes incorrect

**Output:** "Root cause is [X] at [file:line] because [evidence from trace]."

---

## Tool: architectural_impact

**Apply when:** architecture-check, or story-cycle Phase 1 for stories touching multiple modules.

Steps:
1. Identify all modules/layers the change touches (read ARCHITECTURE.md if available)
2. For each touched module: what is its documented responsibility?
3. Does the proposed change stay within those responsibilities, or does it extend them?
4. Check import direction: will new imports flow in the documented dependency direction?
5. Identify any new cross-module dependencies the change introduces
6. If responsibilities are extended or new dependencies cross layer boundaries: flag for ADR consideration

**Output:** Module impact list with dependency direction assessment and boundary violation flags.

---

## Tool: plan_completeness

**Apply when:** story-cycle Phase 1e, before presenting the plan for approval.

Steps:
1. Re-read the original user request and Phase 0 scope list
2. For each deliverable in the scope: does the plan include implementation steps?
3. For each acceptance criterion: does the plan include a verification approach?
4. Are non-goals explicitly stated? (prevents scope creep during execution)
5. Is the testing strategy explicit? (which tests, where, what approach)
6. Does the plan fit under 50 lines? If not, trim detail — reference files by path instead of inlining

**Output:** Completeness checklist (all items checked) or list of gaps to address.
