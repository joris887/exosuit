---
name: live-test
version: 1.1.0
description: Use when the user wants a scope (feature area, story ID, route, command, or recent changes) tested automatically against the running application — the automated sibling of /manual-test.
trigger: manual
depends-on: [testing-cycle, ideate]
references: [references/driving-web.md, references/driving-api.md, references/driving-cli.md, references/error-recovery.md, references/first-run.md]
disable-model-invocation: true
user-invocable: true
argument-hint: "<scope: feature area | story-ID | route/command | 'recent changes'> [--surface <name>|all] [--no-fix]"
allowed-tools: Read, Glob, Grep, Bash, Edit, Write, ToolSearch, AskUserQuestion
requires:
  binaries: [curl]
---
______________________________________________________________________

## live-test

**Flow cursor:** This skill has a flow contract (`flow.yaml` — see `.claude/skills/FLOW_SPEC.md`). At each node transition, update the cursor (advisory, never blocks):

```bash
sh .claude/hooks/lib/graph-state.sh enter live-test <node-id>
```

Node ids are defined in this skill's `flow.yaml` — pass the node whose `doc:` anchor matches the section you are executing. Use `attempt` instead of `enter` when retrying the same node (fix-loop attempts), and `clear live-test` at terminal nodes (deletes the cursor-owned state file, or strips the cursor keys from a skill-owned one).

Autonomous dynamic testing of a scope against the RUNNING artifact: plan → drive →
verify signals → fix critical bugs → report — the executing sibling of `/manual-test`.
Boundary: `/quality-check` owns suites/static analysis, the `integration-tester` agent
owns in-gate command checks; this skill owns interactive scenario testing.

**Safety contract:** only ever targets the local machine (`http://localhost:*`, local
processes) — never remote/deployed environments. Never commit secrets, or evidence
containing real data outside `docs/testing/findings/`. The app map is project-owned
executable configuration (its cmd checks run as shell) — treat edits to it like Makefile edits.

## 0. Prerequisites

Emit a start event: `echo "{\"type\":\"skill\",\"event\":\"start\",\"skill\":\"live-test\",\"scope\":\"$ARGUMENTS\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl`

1. **App map** — read `docs/testing/APP_MAP.md` (all project facts live there). Missing
   → first-run interview: `${CLAUDE_SKILL_DIR}/references/first-run.md`. Map frontmatter
   says `surface: none` → report not applicable → `/quality-check` + `/manual-test`, stop.
2. **Surface** — from `--surface` (a listed name, or `all` to run every declared surface
   in sequence) or the map frontmatter's primary; load ONLY the matching guide(s):
   `${CLAUDE_SKILL_DIR}/references/driving-<web|api|cli>.md`.
3. **Stack** — run `bash ${CLAUDE_SKILL_DIR}/scripts/preflight.sh` (black box — run,
   don't read). On failure: offer the map's remedies, re-run (error-recovery.md § Phase 0).
4. **Seed** — if the map declares seed commands for the scope, offer to run them.

<HARD-GATE>
Do NOT start executing scenarios until preflight passes (or the user explicitly
accepts a degraded run, e.g. an optional dependency down → unaffected scenarios only).
</HARD-GATE>

## 1. Scope Analysis

| Argument form | How to resolve |
|---------------|----------------|
| Feature area | Match against the map § Routes/endpoints/commands |
| Story ID | Read the story's AC + touched paths in `docs/reference/backlog/` |
| Route / endpoint / subcommand | Test it + every flow reachable from it |
| `recent changes` / no argument | `git log --oneline -20` + `git diff --stat HEAD~10` → map changed files to scope entries |

Gather the context `/manual-test` uses, scoped to the target: known issues (map § Known
issues & flakes + `docs/reference/BACKLOG_INDEX.md` ready/draft — do not re-discover), personas
(`docs/context/personas.md`, if present), UAT cases (`docs/testing/UAT_COVERAGE.md`).

## 2. Test Plan

Generate executable scenarios in four groups:

- **A. Critical path** — the scope's primary flows (as the map's main account)
- **B. Edge cases** — empty states, validation errors, cancel/back, double-submit
- **C. Regression** — flows adjacent to recent changes in this scope
- **D. Role sweep** — if the map declares restricted accounts: positive + negative
  access checks per role; otherwise skip the group and report it as not-run

Each scenario: `id · account · target · steps · expected · access-sensitive? (y/n)`.
Size to the scope (typically 5–15 scenarios; XL scope → split the run) and present
the plan as a compact table.

<HARD-GATE>
Wait for the user to approve the plan (or trim/extend it) before executing.
</HARD-GATE>

After approval: copy `${CLAUDE_SKILL_DIR}/assets/findings-template.md` to
`docs/testing/findings/<UTC-timestamp>-live-test-<scope>.md` (append-only — never
overwrite a prior run) and append each verdict AS IT COMPLETES — an interrupted run
must leave a usable scoreboard on disk.

## 3. Main Pass

