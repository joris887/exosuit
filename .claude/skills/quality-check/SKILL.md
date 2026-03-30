---
name: quality-check
version: 1.0.0
description: Unified quality gate dispatcher. Runs selected quality checks with profile-aware defaults.
trigger: manual
depends-on: [code-quality, test-validator, security-audit, architecture-check, performance-check]
references: []
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Agent
argument-hint: "[--code] [--tests] [--security] [--architecture] [--performance] [--all]"
---
______________________________________________________________________

## quality-check

Running quality gates: **$ARGUMENTS**

## 1. Parse Flags

Extract check selection from `$ARGUMENTS`:

| Flag | Dispatches |
|------|-----------|
| `--code` | `/code-quality` |
| `--tests` | `/test-validator` |
| `--security` | `/security-audit` |
| `--architecture` | `/architecture-check` |
| `--performance` | `/performance-check` |
| `--all` | All 5 checks above |

## 2. Apply Profile Defaults

If NO flags are provided, read the project profile from the `**Profile:**` line in CLAUDE.md and apply defaults:

| Profile | Default Checks |
|---------|---------------|
| **lean** | `--code` (lint + complexity only) |
| **standard** | `--code --tests --security` |
| **strict** | `--all` plus integration-tester agent |

If the profile is not set or not recognized, default to **standard** behavior.

## 3. Run Quality-Gate-Sequence First

Before dispatching agent skills, run the `quality-gate-sequence` micro-component from `.claude/prompts/quality-gate-sequence.md` — this runs lint, typecheck, and tests from CLAUDE.md Commands. These are fast, deterministic checks that catch issues before the more expensive agent analysis.

**HARD GATE:** If tests fail, stop here. Do not dispatch agent skills on failing code.

## 4. Dispatch Selected Checks

Dispatch each selected check as a parallel Task agent. Each invokes the corresponding skill:

```
For each selected check:
  Launch Agent (subagent_type: general-purpose) with prompt:
    "Run /<skill-name> on the current codebase. Return a structured report."
```

Run all selected checks in parallel for efficiency. Wait for all to complete.

<IF condition="Profile is strict AND --all was selected (explicitly or via default)">
Also dispatch the `integration-tester` native agent (`.claude/agents/integration-tester.md`) to independently verify acceptance criteria by running commands.
</IF>

## 5. Unified Report

Combine results from all dispatched checks into a single report:

```markdown
## Quality Gate Report

| Check | Status | Key Findings |
|-------|--------|-------------|
| Code Quality | PASS/WARN/FAIL | [summary] |
| Test Validator | PASS/WARN/FAIL | [summary] |
| Security Audit | PASS/WARN/FAIL | [summary] |
| Architecture | PASS/WARN/FAIL/SKIP | [summary] |
| Performance | PASS/WARN/FAIL/SKIP | [summary] |
| Integration Test | PASS/WARN/FAIL/SKIP | [summary] |

**Overall: PASS / WARN / FAIL**
```

Verdict rules:
- **PASS** — all checks pass with no blocking findings
- **WARN** — advisory findings only (no blocking issues)
- **FAIL** — one or more checks have blocking findings

## 6. Return Verdict

Return the unified report and overall verdict. Callers (sprint-end, story-cycle) use this verdict for gate decisions.

If FAIL: list the specific blocking findings with `file:line` references so the caller can address them.

## Error Handling

- If a dispatched agent fails or times out: report that check as WARN with "agent failed — manual review recommended"
- If no checks are selected and profile cannot be determined: fall back to standard defaults (code + tests + security)
- If CLAUDE.md Commands has no test command configured: skip the test gate in quality-gate-sequence, note in report
