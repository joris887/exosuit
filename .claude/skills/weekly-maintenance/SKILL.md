---
name: weekly-maintenance
version: 2.6.0
description: Execute comprehensive weekly maintenance routine (1-2 hours, Friday recommended). Includes health checks, quality review, dependency governance, activity insights, and planning.
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
- **Metrics freshness**: If `docs/progress.md` → `## Sprint History` has ≥2 data rows but `## Metrics` table still shows "—" values, sprint-end is not computing metrics — flag as a measurement gap. The feedback loop is broken: data collected but not surfaced.

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

## 4.3. Security Health Check

Perform a focused security health review:

### Secrets Inventory Review
<IF condition="docs/reference/SECRETS_INVENTORY.md exists">
Read `docs/reference/SECRETS_INVENTORY.md` and check:
- **Overdue rotations:** Scan the `Next Due` column for dates in the past. Flag by severity: ≤7 days (warning), 8-30 days (high priority), >30 days (critical — rotate immediately).
- **Missing rotation methods:** Any secrets without a documented `Rotation Method` should be flagged.
- **Critical secrets without automation:** Secrets classified as `critical` that rely on `manual` rotation are high-risk.
</IF>
<ELSE>
If `docs/reference/SECRETS_INVENTORY.md` does not exist but the project uses environment variables or credentials, note this as a gap: "No secrets inventory — consider creating one from the template in the framework scaffold."
</ELSE>

### Dependency Security Audit
Run the project's dependency audit tool (same as section 4, but focused on security):
```bash
# npm audit --audit-level=high / pip-audit / cargo audit / govulncheck / bundler-audit
```
Report Critical and High vulnerabilities. These should be addressed before the next sprint.

### Quarterly Full-Repo Secret Scan
On the first weekly-maintenance of each quarter, run a full repository secret scan if Gitleaks or similar is available:
```bash
gitleaks detect --source . --no-git --report-format json 2>/dev/null
```
Report any findings. This catches secrets missed by the per-file post-edit hook.

## 4.5. Technical Debt Register Review

Read `docs/technical-debt.md` and perform the weekly debt review:

### Triage active items
For each active item:
- **Interest rate reassessment** — check coupling to determine if interest is Growing or Stable. Run `grep -rn` on the debt item's Location files to count how many other files import/reference them. High fan-in (imported by >5 files) + active debt = Growing interest. Isolated files with no dependents = Stable or Shrinking.
- **Severity check** — has the item worsened? (e.g., new incidents, more files affected). Promote if so.
- **Resolution progress** — is there a linked story? If not and item is >30 days old, consider creating one.
- **Accept or resolve** — can any items move to "Accepted" (conscious trade-off) or "Resolved" (fixed)?

### Detect new debt
Check this week's commits and code quality findings for new debt. Specifically scan for the **5 AI-specific debt types**:

1. **Comprehension debt** — grep git log for AI-assisted commits (`Co-Authored-By: Claude` or similar). For files with high AI-commit ratio that haven't been manually modified since, flag as potential comprehension debt. The risk: code ships faster than developers understand it.
2. **Pattern violation debt** — compare this week's changes against `docs/reference/CODING_STANDARDS.md` (if exists). AI introduces inconsistent patterns at 3x the human rate for formatting, 2x for naming.
3. **Duplication debt** — check for near-duplicate code blocks introduced this week. AI regenerates rather than reusing existing functions.
4. **Phantom dependency debt** — verify all imports added this week reference packages that exist in the project's dependency manifest (package.json, requirements.txt, go.mod, Cargo.toml, etc.).
5. **Verification debt** — check if large AI-generated diffs have corresponding test coverage. Code reviewed without full understanding creates hidden risk.

Tag new items with `origin: ai-generated` when the source commit has AI co-author markers.

