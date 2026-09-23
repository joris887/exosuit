# Experiment: /live-test skill (#92)

**Status:** under evaluation. NOT merged to `main`, NOT part of any release.

This branch carries @albertsanz's **restacked** `/live-test` series (Aug 23),
brought up to date with `main` (2026-09-23):

| Part | PR | What |
|---|---|---|
| 1/4 | #93 | driving references: web (browser MCP), API (curl), CLI, recovery, first-run |
| 2/4 | #94 | map-driven `preflight.sh` + app-map template |
| 3/4 | #95 | skill entry, findings template, registration |
| 4/4 | #96 | live-test's own flow contract (36 nodes) + generated view |

**Part 4 depends on the flow-contracts main line (#79 → #88, without L5), so
this branch contains that ladder too.** To take live-test without flow
contracts, merge #95's tip (`d18fa71`) instead.

The restack superseded the Aug 20 version of this branch. Both Aug 20 security
fixes (the scheme-less URL bypass, predictable temp paths) are in Albert's
commits with authorship kept. The Aug 20 history is still reachable as the
first parent of the 2026-09-23 merge.

## What it adds

An autonomous dynamic-testing skill. It plans a scoped run behind a hard user
gate, drives the app's declared surface, checks each scenario on several
signals, optionally fixes critical bugs in a bounded loop, and writes findings.
Project facts live in a project-owned `docs/testing/APP_MAP.md`.
Nothing else in Exosuit drives a running app: `/manual-test` writes a plan,
`/UAT-cycle` supervises a human, and `integration-tester` marks such ACs
UNTESTABLE.

## What happened to the Aug 20 open decisions

| # | Decision | Albert's restack |
|---|---|---|
| 1 | "Localhost is not safe" | **Required `data_environment: disposable \| shared`.** Preflight refuses to run without it; `shared` arms a MUTATION LOCK (read-only scenarios only). The first-run interview defaults to `shared` when unsure. |
| 2 | App map runs shell before any gate | **Per-clone cmd approval.** Preflight prints every `cmd` verbatim, exits 3 having run nothing, and only `--approve-cmds <hash>` runs them. The approval is stored in gitignored `.claude/hooks/state/`, so it can't be committed for others, and it's invalidated when the map changes. |
| 3 | Fix loop opt-out | **Opt-in `--fix`**; without it every Critical becomes a handoff. The plan gate states "Fix loop: authorized \| report-only". |
| 4 | Credentials in findings | Mandatory redaction step before the findings commit plus a self-check grep. The `post-edit-format.sh` `.md` skip is still yours. |
| 5 | No destructive-op guard on web/API | Web and API guides now carry the CLI guide's rule. |
| 6 | MCP prompting | Playwright tools listed in `allowed-tools`, **excluding** `browser_evaluate` and `browser_run_code_unsafe`. |
| 7 | "Starts the app" | Text now says preflight verifies a running stack and never launches it. The shared dev-launch snippet is still yours. |
| 8 | Triplicated findings tables | Left for your refactor. |

Albert also found two defects in the Aug 20 gate fix and fixed both:
- **False positives:** `pip install -r requirements.txt` and `git add .` were refused as URLs.
- **Missed hosts:** dotless and decimal/hex hosts (`curl evilbox`, `curl 0xdeadbeef`) went through.

Bare-host scanning is now scoped to curl/wget. The URL check is framed as an
accident-catcher; the cmd approval is the security boundary.

## Remaining decisions (maintainer)

1. ~~With or without its flow contract?~~ **Decided 2026-09-23: ship with it.** Order: flow-contracts main line (#79 → #88) lands on `main` first, then #93 → #96 as one merge. Blocked only on the maintainer's hands-on test.
2. `post-edit-format.sh` secrets scan skips `.md`/`.txt`, which are live-test's output formats.
3. Extract the "read `dev:`, run in background" snippet shared with build/sprint-end/story-cycle.

## Verification (2026-09-23, Linux, after merging main)

- hook suite: **253 assertions, 0 failures** (exit 0)
- `validate-flows.sh`: ALL CONFORMANT (8 contracts); `render-flow.sh --check`: current (8 flows)
- `validate-skills.sh`: 46 skills, 438 passed, **0 failures** (new warning: live-test SKILL.md 203 lines > 150)
- `shellcheck -S error`: clean, including `live-test/scripts/*.sh`
- Gates exercised by execution against a scratch project:
  - missing `data_environment`: exit 1, nothing run
  - unapproved `cmd`: exit 3, nothing run, hash printed
  - approved hash: runs
  - map edited after approval: exit 3 again
  - `curl evil.example.com/beacon`: refused even after approval
  - `shared`: MUTATION LOCK printed
