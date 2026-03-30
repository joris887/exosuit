---
name: doctor
version: 3.0.0
description: Validate framework configuration, check runtime dependencies, and report issues. Use when something isn't working or after setup.
trigger: manual
depends-on: []
references: []
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash
---
______________________________________________________________________

## doctor

Run a comprehensive health check on the framework configuration and project setup.

## 1. Command Verification

Read CLAUDE.md Commands section. For each configured command (test, lint, format, build, typecheck):

<IF condition="command is configured (not placeholder)">
Run the command in dry-run or check mode (e.g., `npm test --dry-run`, `ruff check --quiet .`).
Report: PASS if it executes, FAIL if it errors, SKIP if not configured.
</IF>
<ELSE>
Report: NOT CONFIGURED — suggest running `/bootstrap` to detect.
</ELSE>

## 2. Hook Dependencies

For each hook in `.claude/settings.json`:

- Verify the hook script file exists and is executable
- For `post-edit-format.sh`: check if at least one formatter is installed (prettier, biome, ruff, black, rustfmt, gofmt)
- For shell hook scripts: verify git is available (used by stop.sh, session-start.sh)
- Optional: check if jq is available (hooks fall back to sed without it)

Report: PASS/WARN (missing optional tools)/FAIL (missing required tools)

## 3. Rule Relevance

For each rule in `.claude/rules/`:

- Read the YAML frontmatter `paths:` field
- Check if any files in the project match those patterns
- Report: ACTIVE (matches found) / DORMANT (no matches — rule will never trigger)
- Check `docs/sessions/.activity-log.jsonl` for rule trigger frequency over the last 5 sessions
- Rules that are ACTIVE but have zero trigger events in 5+ sessions: report as REVIEW (candidate for retirement)
- The "pull their weight" test: if a rule never changes AI behavior, it wastes context budget

## 4. Skill Dependencies & Cross-References

For each skill with `depends-on:` in YAML frontmatter:

- Verify each dependency skill exists in `.claude/skills/`
- For skills with `requires:` — check binaries, commands, and files
- Report: PASS/WARN (optional dependency missing)/FAIL (required dependency missing)

For each skill with `calls:` in `skills-registry.json`:

- Verify each called skill exists in `.claude/skills/`
- Report any broken references (skill calls a non-existent skill)
- Report orphaned skills (not called by any other skill AND not user-invocable) as INFO — may be intentionally standalone

## 5. Documentation Freshness

Check key framework files:

- CLAUDE.md: Is "Current Focus" section filled (not placeholder)?
- docs/progress.md: Has it been updated this sprint?
- docs/reference/BACKLOG_INDEX.md: Are status counts current?
- docs/reference/GROUND_RULES.md: Does it exist and have principles?

Report: CURRENT/STALE/MISSING for each

## 6. Git State

- Branch naming follows convention (`feat/*`, `fix/*`, `hotfix/*`, `refactor/*`, `docs/*`, `test/*`, `chore/*`, or `sprint-*`)?
- Any stale branches (merged but not deleted)?
- Any unmerged branches with no commits in the last 2 weeks?
  ```bash
  git for-each-ref --sort=-committerdate --format='%(refname:short) %(committerdate:relative)' refs/heads/ | while read branch date; do echo "$branch — last commit $date"; done
  ```
  Flag branches with no commits in >14 days as "potentially stale — consider merging or deleting"
- Remote configured and accessible?

## 7. Skill Conformance

Execute `scripts/validate-skills.sh` directly — do NOT read source first.

```bash
bash .claude/skills/doctor/scripts/validate-skills.sh
```

Reports per-skill conformance: YAML frontmatter, line budget, required sections, reference budgets, registry version match. Include results in the health report under a "Skill Conformance" section.

## 8. Skill Usage Analytics

Parse `docs/sessions/.activity-log.jsonl` for entries with `"type":"skill"`:

```bash
# Extract skill invocation data from activity log
grep '"type":"skill"' docs/sessions/.activity-log.jsonl 2>/dev/null || echo "No skill data"
```

