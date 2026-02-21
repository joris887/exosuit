______________________________________________________________________

## name: backlog-review description: Execute comprehensive backlog review. Analyzes theme coverage, story quality, dependencies, and generates a backlog health report. disable-model-invocation: true user-invocable: true allowed-tools: Read, Glob, Grep

Execute comprehensive backlog review:

## 1. Load Current State

Read these files:

- @docs/reference/BACKLOG_INDEX.md (backlog overview)
- docs/reference/backlog/E##-name.md (epic files as needed)
- @docs/reference/PRD_SUMMARY.md (requirements overview, if exists)
- @docs/progress.md (completed work)

## 2. Theme Coverage Analysis

Map each epic to requirements:

| Epic | Requirements Covered | Coverage % | Gap Analysis |

### Priority Validation

- Are high-priority items truly high-value?
- Are dependencies properly ordered?
- Any blocked items that should be deprioritized?

### Scope Assessment

- Stories that exceed original scope
- Features creeping in without justification
- Non-goals being violated

## 3. Story Quality Scan

For upcoming TODO stories, review:

- INVEST criteria (Independent, Negotiable, Valuable, Estimable, Small, Testable)
- Acceptance criteria completeness
- Testability assessment
- Suggested improvements

## 4. Dependency Mapping

Create dependency graph for upcoming work:

```
[Story A] --depends on--> [Story B]
                              |
                              v
                         [Story C]
```

## 5. Estimation Review

For stories with estimates:

- Compare to actual completion times
- Identify systematic over/under estimation
- Adjust future estimates accordingly

## 6. Backlog Health Report

```markdown
## Backlog Health Report - [Date]

### Overall Health: X/10

### Coverage
- Requirements covered: X%
- Orphan stories (no requirement trace): X
- Requirement gaps (no stories): [list]

### Quality
- Stories ready for sprint: X
- Stories needing refinement: Y
- Stories too large (need split): Z

### Priority Issues
- Blocked items: [list]
- Misordered dependencies: [list]
- Overdue items: [list]

### Recommended Actions
1. [Action with specific story IDs]
2. [Action]
3. [Action]
```

Output the full backlog health report with specific recommendations.
