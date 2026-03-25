---
name: backlog-review
version: 3.0.0
description: Execute comprehensive backlog review. Analyzes story quality, Definition of Ready compliance, dependencies, zombie stories, and generates a backlog health report.
trigger: manual
depends-on: []
references: []
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep
---
______________________________________________________________________

## backlog-review

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

For each non-done story, validate against the **Definition of Ready** checklist:

| Criterion | Check |
|-----------|-------|
| Title clear and specific | Describes the change, not the problem |
| Type assigned | One of: feature, bugfix, refactor, spike, infra, testing, docs, security, performance, skill |
| Size classified | TRIVIAL, SMALL, or STANDARD. If >5 affected files → flag for splitting |
| 3-7 acceptance criteria | Each testable and specific. No "should be fast" or "handle errors properly" |
| Verification commands | Exact commands that prove completion |
| Out of scope defined | At least one explicit exclusion |
| Affected files listed | Max 5 files per story |
| Pattern references | "Follow patterns in [file]" where applicable |
| Dependencies resolved | No unresolved blockers |
| No ambiguous language | No vague terms, all criteria measurable |
| Self-contained | All referenced context included or linked |

Classify each story:
- **Ready**: Passes all 11 criteria → `status: ready`
- **Needs refinement**: Missing 1-3 criteria → list what's missing
- **Needs rewrite**: Missing 4+ criteria or too large → flag for `/ideate` refinement

## 4. Dependency Mapping

Create dependency graph for upcoming work:

```
[Story A] --depends on--> [Story B]
                              |
                              v
                         [Story C]
```

**Validate dependency health:**
- Flag circular dependencies (A→B→C→A)
- Flag stories blocked by draft/not-ready dependencies
- Flag stories with >2 transitive dependencies (fragile chain)
- Identify the critical path: longest dependency chain

## 5. Zombie Story Detection

Check each story's `created:` date (from inline metadata or YAML frontmatter):

- **Zombie** (>2 sprint cycles old, still not done): Must be split or killed
- **Aging** (>1 sprint cycle, same status): Flag for attention
- **Stalled** (status: `in-progress` but no commits referencing it in >1 week): Flag as potentially abandoned

For each zombie, recommend: **Split** (too large), **Kill** (no longer needed), or **Unblock** (has a blocker that can be resolved).

## 6. Flow Metrics

If `docs/sessions/.activity-log.jsonl` exists and contains story events:

- **Throughput**: Stories completed per sprint (from story events with `to: done`)
- **Cycle time by size**: Average time from `in-progress` to `done` for TRIVIAL/SMALL/STANDARD
- **Completion rate**: Stories started vs completed
- **Type distribution**: Which story types are most common

## 7. Backlog Health Report

```markdown
## Backlog Health Report - [Date]

### Overall Health: X/10

### Definition of Ready Compliance
- Stories meeting DoR: X/Y (Z%)
- Common DoR failures: [list most frequent missing criteria]
- Stories needing refinement: [list IDs]

### Coverage
- Requirements covered: X%
- Orphan stories (no requirement trace): X
- Requirement gaps (no stories): [list]

### Quality
- Stories ready for sprint: X
- Stories needing refinement: Y
- Stories too large (need split): Z

### Flow
- Throughput: X stories/sprint (last 3 sprints)
- Avg cycle time: TRIVIAL Xh, SMALL Xh, STANDARD Xh
- Completion rate: X%

### Zombie Stories
- Zombie (>2 cycles): [list IDs with age]
- Aging (>1 cycle): [list IDs]
- Stalled in-progress: [list IDs]

### Dependency Health
- Stories with unresolved blockers: [list]
- Circular dependencies: [list or "None"]
- Critical path length: X stories

### Priority Issues
- Blocked items: [list]
- Misordered dependencies: [list]

### Recommended Actions
1. [Action with specific story IDs]
2. [Action]
3. [Action]
```

Update `docs/reference/BACKLOG_INDEX.md` Backlog Health section with the calculated metrics.

Output the full backlog health report with specific recommendations.
