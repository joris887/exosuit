# Quality Gates — Detailed Reference

Reference loaded by `/sprint-end` step 2. All gates must pass before proceeding.

## 2a. Tests

Run the project's test command (from CLAUDE.md Commands section). If the project has multiple test suites (e.g., backend + frontend), run all of them.

**If tests fail:** Stop. Fix failures first, then re-run `/sprint-end`.

## 2b. Test Protection

Run `.claude/skills/sprint-end/scripts/test-count-delta.sh` — do NOT perform the test count comparison manually.

The script auto-detects the base branch from CLAUDE.md, git remote HEAD, or common branch names. Run `--help` first if unsure about arguments:

```bash
bash .claude/skills/sprint-end/scripts/test-count-delta.sh
```

If base branch detection fails, pass it explicitly:

```bash
bash .claude/skills/sprint-end/scripts/test-count-delta.sh --base-branch master
```

If test framework auto-detection fails, pass the test command explicitly:

```bash
bash .claude/skills/sprint-end/scripts/test-count-delta.sh -- pytest --collect-only -q
```

- **Test count gate:** Total tests on branch must be >= total on base branch. Fail if tests were deleted.
- **Coverage delta gate:** Coverage for touched files must not decrease. Warn if overall coverage drops.
- **Assertion density:** Check for weakened assertions (e.g., `toBeTruthy` replacing specific `toBe` checks).

If test count decreased, present the deleted tests and ask user to confirm before proceeding.

## 2c. Quality Agent Skills (Scope-Scaled Dispatch)

**Important:** Dispatch quality agent **skills** (`/code-quality`, `/test-validator`, `/security-audit`, `/architecture-check`), NOT native agents (`.claude/agents/`). Skills have structured checklists, confidence scoring, and AI-specific anti-pattern detection. Native agents use persona-driven review — they complement but do not replace skill-based quality gates.

Before dispatching, classify sprint scope to determine which skills to run:

### Scope Classification

```bash
# Count changed source files (excluding docs, config, tests)
git diff --name-only $DEFAULT_BRANCH...HEAD
```

| Scope | Criteria | Skills to Dispatch |
|-------|----------|--------------------|
| **Minimal** | 1-3 files, none in src/ | /test-validator only |
| **Small** | 1-5 src files | /code-quality + /test-validator |
| **Standard** | 6-15 src files | /code-quality + /test-validator + /security-audit (if applicable) |
| **Large** | 16+ src files | All four skills + optional multi-perspective review |

**Security-audit override:** ALWAYS include `/security-audit` if the diff touches auth, credentials, secrets, user data, network, or database code — regardless of scope classification.

**Architecture-check override:** ALWAYS include `/architecture-check` if the diff touches module boundaries, introduces new dependencies, or changes file structure — regardless of scope classification.

### Dispatch

Dispatch selected quality agent skills **simultaneously** as parallel Task agents (forked context to keep main clean). Do NOT run them sequentially — parallel execution saves time and gives each agent a truly independent perspective.

**Quality agent skills:**
- `/code-quality` — complexity, duplication, dead code, naming patterns
- `/test-validator` — coverage, quality, TDD compliance, weakened assertions, deleted tests
- `/security-audit` — OWASP top 10, secrets, injection, auth issues, CWE checklist
- `/architecture-check` — module boundaries, dependency direction, coupling, architectural drift

Wait for all skills to complete. Aggregate findings. Apply confidence threshold: only findings scored ≥80 are actionable. Findings 50–79 are logged as notes but don't block. Any actionable finding from ANY skill blocks progression.

### Multi-Perspective Code Review (Optional Enhancement)

For sprints with significant code changes (10+ files or core logic), you may additionally dispatch 2–3 native code-reviewer agents in parallel using `.claude/agents/code-reviewer.md` with different lens values:

1. **Correctness reviewer** — `$3 = "correctness"`
2. **Conventions reviewer** — `$3 = "conventions"`
3. **Security reviewer** — `$3 = "security"` (if not already covered by `/security-audit`)

Issues flagged by 2+ independent reviewers are auto-elevated to **Critical**. This multi-perspective approach reduces single-reviewer blindness.

**Note:** Native agent review is supplementary — it does NOT replace the quality agent skills dispatched above. For smaller sprints, the standard quality skills are sufficient.

Present aggregated findings to user. If critical issues found, stop and fix first.

### Cross-Validation Step

After all quality agents report findings:

1. Collect all findings with confidence ≥80 from all agents
2. Dispatch a code-reviewer agent (with correctness lens) to independently verify each finding:
   - For each: read the cited file:line, assess if the issue is real
   - Rate: CONFIRMED / DISPUTED / INCONCLUSIVE
3. Surface only CONFIRMED findings as blocking issues
4. List DISPUTED findings as informational (non-blocking, FYI only)
5. Discard INCONCLUSIVE findings

This step prevents quality gate fatigue from false positives.

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
