# Experiment: parallel-work streams (#104 → #110)

**Status:** under evaluation. NOT merged to `main`, NOT part of any release.

This branch carries @albertsanz's draft #110 (Sep 7), the implementation of
feature issue #104, brought up to date with `main` (2026-09-23). #110 was
stacked on #103, which landed on `main` separately (squash `7029e40`), so
the parallel-work scripts here are #110's versions (a superset of #103).

## What it adds

Parallel streams get a single source of facts and a closed verdict vocabulary.
Five scripts compute every git fact and print fixed lines (`GATE`, `MERGE:`,
`SYNC:`, `CLEANUP:`) for the skills to route on. The model never interprets
git's error text. Streams open as named sessions, and four fixed hints (HELLO,
MERGED, BYE, NOTE) tell the other terminals what landed. A hint never
approves, runs or decides anything. Every refusal is a script exit code with a
named reason.

- parallel-work 3.0.1 → **4.0.0** (breaking: `EXOSUIT_WORKTREE_LAUNCH_CMD` is now the base command), merge-up 1.0.0 → 2.0.0, merge-down → 1.1.0, sprint-start 2.8.0, sprint-end 2.11.0
- new scripts: `worktree-status.sh --porcelain|--me|--gate …`, `merge-up-run.sh`, `stream-cleanup.sh [--apply]`
- hooks: WorktreeCreate arm and the inert `worktree-bash-fix` removed; `Stream:` banner on SessionStart
- tests: `test-parallel-work-scripts.sh` + `test-parallel-work-launcher.sh`; `run-all.sh` reports every failing file
- CI: shellcheck widened to hook libs, tests and every skill script
- human docs: `docs/reference/PARALLEL_WORK.md`

Most of #104's proposed mechanisms were **dropped on measurement**: the merge
token, the claims registry with its per-edit hook, the JSON message protocol
and the flow cursor. The reasons are in #110's PR body.

## Decisions for the maintainer (from #110)

1. **Launcher default:** plain `claude` (as #104 promised), or bypass-mode streams?
2. **`.mcp.json` in `.gitignore.framework`:** make it the default for new projects?
3. **Shape:** one PR, or six groups (fixes, fact source, merge runner, skills, integration/docs, CI lint)?
4. **Provenance:** the PR notes the design was first developed on a private
   engagement running this framework (JD-LLM era). Every file was written fresh
   from a behavioural spec under MIT, and no code was copied.

## Not verified (per #110)

- Terminal.app, Windows Terminal, WSL, Git Bash, iTerm2, gnome-terminal and konsole launchers are only exercised through stubs.
- Cross-session messaging behaviour is taken from the docs, not exercised.
- Commits in the middle of the stack are red until the full test harness lands.

## Verification (2026-09-23, Linux, after merging main)

- hook suite: **459 assertions, 0 failures** (exit 0), incl. parallel-work scripts 222/0 and launcher 55/0
- `validate-skills.sh`: 45 skills, 427 passed, **0 failures**; registry 45 entries, no duplicates, versions match SKILL.md
- CI's widened `shellcheck -S error` (hooks, libs, tests, all skill scripts, install.sh): clean
