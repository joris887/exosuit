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
6. For each deliverable: is the user's intent unambiguous? If multiple valid interpretations exist, mark with `[NEEDS CLARIFICATION: specific question]`

**Output:** Numbered scope list with types, complexity ratings, dependency arrows, and any `[NEEDS CLARIFICATION]` markers.

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
1. Identify all modules/layers the change touches (read ARCHITECTURE.md Module Map if available)
2. For each touched module: what is its documented responsibility?
3. Does the proposed change stay within those responsibilities, or does it extend them?
4. Check Dependency Rules: will the change violate any MUST/NEVER rules in the Module Map?
5. Check import direction: will new imports flow in the documented dependency direction?
6. Identify any new cross-module dependencies the change introduces
7. Check Known Landmines: does the change touch any documented gotchas?
8. If responsibilities are extended, rules violated, or new dependencies cross layer boundaries: flag for ADR consideration

**Output:** Module impact list with dependency direction assessment, rule compliance check, landmine warnings, and boundary violation flags.

---

## Tool: ambiguity_scan

**Apply when:** story-cycle Phase 1f (Clarification Check), after the plan draft and before the approval gate.

Steps:
1. Scan the plan for assumptions across these seven categories:
   - **Scope & Behavior** — Are all user-visible behaviors explicit?
   - **Data Model** — Are entity relationships and validation rules clear?
   - **UX Flow** — Are interaction patterns specified or assumed?
   - **Non-Functional** — Are performance/security/accessibility requirements stated?
   - **Integration** — Are external dependency behaviors documented?
   - **Edge Cases** — Are failure modes and boundary conditions covered?
   - **Constraints** — Are technical limitations acknowledged?
2. For each assumption found, generate a focused question with 2-4 discrete answer options
3. Rank questions by impact: scope > security > UX > technical
4. Present top 3-5 highest-impact questions to user

**Output:** Numbered question list (max 5) ranked by impact, each with answer options. If zero assumptions found, output "No ambiguity detected — plan is ready for approval."

---

## Tool: plan_completeness

**Apply when:** story-cycle Phase 1g, before presenting the plan for approval.

Steps:
1. Re-read the original user request and Phase 0 scope list
2. For each deliverable in the scope: does the plan include implementation steps?
3. For each acceptance criterion: does the plan include a verification approach?
4. Are non-goals explicitly stated? (prevents scope creep during execution)
5. Is the testing strategy explicit? (which tests, where, what approach)
6. Does the plan fit under 50 lines? If not, trim detail — reference files by path instead of inlining
7. Verify the Specification section contains zero implementation details (no file paths, no function names, no framework references)
8. Verify the Implementation Approach section traces back to every acceptance criterion in the Specification section

**Output:** Completeness checklist (all items checked) or list of gaps to address.

---

## Tool: risk_classification

**Apply when:** story-cycle Phase 0, after size classification (trivial/small/standard). Adds a risk dimension to calibrate workflow depth.

Steps:
1. Score each risk factor (1=Low, 2=Medium, 3=High):
   - **Domain risk:** UI/docs/config (1) | Business logic/data processing (2) | Auth/payments/security/data migration (3)
   - **Integration surface:** Isolated single file (1) | Same module, 2-3 files (2) | Cross-module, shared interfaces (3)
   - **Reversibility:** Easily reverted (1) | Requires data migration or API versioning (2) | Irreversible (schema change, published API) (3)
2. Sum the scores (range 3-9)
3. Classify: Low (3-4), Medium (5-6), High (7-9)
4. Adjust workflow depth based on size × risk matrix:
   - TRIVIAL + High risk → reclassify as SMALL
   - SMALL + High risk → use standard workflow + mandatory security-audit
   - STANDARD + High risk → standard + all quality agents + architecture-check
   - Any size + Low risk → use the size-based workflow as-is

**Output:** Risk score with factor breakdown and any workflow depth adjustments.

---

## Tool: depth_exploration

**Apply when:** story-cycle Phase 1 when user selects [D] at the depth check, or when `ambiguity_scan` produces ≥3 questions.

Steps:
1. Identify areas in the plan with complexity ≥4 or `[NEEDS CLARIFICATION]` markers
2. For each uncertain area: generate 2-3 alternative approaches with tradeoff analysis
3. Select the most relevant elicitation technique from `references/elicitation-techniques.md` for the type of uncertainty
4. Apply the technique — ask focused questions, gather user input
5. Integrate selected approach and answers into the plan
6. Remove resolved `[NEEDS CLARIFICATION]` markers

**Output:** Updated plan sections with selected approaches, rationale, and resolved uncertainties.
