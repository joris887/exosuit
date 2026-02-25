# Quality Gates — Detailed Reference

Reference loaded by `/sprint-end` step 2. All gates must pass before proceeding.

## 2a. Tests

Run the project's test command (from CLAUDE.md Commands section). If the project has multiple test suites (e.g., backend + frontend), run all of them.

**If tests fail:** Stop. Fix failures first, then re-run `/sprint-end`.

## 2b. Test Protection

Execute `scripts/test-count-delta.sh` directly — do NOT read source first.

Compare test metrics on branch vs main. Run `bash scripts/test-count-delta.sh --help` first, then invoke:

```bash
bash scripts/test-count-delta.sh
```

If auto-detection fails, pass the test command explicitly:

```bash
bash scripts/test-count-delta.sh -- pytest --collect-only -q
```

- **Test count gate:** Total tests on branch must be >= total on main. Fail if tests were deleted.
- **Coverage delta gate:** Coverage for touched files must not decrease. Warn if overall coverage drops.
- **Assertion density:** Check for weakened assertions (e.g., `toBeTruthy` replacing specific `toBe` checks).

If test count decreased, present the deleted tests and ask user to confirm before proceeding.

## 2c. Quality Agents (Scope-Scaled Dispatch)

Before dispatching agents, classify sprint scope to determine which agents to run:

### Scope Classification

```bash
# Count changed source files (excluding docs, config, tests)
git diff --name-only main...HEAD
```

| Scope | Criteria | Agents to Dispatch |
|-------|----------|--------------------|
| **Minimal** | 1-3 files, none in src/ | test-validator only |
| **Small** | 1-5 src files | code-quality + test-validator |
| **Standard** | 6-15 src files | code-quality + test-validator + security-audit (if applicable) |
| **Large** | 16+ src files | All three + multi-perspective review |

**Security-audit override:** ALWAYS include security-audit if the diff touches auth, credentials, secrets, user data, network, or database code — regardless of scope classification.

### Dispatch

Dispatch applicable quality agents **simultaneously** as parallel Task agents (forked context to keep main clean). Do NOT run them sequentially — parallel execution saves time and gives each agent a truly independent perspective.

**Standard agents (per scope table above):**
- **Code Quality Agent** (`/code-quality`): Complexity, duplication, patterns
- **Test Validator Agent** (`/test-validator`): Coverage, quality, TDD compliance

**Conditionally dispatch** (per scope table OR if security-sensitive paths changed):
- **Security Audit Agent** (`/security-audit`): Vulnerabilities, secrets, SQL injection

Wait for all agents to complete. Aggregate findings. Apply confidence threshold: only findings scored ≥80 are actionable. Findings 50–79 are logged as notes but don't block. Any actionable finding from ANY agent blocks progression.

### Multi-Perspective Code Review (Optional Enhancement)

For sprints with significant code changes (10+ files or core logic), dispatch 2–3 code-reviewer agents in parallel using the `.claude/agents/code-reviewer.md` native agent with different lens values:

1. **Correctness reviewer** — `$3 = "correctness"`
2. **Conventions reviewer** — `$3 = "conventions"`
3. **Security reviewer** — `$3 = "security"` (if not already covered by `/security-audit`)

Issues flagged by 2+ independent reviewers are auto-elevated to **Critical**. This multi-perspective approach reduces single-reviewer blindness.

For smaller sprints, the standard quality agents (code-quality + test-validator) are sufficient.

Present aggregated agent findings to user. If critical issues found, stop and fix first.

**DO / DON'T:**
- DO run ALL quality agents before declaring gates passed — skipping one agent is not "mostly passed."
- DON'T use a previous session's quality results — run fresh agents against the current branch state.
- DO present all findings ≥80 confidence to the user, even if they seem minor.
- DON'T silently dismiss findings below the threshold — log them in the Notes section.

## Red Flags — Stop If You're Thinking:

| Rationalization | Why It's Wrong | Correct Action |
|----------------|----------------|----------------|
| "Tests mostly pass, good enough" | Mostly is not all | Fix all failures |
| "The quality agent found minor issues, skip them" | Minor issues compound | Present to user, let them decide |
| "CI will catch it" | CI is a safety net, not the primary check | Pass local checks first |
| "I already ran tests during story-cycle" | That was then, this is now | Run fresh test suite |

## Recovery: If Quality Gates Fail

- **Tests fail:** Stop. Show failures. Ask user to fix or run `/debug-session <error>`.
- **Test count decreased:** Show which tests were removed. Require explicit user approval to proceed.
- **Quality agents find critical issues:** Show findings. Security issues must be fixed. Others: user decides fix now vs. log to `docs/technical-debt.md`.
- **CI fails after push:** Diagnose locally, commit fix, push. Never force push.