- Count invocations per skill name over all available log data
- Find the most recent invocation timestamp per skill
- List all skill directories from `.claude/skills/` (excluding SKILLS_INVENTORY.md, SKILL_TEMPLATE.md, and non-directory entries)
- Cross-reference invocations with available skills to classify:
  - **ACTIVE:** Invoked at least once in the log
  - **DORMANT:** Skill directory exists, user-invocable, but never invoked
  - **FREQUENT:** Invoked 5+ times (top skills)
- Note: Skills not in the log may still be useful — they may not have been needed yet. DORMANT is informational, not a problem.

## 9. Profile & Hook Status

Report the current project profile and hook configuration:

```bash
echo "Project profile: $(cat .claude/hooks/state/project-profile 2>/dev/null || echo 'standard (default)')"
echo "JD_PROJECT_PROFILE=${JD_PROJECT_PROFILE:-<not set, reading from CLAUDE.md>}"
echo "JD_HOOK_PROFILE=${JD_HOOK_PROFILE:-<derived from project profile>}"
echo "JD_DISABLED_HOOKS=${JD_DISABLED_HOOKS:-<none>}"
echo "JD_EXPLAIN_MODE=${JD_EXPLAIN_MODE:-brief}"
echo "JD_STOP_MAX_ITERATIONS=${JD_STOP_MAX_ITERATIONS:-5}"
```

- Show current project profile and its source (env var, CLAUDE.md `**Profile:**` line, or default)
- Show derived hook profile and whether it was explicitly overridden
- Profile implications:
  - **lean**: minimal hooks, simplified story-cycle (Plan→Build→Verify), no quality agents, no sprint specs
  - **standard**: standard hooks, full 8-phase story-cycle, 3 quality agents, full docs
  - **strict**: strict hooks, all phases mandatory for all stories, 5 quality agents + integration-tester, audit trail
- List any disabled hooks
- Verify `lib/hook-guard.sh` exists and is executable
- Show effective stop iteration limit (strict defaults to 10)

## Output

```markdown
## Framework Health Report

### Commands
| Command | Status | Notes |
|---------|--------|-------|
| test | PASS/FAIL/NOT CONFIGURED | [details] |
| lint | PASS/FAIL/NOT CONFIGURED | [details] |
| ... | | |

### Hooks
| Hook | Status | Missing Tools |
|------|--------|---------------|
| post-edit-format.sh | PASS/WARN | [list] |
| ... | | |

### Rules
| Rule | Status | Matching Files |
|------|--------|----------------|
| testing.md | ACTIVE | [count] files |
| ... | | |

### Skills
| Check | Status | Details |
|-------|--------|---------|
| Dependency resolution | PASS/WARN | [details] |
| Prerequisites | PASS/WARN | [details] |

### Documentation
| File | Status | Last Updated |
|------|--------|-------------|
| CLAUDE.md | CURRENT/STALE | [date] |
| ... | | |

### Skill Conformance
| Skill | Frontmatter | Lines | References | Registry |
|-------|-------------|-------|------------|----------|
| [name] | PASS/FAIL | [count] | PASS/WARN | PASS/WARN |

### Skill Usage
| Skill | Invocations | Last Used | Status |
|-------|-------------|-----------|--------|
| story-cycle | 15 | 2026-03-25 | ACTIVE |
| manual-test | 0 | never | DORMANT |

### Profile & Hook Configuration
| Setting | Value | Source |
|---------|-------|--------|
| Project Profile | lean/standard/strict | env var / CLAUDE.md / default |
| Hook Profile | minimal/standard/strict | env var / derived from project |
| Disabled Hooks | none or list | JD_DISABLED_HOOKS |
| Explain Mode | off/brief/verbose | JD_EXPLAIN_MODE |
| Stop Iterations | 5/10/custom | JD_STOP_MAX_ITERATIONS |
| Guard script | PASS/FAIL | lib/hook-guard.sh |

### Overall: X/Y checks passed — [HEALTHY / NEEDS ATTENTION / ACTION REQUIRED]
```

## Next Steps

Based on findings, suggest:
- `/bootstrap` — if commands or hooks need configuration
- Specific fixes for any FAIL items
- `/weekly-maintenance` — if documentation is stale
