---
name: weekly-maintenance
version: 2.4.0
description: Execute comprehensive weekly maintenance routine (1-2 hours, Friday recommended). Includes health checks, quality review, dependency governance, and planning.
trigger: manual
depends-on: [code-quality]
references: []
---
______________________________________________________________________

## name: weekly-maintenance description: Execute comprehensive weekly maintenance routine (1-2 hours, Friday recommended). Includes health checks, quality review, dependency governance, and planning. disable-model-invocation: true user-invocable: true allowed-tools: Read, Glob, Grep, Bash, Edit, Write

Execute comprehensive weekly maintenance routine (1-2 hours, Friday recommended):

## 1. Codebase Health Check

Run the project's quality/health tools (from CLAUDE.md Commands section):

```bash
# Use project-specific commands, e.g.:
# just health, npm run lint, cargo clippy, etc.
```

Report on:

- Complexity trends (should be stable or decreasing)
- Duplication percentage (target: <5%)
- High-churn files that may need attention

## 2. Code Quality Agent Review

Use the code-quality skill to analyze the entire codebase:

- Flag any functions with CCN >10
- Identify duplication patterns
- Check for pattern consistency violations

## 3. Documentation Review

Check key documentation for accuracy:

- @CLAUDE.md accuracy (commands, paths, patterns still correct?)
- @docs/progress.md completeness
- Any drift between docs and implementation
- **Documentation efficiency**: Key context files (CLAUDE.md, progress.md, BACKLOG_INDEX.md) are loaded every session — keep them lean. Archive stale content, deduplicate, condense verbose sections.

## 4. Dependency Review

Check for outdated dependencies using the project's package manager:

```bash
# npm outdated, pip list --outdated, cargo outdated, etc.
```

### Dependency Health Check

Run dependency auditing tools:

```bash
# npm audit / pip-audit / cargo audit / bundler-audit
```

Flag and report:

- **Recently added packages** (added since last maintenance) — verify they exist in the registry and are well-established
- **Young packages** (< 7 days old) — flag as supply chain risk
- **Known vulnerabilities** — categorize by severity
- **Lockfile sync** — verify lockfile matches dependency manifest
- **Recently deprecated packages** — check for deprecation notices

### Dependency Report

```markdown
### Dependency Health
- Total dependencies: [count]
- Outdated: [count]
- Vulnerabilities: [critical/high/medium/low counts]
- Recently added: [list with age and download counts]
- Lockfile in sync: [yes/no]
```

## 5. Weekly Summary

Update @docs/progress.md with:

```markdown
## Week of [Date]

### Sprints Completed
- [Sprint X]: [Story ID] - [Title]

### Metrics
- Stories completed: X
- Test count: X (delta: +/-Y)
- Test coverage: X% (delta: +/-Y)

### Health Indicators
- Complexity trend: [stable/increasing/decreasing]
- Duplication: X%
- High-churn files: [list if concerning]
- Dependency health: [count] vulnerabilities, [count] outdated

### Technical Debt Identified
- [Item]: [Location] - [Priority]

### Next Week Focus
- [Story IDs planned]
```

## 6. Plan Next Week

Review @docs/reference/BACKLOG_INDEX.md and relevant epic files to identify:

- Next 3-5 stories to target
- Any blockers to address first
- Dependencies between stories

Output comprehensive weekly report with actionable items.
