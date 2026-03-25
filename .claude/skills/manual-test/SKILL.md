---
name: manual-test
version: 2.4.0
description: Prepare for manual testing session with test plan based on known issues, recent changes, and acceptance criteria.
trigger: manual
depends-on: []
references: []
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash
---
______________________________________________________________________

## manual-test

Preparing manual test session...

## 1. Gather Context

Read these files to understand what to test:

### Recent Changes

```bash
# What changed recently (last 20 commits or since last tag)
git log --oneline -20
git diff --stat HEAD~10
```

Identify which areas of the project were modified and map to testable features.

### Known Issues

Check the backlog for known gaps and bugs that are still TODO:

- Read relevant epic files in `docs/reference/backlog/`
- These are **confirmed issues** — test around them but don't spend time re-discovering them

### Recent Sprint Work

- Read `docs/progress.md` for latest sprint info
- Check `docs/sprints/` for recent sprint specs with acceptance criteria

### UAT Coverage

- Read `docs/testing/UAT_COVERAGE.md` (if it exists) for test case status
- Identify which areas have not been tested yet

### Product Requirements

- Read `docs/reference/PRD_SUMMARY.md` (if it exists) for persona and success criteria context
- Section 2 (target users) personas inform exploratory testing in Phase 3C
- Section 3 (success criteria) identify what to prioritize testing
- Section 4 (user flows) provide the core scenarios to regression test

## 2. Pre-Flight Checks

Before manual testing, verify the system is ready:

Run the project's test command (from CLAUDE.md) to ensure automated tests pass.

If pre-flight fails, fix issues before proceeding to manual testing.

## 3. Generate Test Plan

Generate a structured test plan covering three areas:

### A. Regression Tests (from recent changes)

Based on the git diff, generate specific test scenarios for recently modified code:

```markdown
#### Regression: [Area changed]
- [ ] **Scenario**: [What to test] — **Steps**: [How to test] — **Expected**: [What should happen]
```

### B. Known Issue Verification

For each recently fixed issue, generate a verification test:

```markdown
#### Verify Fix: [Story ID] — [Title]
- [ ] [Specific step to verify the fix still works]
```

For each open issue, note it as a known limitation:

```markdown
#### Known Limitation: [Story ID] — [Title]
- Warning: [Brief description] — skip testing this area
```

### C. Exploratory Testing

Based on architecture and project knowledge, suggest areas to probe.

**If PRD_SUMMARY.md was loaded:** Structure exploratory testing around each persona from Section 2. For each persona, create scenarios that exercise their primary goal, pain points, and constraints. Example: a persona with "low connectivity" constraints → test offline/slow-network behavior. A persona with "screen reader" constraints → test keyboard navigation and ARIA labels.

```markdown
#### Exploratory: [Feature Area] (as [Persona Name])
- [ ] [Step 1 — what to do and what to look for, from persona's perspective]
- [ ] [Step 2]

#### Exploratory: Error Handling
- [ ] [Provoke an error condition and verify graceful handling]

#### Exploratory: Edge Cases
- [ ] [Test boundary conditions, empty states, large inputs]
```

## 4. Present Test Plan

Output the complete test plan:

```markdown
## Manual Test Plan — [Date]

### Environment
- [List required services, tools, and their status]

### A. Regression Tests ([count] scenarios)
[generated scenarios]

### B. Known Issue Checks
**Verified fixes**: [count]
**Known limitations**: [count]
[generated checks]

### C. Exploratory Testing ([count] areas)
[generated areas]

### How to Report Findings
Use `/testing-cycle <description of what you found>` for each issue.
This will classify it and handle it through the right process.

For structured UAT, use `/UAT-cycle <test-case-id>` to execute formal test cases.
```

## 5. Wait for Testing

Tell the user:

> The test plan is ready. Start the application if not already running, then work through the checklist. Report each finding with `/testing-cycle <feedback>`. When done, wrap up with `/sprint-end`.

Do not proceed until user reports back.
