# Experiment: /live-test skill (#92)

**Status:** under evaluation. NOT merged to `main`, NOT part of any release.

This branch carries @albertsanz's `/live-test` skill (#93 → #95) on top of `main`,
plus security fixes. #96 adds a flow contract for the skill and depends on the
flow-contracts ladder — it belongs on `experimental/flow-contracts` once both
are accepted.

## What it adds

An autonomous dynamic-testing skill: plans a scoped run (user-approved at a hard
gate), drives the app's declared surface (web via browser MCP, HTTP API via curl,
or CLI), verifies each scenario on multiple signals, optionally fixes critical
bugs in a bounded loop, and writes append-only findings. Project facts live in a
project-owned `docs/testing/APP_MAP.md`; `preflight.sh` gates execution on stack
health.

**It fills a real gap.** `/manual-test` writes a plan and stops. `/UAT-cycle`
supervises a human. `/testing-cycle` processes one feedback string.
`/claude-sense-check` is code-only. The `integration-tester` agent flags
un-runnable ACs as UNTESTABLE — literally naming this hole. Nothing else drives a
running app. Browser control is MCP-only in Claude Code, so routing through
Playwright MCP with a documented fallback integrates with the native path rather
than reimplementing it.

## Security fixes applied on this branch

- **Scheme-less URL bypass closed.** The `cmd` localhost gate only inspected
  words starting with `http(s)://`, but curl and wget default to `http://`, so
  `curl evil.example.com/beacon` executed while `curl http://evil.example.com`
  was refused. Verified closed; local checks still pass.
- **Predictable temp paths replaced with `mktemp`** — `/tmp/live-test-body.json`
  and `/tmp/lt-health.json` were symlink-clobberable and collided between
  concurrent worktree runs.
- **Secrets caveat documented** where response bodies are excerpted into findings.
- `preflight.sh` mode `100644` → `100755`, matching every other skill script.

## Open decisions — maintainer's call, NOT made here

These are design changes, not defects; each needs a product decision.

1. **"Localhost" is not "safe".** Nothing asks what the app is *connected to*. A
   dev server on `localhost:8000` can hold a shared-staging `DATABASE_URL`, a
   live Stripe key, a real SMTP credential — while the skill is instructed to run
   create/update/**delete** sequences and to repeat mutating requests to test
   double-submit. Recommended: a required app-map field (e.g.
   `data_environment: disposable|shared`) that preflight refuses to run without,
   with `shared` blocking mutating scenarios. **This is the most important one.**
2. **The app map executes arbitrary shell before any user gate.** `preflight.sh`
   runs `sh -c` on every `cmd` line at step 0.3; the plan gate is at step 2, and
   the prose tells the model "black box — run, don't read". `APP_MAP.md` is a
   committed file, so cloning a repo and typing `/live-test` is arbitrary code
   execution — with `Bash` auto-approved via `allowed-tools`. Verified by
   execution. Recommended: print every `cmd` target verbatim and confirm once per
   map-hash, or drop `cmd` in favour of `http`/`compose`.
3. **The fix loop is opt-out, not opt-in.** It edits source and commits up to 3×
   without a human gate; the plan gate approves *scenarios*, not fixes. A
   misclassified local misconfiguration can leave spurious commits. Recommended:
   make fixing `--fix` rather than `--no-fix`.
4. **Evidence commits can leak credentials.** Findings are committed, the first
   API scenario authenticates for real, and response bodies/screenshots are
   excerpted — but `post-edit-format.sh`'s secrets scanner skips `.md`/`.txt`,
   which are exactly live-test's output formats. Principle 13 has a blind spot
   shaped like this skill.
5. **No destructive-operation guard on web/API.** The CLI guide has a good one;
   the API guide actively prescribes DELETE and the web guide is unguarded.
6. **MCP tools cannot be auto-approved.** `allowed-tools` has no `mcp__*` entries
   (this would be the repo's first), so a web run prompts on every browser call.
7. **Nothing actually starts the app**, contrary to #92's headline — and the
   "read `dev:`, run in background" block now exists in four places
   (`build`, `sprint-end`, `story-cycle`, and here as prose). Extract a shared
   prompt snippet.
8. Findings-classification tables are triplicated across `/UAT-cycle`,
   `/testing-cycle` and here — refactor target, not a blocker.

## Verification on this branch

- hook suite: 12 suites, **0 failures** (exit 0)
- `validate-skills.sh`: 46 skills, 435 passed, **0 failures**; the one new
  warning is live-test's 178-line SKILL.md over the 150-line budget (20 other
  skills also exceed it)
- localhost gate: 17 hostile URL spoofs all fail closed; scheme-less bypass
  verified closed by execution
