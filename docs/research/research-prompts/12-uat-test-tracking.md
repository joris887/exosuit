# 12. UAT & Test Case Tracking

## Research Prompt

```
I need deep research on User Acceptance Testing documentation and test case management. The goal is to determine the best possible approach for a test tracking format that works for manual testing, automated UAT, and AI-assisted test verification — all in markdown without requiring a dedicated test management tool.

**Framework context:** This template is part of the JD-LLM Development Framework — a language-agnostic AI development framework for Claude Code. UAT tracking:
- Is used by /story-cycle Phase 4 (generates UAT test cases for features)
- Is used by /manual-test (reads for test planning)
- Is executed by /UAT-cycle (runs individual test cases)
- Is batch-verified by /claude-sense-check (AI code logic verification)
- Is updated by /testing-cycle (processes test findings)
The format must be parseable by /claude-sense-check for batch processing, and scale from a handful to hundreds of test cases.

**Research areas** (starting points — include anything significant you discover beyond these):

1. **Test Case Management Approaches** — TestRail, Zephyr, qTest format features worth stealing for markdown. BDD living documentation (Cucumber, SpecFlow). Exploratory testing charters. Risk-based testing. UAT at scale (Atlassian, Microsoft, banking/healthcare).

2. **Test Case Design Patterns** — Scenario-based vs step-based. Decision tables. State transition testing. Equivalence partitioning and boundary value analysis. Which test case fields actually get used?

3. **Traceability** — Requirements traceability matrix — worth maintaining? Story → test → code mapping. Coverage gap analysis. Bi-directional traceability.

4. **Test Execution & Results Tracking** — Status patterns (Pass/Fail/Blocked/Skip). Execution history. Defect linking. Retest tracking. Test metrics: pass rate, defect detection rate.

5. **AI-Assisted Test Verification** — Code logic verification (like /claude-sense-check). Automated test case generation from AC. Test case maintenance with code changes.

6. **UAT Process** — Planning and sign-off. Environment requirements. User feedback capture. Exit criteria. Regression selection.

**Required output format:**
1. Executive summary
2. Per-topic findings with citations
3. **Recommended test case format** — propose the specific fields, status model, and structure, with justification
4. **Recommended tracking structure** — how to organize test cases at scale in markdown
5. **Recommended traceability approach** — lightweight but effective
6. **Recommended AI verification integration** — how AI batch-checks test cases
7. Knowledge gaps
```

## Implementation Prompt

```
I have completed deep research on UAT and test case management. The research findings are saved in docs/research/uat-tracking.md (or I will paste them below).

Your task: Update the framework's UAT_COVERAGE.md template to be the best possible test tracking format, guided by the research findings.

**Hard constraints (non-negotiable):**
- File location: docs/testing/UAT_COVERAGE.md AND scaffold/docs/testing/UAT_COVERAGE.md
- Used by: /story-cycle Phase 4, /manual-test, /UAT-cycle, /claude-sense-check, /testing-cycle
- Must track test cases with status, dates, and findings
- Must support both manual execution and AI-assisted verification
- Must link test cases to stories (traceability)
- Must be parseable by /claude-sense-check for batch processing
- Must scale from a handful to hundreds of test cases

**Instructions:**
1. Read the current docs/testing/UAT_COVERAGE.md template
2. Read the research findings thoroughly
3. Implement the test case format, tracking structure, traceability approach, and AI verification integration the research recommends — trust the research over your own defaults
4. Verify /claude-sense-check can parse the new format (reads checkboxes, finds unchecked cases)
5. Verify /UAT-cycle can update the new format (status, findings, dates)
6. Update scaffold version to match

**Outcome criteria (how to evaluate the result):**
- No feature ships without verified acceptance criteria
- Test cases are easy to write, easy to execute, and easy to track
- /claude-sense-check can batch-process unchecked test cases automatically
- Traceability is lightweight but reveals coverage gaps
- Scales to hundreds of test cases without the file becoming unwieldy
```