### Housekeeping
1. **Review dates** — update "Last reviewed" to today, "Next review" to +7 days
2. **Resolved cleanup** — delete resolved items older than 90 days
3. **AI trends** — at quarter boundaries, update the AI Debt Trends table with counts
4. **Active count** — update header: `Active items: X | Resolved this quarter: Y`
5. **Sprint candidates** — flag items with priority score ≥4.5 or interest "Growing" for next sprint planning. `/sprint-start` reads these during its debt health check.

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

Also run the progress dashboard for trend signals and relative changes:

```bash
bash scripts/pm/metrics.sh --progress
```

Review the output for:
- Any metrics with Δ3avg >50% (rapid change worth investigating)
- Leading vs Lagging divergences (early warning signals)
- Persistent 3-sprint trends that haven't been addressed

## 5.5. Ground Rules Health

<IF condition="docs/reference/GROUND_RULES.md exists and has GR-NNN rules">
Check the health of project ground rules:

- **Expired exceptions** — scan the Exception Log table for rows where `Expires` date has passed. Flag for resolution (remove exception or renew with justification).
- **Stale rules** — if Change History shows no updates in 6+ months, the rules may need a freshness review.
- **Compliance trends** — read recent sprint specs (`docs/sprints/sprint-N.md`) → `## Outcome` → **Ground rules** field. Consistent violations of one rule may mean the rule is unrealistic, or enforcement is missing.
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

## 5.9. Weekly Activity Insights

Parse `docs/sessions/.activity-log.jsonl` for the past 7 days of activity:

```bash
ACTIVITY_LOG="docs/sessions/.activity-log.jsonl"
WEEK_AGO=$(date -v-7d +%Y-%m-%d 2>/dev/null || date -d "7 days ago" +%Y-%m-%d 2>/dev/null)
if [ -f "$ACTIVITY_LOG" ] && [ -s "$ACTIVITY_LOG" ]; then
  # Filter to last 7 days and analyze
  # Top 3 most-edited files this week
  # Skill invocation counts
  # Test failure patterns (same test failing repeatedly = flaky or fundamental)
  # Edit-to-test ratio for the week
fi
```

Present as a concise summary (5-10 lines max):

```markdown
### Weekly Activity Insights
- **Hot files:** `src/auth/login.ts` (23 edits), `src/api/users.ts` (15 edits), `tests/auth.test.ts` (12 edits)
- **Skills used:** /story-cycle (8x), /commit (6x), /debug-session (2x), /sprint-end (1x)
- **Test health:** 3 failures this week — `auth.test.ts:login_expired_token` failed 2x (possible flaky test)
- **Edit-to-test ratio:** 3.2 (good TDD discipline)
- **Sessions:** 4 sessions, avg 45 min each
```

Flag patterns worth investigating:
- Same test failing in multiple sessions → likely flaky or fundamental issue
- High edit-to-test ratio (>5.0) → TDD discipline slipping
- One file getting >30% of all edits → possible hotspot needing refactoring
- Skills with repeated failures → investigate common failure points

## 6. Weekly Summary

Update @docs/progress.md with:

```markdown
## Week of [Date]

### Sprints Completed
- [Sprint X]: [Story ID] - [Title]

### Metrics Status
Reference `docs/progress.md` → `## Metrics` table for current sprint metrics.
Additional weekly indicators not tracked per-sprint:
- Complexity trend: [stable/increasing/decreasing]
- Duplication: X%
- Dependency health: [count] vulnerabilities, [count] outdated

### Technical Debt
- New items added: [count] (AI-origin: [count])
- Items resolved: [count]
- Active totals: [N] critical / [N] high / [N] medium / [N] low
- Growing-interest items needing attention: [list or "none"]

### Next Week Focus
- [Story IDs planned]
```

## 7. Plan Next Week

Review @docs/reference/BACKLOG_INDEX.md and relevant epic files to identify:

- Next 3-5 stories to target
- Any blockers to address first
- Dependencies between stories

Output comprehensive weekly report with actionable items.
