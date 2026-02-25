# User Acceptance Testing Coverage

**Last Updated:** <!-- date -->

## Purpose

This document defines all user acceptance test cases for the project. Each test case covers one or more features/stories and focuses on user-visible behavior that must be manually verified.

## Status Summary

| Area | Test Cases | Not Tested | Pass | Fail | Blocked |
| ---- | ---------- | ---------- | ---- | ---- | ------- |
<!-- Filled by /UAT-cycle or manually. Example:
| Authentication     | 3 | 2 | 1 | 0 | 0 |
| Dashboard          | 4 | 4 | 0 | 0 | 0 |
| Data Export        | 2 | 2 | 0 | 0 | 0 |
| **Total**          | **9** | **8** | **1** | **0** | **0** |
-->

## Test Case Format

Each test case includes:

- **ID**: UAT-### (sequential)
- **Title**: Short descriptive name
- **Covers**: Backlog story IDs or feature area this test validates
- **Prerequisites**: What must be set up before testing
- **Steps**: Numbered actions to perform
- **Acceptance Criteria**: Pass/fail conditions (checkboxes)
- **Status**: Not Tested / Pass / Fail / Blocked
- **Tested On**: Date of last test
- **Findings**: Notes from test execution

______________________________________________________________________

## Test Cases

<!-- Add test cases below. Use this template:

### UAT-001: [Title]

**Covers:** [Story IDs or feature area]

**Prerequisites:** [What must be running/configured]

**Steps:**

1. [Action to perform]
1. [Verify expected outcome]
1. [Next action]

**Acceptance Criteria:**

- [ ] [Verifiable criterion 1]
- [ ] [Verifiable criterion 2]
- [ ] [Verifiable criterion 3]

**Status:** Not Tested
**Tested On:** —
**Findings:** —

-->

______________________________________________________________________

## How to Use

1. **Create test cases**: Use `/ideate` or write manually following the template above
2. **Execute a test case**: `/UAT-cycle UAT-001` (or just `/UAT-cycle` to browse)
3. **Process findings**: The UAT cycle handles classification, fixing, and logging
4. **Track progress**: Status summary table updated automatically after each cycle

## Creating Good Test Cases

- **One scenario per test case** — keep them focused and independently executable
- **User perspective** — describe what the user does and sees, not internal implementation
- **Concrete steps** — "Click the Submit button" not "Trigger form submission"
- **Measurable criteria** — "Error message appears" not "Error is handled properly"
- **Include prerequisites** — what must be true before the test starts
- **Cover happy path AND edge cases** — separate test cases for error scenarios
