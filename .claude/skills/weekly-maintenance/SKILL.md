---
name: weekly-maintenance
version: 2.5.0
description: Execute comprehensive weekly maintenance routine (1-2 hours, Friday recommended). Includes health checks, quality review, dependency governance, and planning.
trigger: manual
depends-on: [code-quality]
references: []
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Edit, Write
---
______________________________________________________________________

## weekly-maintenance

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
- Dead code: unused exports, orphaned functions (run monthly or when codebase > 5K LOC)

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

## 5. Rule Health Review

Run the metrics script to assess rule effectiveness:

```bash
bash scripts/pm/metrics.sh
```

Review the "Rule Triggers" section. Flag:
- **Over-active rules** (>20 triggers/week) — may be too broad or indicating a persistent issue
- **Silent rules** (0 triggers in 30+ days) — may be too narrow or addressing a solved problem
- **High-failure skills** (success rate <70%) — investigate common failure points

Record findings in the weekly summary below.

## 5.5. Ground Rules Health

<IF condition="docs/reference/GROUND_RULES.md exists and has GR-NNN rules">
Check the health of project ground rules:

- **Expired exceptions** — scan the Exception Log table for rows where `Expires` date has passed. Flag for resolution (remove exception or renew with justification).
- **Stale rules** — if Change History shows no updates in 6+ months, the rules may need a freshness review.
- **Compliance trends** — read `docs/progress.md` → `## Ground Rule Compliance`. Consistent violations of one rule may mean the rule is unrealistic, or enforcement is missing.
- **Enforcement gaps** — for rules with `Enforced-by: auto:`, verify the tool/test still exists and runs in CI. Unconfigured enforcement = paper rule.
</IF>

## 5.7. Architecture Decision Health

<IF condition="docs/adr/ contains ADR files">
Review the health of architecture decision records:

- **Low-confidence ADRs** — scan for `confidence: low` in frontmatter. For each, check whether `Reconsider when` conditions have been met by the current codebase state. Flag any that need re-evaluation.
- **Stale ADRs** — if no ADR has been created or reviewed in 90+ days on an actively developed project, the team may be making undocumented decisions. Flag as a process gap.
- **Supersession chains** — check for `superseded-by` chains longer than 2 (A→B→C). These indicate a volatile decision area that may need a ground rule instead.
- **Ground rule candidates** — if 2+ accepted ADRs address the same concern, suggest promoting to `docs/reference/GROUND_RULES.md`.
- **ADR count health** — projects with <5 ADRs and >10 major dependencies are likely under-documenting decisions.
</IF>

## 6. Weekly Summary

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

## 7. Plan Next Week

Review @docs/reference/BACKLOG_INDEX.md and relevant epic files to identify:

- Next 3-5 stories to target
- Any blockers to address first
- Dependencies between stories

Output comprehensive weekly report with actionable items.
