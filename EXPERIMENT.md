# Experiment: v5 brain (#43, #44)

**Status:** dormant. Rolled back from `main` on 2026-05-27, NOT part of any
release. The pre-merge state is tagged `v5-brain-experiment`.

This branch carries the v5.0 "outcome-driven framework" (#43) and the bootstrap
Path B fix (#44). It was brought up to date with `main` on 2026-09-23: the
Exosuit rebrand, the parallel-work suite, telemetry fixes, installer and hook
fixes, and the cohesion-sizing sweep.

## What it adds

- `docs/brain/`: an LLM-maintained source of truth (index, log,
  current-state, 7 stable pages, a file:line citation on every claim).
  `/brain-update` is the only writer; /story-cycle, /sprint-end, /brainstorm,
  /ideate and /discover call it.
- Outcome-first stories: stable Outcome + Verification sections. Implementation
  Hints are stale by default and re-refined against the brain at
  `/sprint-start` step 3.5.
- AC coverage replaces test-count enforcement.

## How the 2026-09-23 merge was resolved

- **Kept from the experiment:** story format, sizing, the `/brain-update` call
  sites, and the higher v5 skill versions.
- **Taken from `main`:** rebrand naming (no JD-LLM strings left except bootstrap's
  deliberate legacy-name detection), the rewritten README, research 1.0.1, all
  hook and installer fixes.
- **Kept both:** where `main` added skill completion events next to a
  `/brain-update` call (brainstorm, ideate).

## ⚠ Open decision 1: two sizing policies now coexist

The experiment sizes stories by **verification budget**: TRIVIAL/STANDARD/LARGE,
3-7 AC, PR ≤500 LOC. `main` has since adopted **cohesion sizing** (#97):
TRIVIAL/SMALL/STANDARD/LARGE/XL, "file count is never a threshold". In
conflicted files the experiment's policy was kept. Files the experiment never
touched came in from `main` with the cohesion policy.

- **Cohesion:** `SKILLS_INVENTORY.md`, `backlog-review`, `build`,
  `architecture-reviewer` and `spec-reviewer` agents,
  `scaffold/docs/reference/STORY_SIZING.md`, `TEAM_WORKFLOW.md`
- **Verification budget:** `ideate` + `story-template.md`, `story-cycle`,
  `rules/git.md`, `GIT_WORKFLOW.md`, `foundation-backlog.md`,
  `story-template-lightweight.md`

If the brain is revived, pick one policy and sweep the other set.

## Other open decisions

2. The direction for the brain work itself: cherry-pick, abandon, or redo.
3. README no longer mentions `docs/brain/`. `main`'s rewrite replaced the
   architecture block the experiment had edited.

## Verification (2026-09-23, Linux, after merging main)

- hook suite: **160 assertions, 0 failures** (exit 0)
- `validate-skills.sh`: 46 skills, 437 passed, **0 failures**
- registry: 46 entries for 46 skill directories, every version matches SKILL.md
- `shellcheck -S error`: clean
