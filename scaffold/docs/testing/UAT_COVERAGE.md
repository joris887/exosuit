# UAT Coverage

**Last Updated:** <!-- date -->

## Dashboard

| Metric | Value |
|--------|-------|
| Total Test Cases | 0 |
| ✅ Pass | 0 |
| ❌ Fail | 0 |
| ⏭️ Skip | 0 |
| 🚧 Blocked | 0 |
| ⚠️ Partial | 0 |
| ⬜ Untested | 0 |
| 🔍 Sense-Checked | 0 |

<!-- /UAT-cycle and /claude-sense-check update this table automatically -->

## Coverage Gaps

<!-- Stories without test cases — updated by /claude-sense-check -->
<!-- Format: STORY-ID, STORY-ID, ... or "None — all stories covered" -->

______________________________________________________________________

## Test Cases

<!-- Test cases below. Each test case follows the standard format.
     Skills that consume this file:
     - /story-cycle Phase 4c: generates new test cases
     - /UAT-cycle: executes test cases, updates status and results
     - /claude-sense-check: batch-verifies unchecked sense-check boxes
     - /manual-test: reads status to identify coverage gaps
-->

<!-- === TEMPLATE (copy for new test cases) ===

### UAT-001: [Title]

**Priority:** critical | **Type:** positive | **Covers:** [STORY-IDs] | **Tags:** [smoke, regression, ...]

**Setup:**
- [Precondition 1]
- [Precondition 2]

**Given** [initial state or precondition]
**When** [action the user takes]
**Then** [expected observable outcome]
**And** [additional expected outcome, if any]

**Test Data:**
| Input | Value |
|-------|-------|
| [field] | [value] |

**Status:** ⬜ Untested
**Tested On:** —
**Findings:** —

**Claude Sense Check**
- [ ] Logic verified from code perspective
- [ ] Notes:

**Human UAT Check**
- [ ] Tested by user
- [ ] Notes:

#### Results
<!-- Append-only execution log — each run adds a row, never delete -->
| Status | Date | Verified By | Build | Notes |
|--------|------|-------------|-------|-------|
| ⬜ Untested | — | — | — | — |

=== END TEMPLATE === -->

<!-- === EXPLORATORY CHARTER TEMPLATE ===

### UAT-001: [Charter Title]

**Priority:** medium | **Type:** exploratory | **Covers:** [STORY-IDs or feature area] | **Tags:** [exploratory]

**Charter:**
- **Explore:** [area or feature to investigate]
- **With:** [techniques, data, or scenarios to try]
- **To discover:** [what risks, bugs, or behaviors you're looking for]

**Time box:** [30 | 60 | 90 minutes]

**Status:** ⬜ Untested
**Tested On:** —
**Findings:** —

**Claude Sense Check**
- [ ] Logic verified from code perspective
- [ ] Notes:

**Human UAT Check**
- [ ] Tested by user
- [ ] Notes:

#### Results
<!-- Append-only execution log — each run adds a row, never delete -->
| Status | Date | Verified By | Build | Notes |
|--------|------|-------------|-------|-------|
| ⬜ Untested | — | — | — | — |

=== END EXPLORATORY TEMPLATE === -->

______________________________________________________________________

## Reference

### Status Model

| Status | Marker | When to use |
|--------|--------|-------------|
| Pass | ✅ Pass | Test produced expected result |
| Fail | ❌ Fail | Test did not produce expected result (must include notes) |
| Skip | ⏭️ Skip | Intentionally not executed this cycle (must include reason) |
| Blocked | 🚧 Blocked | Cannot execute due to dependency or environment issue |
| Partial | ⚠️ Partial | Some criteria met, others not (must include details) |
| Untested | ⬜ Untested | Default state — not yet executed |

### Priority Levels

| Priority | Use for |
|----------|---------|
| critical | Core user flows, payment, auth, data integrity |
| high | Important features, error handling for critical paths |
| medium | Standard features, happy-path scenarios |
| low | Edge cases, cosmetic, nice-to-have behaviors |

### Test Types

| Type | Use for |
|------|---------|
| positive | Expected behavior works correctly (happy path) |
| negative | Invalid input, unauthorized access, error conditions |
| boundary | Limits, thresholds, edge values |
| security | Auth bypass, injection, privilege escalation |
| exploratory | Unscripted investigation (use charter template) |

### How to Use

1. **Create test cases**: `/story-cycle` generates them in Phase 4c, or write manually using the template above
2. **Sense-check batch**: `/claude-sense-check` finds all unchecked `- [ ] Logic verified from code perspective` boxes and verifies code logic
3. **Execute a test case**: `/UAT-cycle UAT-001` runs a specific test case manually
4. **Process findings**: `/testing-cycle <feedback>` classifies and routes ad-hoc findings
5. **Track progress**: Dashboard table updated automatically after each cycle

### Writing Good Test Cases

- **One scenario per test case** — focused and independently executable
- **Given/When/Then** — structured acceptance criteria, not free-form prose
- **User perspective** — "Click Submit" not "Trigger form submission"
- **Measurable outcomes** — "Error message 'Invalid email' appears" not "Error is handled"
- **Include setup** — what must be true before the test starts
- **Cover both paths** — separate test cases for happy path and error scenarios
- **Risk-based priority** — critical paths get `critical`, edge cases get `low`
- **AC coverage** — each acceptance criterion should have at least one Given/When/Then covering it; if an AC needs multiple scenarios, create separate test cases

### Traceability

Each test case's **Covers** field links to story IDs from the backlog. This replaces a separate Requirements Traceability Matrix:

- **Forward** (story -> tests): search this file for the story ID
- **Backward** (test -> story): read the Covers field
- **Gaps**: stories not referenced by any test case appear in Coverage Gaps

### AI Verification Boundaries

`/claude-sense-check` is strong at:
- Confirming code implements described happy paths
- Detecting constant/threshold mismatches between tests and code
- Identifying missing error handling for documented negative cases

`/claude-sense-check` cannot reliably:
- Validate business logic correctness (doesn't know if "5 attempts" is the right threshold)
- Catch race conditions or timing-dependent behavior
- Verify UI rendering or visual correctness
- Assess non-functional requirements (performance, load)

Human UAT remains required for these areas.

### Exit Criteria

Testing is complete when:
- All **critical** test cases: ✅ Pass or ⏭️ Skip (with documented justification)
- All **high** test cases: ✅ Pass, ⏭️ Skip, or ⚠️ Partial (with notes)
- No ❌ Fail on any critical or high case without a linked backlog story
- All sense-check boxes checked (`/claude-sense-check` complete)
- Coverage Gaps section shows no unlinked stories (or gaps are justified)

### Test Case Lifecycle

- **Active** — default state; test is part of the current regression suite
- **Deprecated** — feature removed or test superseded; change Status to `🗄️ Deprecated` with a one-line reason; keep in file for audit trail but skip during execution
- When deprecating, update Dashboard counts accordingly

### Scaling

When this file exceeds ~50 test cases, consider splitting into feature-grouped files:
```
docs/testing/uat/
  _index.md              # Dashboard (auto-generated)
  authentication/
    STORY-123-login.md   # One file per story
  payments/
    STORY-200-checkout.md
```
Each file keeps the same test case format. `/claude-sense-check` scans the directory recursively.

Per-story files use YAML front matter for machine parsing:
```yaml
---
story: STORY-123
feature: authentication
priority: critical
status: untested          # untested | pass | fail | partial | skip | blocked
sense_checked: false
last_tested: null         # ISO-8601 date
---
```
