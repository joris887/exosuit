# Quality Gates — Detailed Reference

Reference loaded by `/sprint-end` step 2. All gates must pass before proceeding.

## 2a. Tests

Run the project's test command (from CLAUDE.md Commands section). If the project has multiple test suites (e.g., backend + frontend), run all of them.

**If tests fail:** Stop. Fix failures first, then re-run `/sprint-end`.

## 2b. Test Protection

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

## 2c. Quality Agents

Run the following quality agents (forked context to keep main clean):

- **Code Quality Agent** (`/code-quality`): Complexity, duplication, patterns
- **Test Validator Agent** (`/test-validator`): Coverage, quality, TDD compliance

If auth/credentials/data/security files were changed:

- **Security Audit Agent** (`/security-audit`): Vulnerabilities, secrets, SQL injection

Present agent findings to user. If critical issues found, stop and fix first.

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
