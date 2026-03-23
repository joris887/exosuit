# 12. UAT & Test Case Tracking

## Research Prompt

```
I need comprehensive deep research on User Acceptance Testing documentation and test case management. The goal is a test tracking format that works for manual testing, automated UAT, and AI-assisted test verification — all in markdown without requiring a dedicated test management tool.

Research these specific areas:

1. **Test Case Management Approaches**
   - Traditional test management tools (TestRail, Zephyr, qTest) — what format features to steal for markdown
   - BDD tools (Cucumber, SpecFlow) — living documentation from executable specs
   - Exploratory testing charters (session-based testing management)
   - Risk-based testing — how to focus test effort on what matters
   - How companies handle UAT at scale (Atlassian, Microsoft, banking/healthcare)

2. **Test Case Design Patterns**
   - Scenario-based vs step-based test cases — which produces better coverage?
   - Decision tables for complex logic testing
   - State transition testing — documentation format
   - Equivalence partitioning and boundary value analysis — how to document efficiently
   - Test case templates — what fields actually get used?

3. **Traceability**
   - Requirements traceability matrix — is it worth maintaining?
   - Story → test case → code path mapping — lightweight approaches
   - Coverage gap analysis — how to identify untested requirements
   - Bi-directional traceability (requirement → test AND test → requirement)

4. **Test Execution & Results Tracking**
   - Pass/Fail/Blocked/Skip status tracking patterns
   - Test execution history — what to track over time
   - Defect linking — connecting failures to bug reports
   - Retest tracking — when a fix is applied, which tests to re-run?
   - Test metrics: pass rate, defect detection rate, test execution time

5. **AI-Assisted Test Verification**
   - Code logic verification (like the framework's /claude-sense-check) — research on effectiveness
   - Automated test case generation from acceptance criteria
   - Visual testing with AI — screenshot comparison approaches
   - Test case maintenance — how to keep test cases current with code changes

6. **UAT Process**
   - UAT planning and sign-off workflows
   - UAT environment requirements documentation
   - User feedback capture during UAT
   - UAT exit criteria — when is UAT "done"?
   - Regression test selection for UAT cycles

For each finding, include sources, template examples, and assessment of overhead vs value.

Output a structured research report with: recommended test case format, tracking structure, traceability approach, and AI verification integration patterns.
```

## Implementation Prompt

```
I have completed deep research on UAT and test case management. The research findings are saved in docs/research/uat-tracking.md (or I will paste them below).

Your task: Update the framework's UAT_COVERAGE.md template to be the best possible test tracking format.

**Context:** The template lives at docs/testing/UAT_COVERAGE.md (and scaffold/docs/testing/UAT_COVERAGE.md). It's used by:
- /story-cycle Phase 4 (generates UAT test cases for features)
- /manual-test (reads for test planning)
- /UAT-cycle (executes test cases)
- /claude-sense-check (batch code logic verification)
- /testing-cycle (processes test findings)

It must:
- Track test cases with status, dates, and findings
- Support both manual execution and AI-assisted verification
- Link test cases to stories (traceability)
- Be parseable by /claude-sense-check for batch processing
- Scale from a handful to hundreds of test cases without becoming unwieldy

**Instructions:**
1. Read the current docs/testing/UAT_COVERAGE.md template
2. Read the research findings
3. Redesign the template:
   - Status summary table (at-a-glance coverage health)
   - Test case format (ID, title, preconditions, steps, expected, actual, status)
   - Claude Sense Check section per test case (code logic verification)
   - Traceability fields (which story/epic each test covers)
   - Findings log (bug, gap, enhancement tracking)
   - Regression test selection guidance
4. Verify /claude-sense-check can parse the new format (reads checkboxes, finds unchecked cases)
5. Verify /UAT-cycle can update the new format (status, findings, dates)
6. Update scaffold version to match

Make this the test tracking document that ensures no feature ships without verified acceptance criteria.
```