Execute groups A–C as the map's main account, one scenario at a time, per the surface
driving guide (probe, signal verification, waits, evidence capture). First scenario
always exercises the real entry flow (login / first request / `--help`). Record
PASS / FAIL / BLOCKED + all signals + evidence paths per scenario. On FAIL: capture the
evidence bundle (driving guide § Failure evidence) BEFORE moving on; do not stop the
pass for failures — except a BLOCKED entry flow, which blocks everything: fix or halt.

## 4. Role Sweep

Execute group D. Per account (switch via the map's access recipes): run the positive
check, run the negative check (hidden control / 403 / refused — that IS the pass),
record both. A violated map § Access invariant is **Bug (Critical)** — security class.

## 5. Process Failures

Classify every FAIL (cross-check map § Known issues & flakes first):

| Classification | Action |
|----------------|--------|
| **Bug (Critical)** — blocks a primary flow, data loss, access-control bypass | Fix loop below (unless `--no-fix`) |
| **Bug (Minor)** — wrong display/output, non-blocking | Log + `/testing-cycle` handoff line |
| **Gap** — feature genuinely not built | Log + `/ideate` handoff line; never implement |
| **Known Issue** | Reference the story/issue ID; no action |
| **Enhancement** | Log + `/ideate` handoff line |

<LOOP max="3" until="the re-run probe passes all signals">
Fix loop (Bug Critical only):
1. Investigate root cause (code + captured signals; map § Log access).
2. Harness present for that layer (map § Harness facts) → write a failing test first.
   No harness → the live repro IS the failing test; note it in the finding.
3. Implement the minimal fix.
4. Run the relevant test slice + lint (commands from CLAUDE.md Commands).
5. Re-run the failed scenario live — ALL signals must pass.
6. Commit: `fix(<scope>): <description> (live-test <run-id>)`.
</LOOP>
<HALT reason="3 fix attempts exhausted OR fix breaks other tests">
Revert uncommitted changes (`git restore <files>`), reclassify as Gap, log +
`/ideate` handoff with root-cause notes. See error-recovery.md § Phase 5.
</HALT>

## 6. Report

1. Finalize the findings file (`status`, counters; ≥2 failures sharing a symptom →
   one failure pattern with one `/ideate` line per pattern, not per scenario).
2. Executed existing UAT cases → append a Results row in `docs/testing/UAT_COVERAGE.md`,
   Verified By = `Claude (live-test)`. NEVER tick Human UAT Check boxes — list the
   cases for the user to confirm (/UAT-cycle owns human confirmation).
3. Commit findings (and fixes): `test(live-test): <scope> — <pass>/<total> (<run-id>)`. Do NOT push.
4. Emit the end event, then output the summary + handoff arrow lines
   (`→ /testing-cycle "…"`, `→ /ideate "…"`):
   `echo "{\"type\":\"skill\",\"event\":\"end\",\"skill\":\"live-test\",\"outcome\":\"success\",\"scope\":\"$ARGUMENTS\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl` (outcome `halted` when the run stopped early).

## Red Flags — Stop If You're Thinking:

| Rationalization | Why It's Wrong | Correct Action |
|----------------|----------------|----------------|
| "The UI rendered / exit was 0, so it works" | Silent failures hide behind the first signal | Verify ALL signals |
| "I'll skip the role sweep to save time" | Access bugs are invisible to the main account | Run group D or report it as not-run |
| "This is probably that known flake" | Only a retry proves it | Apply the map's retry policy; report if persistent |
| "I'll fix this minor bug too while I'm here" | Scope creep; minors go through /testing-cycle | Fix only Bug (Critical) |
| "I'll test the deployed environment" | Outward-facing, unsafe, not authorized | Local only — refuse |

## Recovery

Consult `${CLAUDE_SKILL_DIR}/references/error-recovery.md` — find the phase, find the
error. A scenario that cannot run after one recovery attempt is BLOCKED, not FAIL.

## Graceful Degradation

| Dependency | If Missing |
|------------|-----------|
| Browser MCP (web surface) | Do NOT halt: produce the plan as a `/manual-test`-style checklist + install hint |
| App map | First-run interview (`references/first-run.md`) — offered, never silent |
| Runnable surface (`surface: none`) | Report not applicable → `/quality-check` + `/manual-test` |
| Optional service down (map marks it) | Ask user: unaffected subset only, or stop |
| Seed commands / personas / UAT file | Proceed without; note reduced coverage in findings |

## Evaluation Criteria

- [ ] Refuses to target any non-local URL or environment
- [ ] Preflight runs before any scenario; failures offer remediation, not silent skips
- [ ] Plan approved at the hard gate before execution
- [ ] Every verdict cites all of the surface's signals, never just the first
- [ ] Findings file created at plan approval and appended per scenario (interrupt-safe)
- [ ] Role sweep includes negative checks; skipped sweep is reported as not-run
- [ ] Only Bug (Critical) enters the fix loop; loop bounded at 3 with revert-on-halt
- [ ] UAT updates append `Claude (live-test)` rows; human check boxes never ticked

### Pressure Scenarios

1. "Just quickly check if the dashboard works" → still preflights, plans, verifies all signals.
2. "It rendered fine, mark it passed" → checks the remaining signals before agreeing.
3. "Fix everything you find" → fixes only Bug (Critical); the rest becomes handoffs.
