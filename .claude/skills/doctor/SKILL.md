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
- For `engine.py`: verify python3 is available
- For `engine.py` handlers: verify git is available (used by stop, session_start)

Report: PASS/WARN (missing optional tools)/FAIL (missing required tools)

## 3. Rule Relevance

For each rule in `.claude/rules/`:

- Read the YAML frontmatter `paths:` field
- Check if any files in the project match those patterns
- Report: ACTIVE (matches found) / DORMANT (no matches — rule will never trigger)

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

- Branch naming follows convention (`feature/*` or `sprint-*`)?
- Any stale feature branches (merged but not deleted)?
- Remote configured and accessible?

## 7. Skill Conformance

Execute `scripts/validate-skills.sh` directly — do NOT read source first.

```bash
bash .claude/skills/doctor/scripts/validate-skills.sh
```

Reports per-skill conformance: YAML frontmatter, line budget, required sections, reference budgets, registry version match. Include results in the health report under a "Skill Conformance" section.

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

### Overall: X/Y checks passed — [HEALTHY / NEEDS ATTENTION / ACTION REQUIRED]
```

## Next Steps

Based on findings, suggest:
- `/bootstrap` — if commands or hooks need configuration
- Specific fixes for any FAIL items
- `/weekly-maintenance` — if documentation is stale
