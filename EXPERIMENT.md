# Experiment: flow contracts (#77)

**Status:** under evaluation. NOT merged to `main`, NOT part of any release.

This branch carries @albertsanz's 10-PR flow-contracts ladder (#79 → #88) on top
of `main`, plus review fixes. The bug-fix PRs that were stacked on the ladder
(#90, #91) were extracted and shipped separately in #97 — they are already on
`main` and are not what this branch is for.

## What the ladder adds

| Level | PR | What |
|---|---|---|
| L1-L3 | #79, #81 | `FLOW_SPEC.md` + `flow.yaml` grammar, `validate-flows.sh`, first contracts |
| L4 | #82 | flow cursor — resume state riding `.failure-state.md` |
| L5 | #83 | gate evidence + advisory/blocking enforcement hook |
| L6 | #84 | generated `flow.generated.md` views with CI staleness check |
| adopters | #85-#88 | contracts for bootstrap, discover, brainstorm, ideate |

A `flow.yaml` is **declarative only — never executed**. A skill without one
behaves byte-identically to today.

## Review fixes applied on this branch

- **graph-state.sh anchored to the git root** — it wrote a stray
  `docs/sessions/` into whatever directory was current (the T01-001 class).
- **`clear` no longer told at failure terminals** — the instruction destroyed
  story-cycle's `save-failure-state`, the file `/continue` resumes from.
- **The advisory now actually reaches someone** — PreToolUse exit-0 stderr is
  debug-log only, so the default advisory mode was invisible to both model and
  user. Now emits `additionalContext` + `systemMessage`, still non-blocking.
- **validate-flows.sh rejects typo'd attribute keys** where the vocabulary is
  closed (`faill:` used to resolve as a phantom edge).
- **render-flow.sh distinguishes MISSING from STALE** and prints the full command.
- **story-cycle's parallel path now takes the 3.pre checkpoint**, so a parallel
  run can still use the 4d `[R]` rollback.

## Open decisions — maintainer's call, deliberately NOT made here

1. **Does the ladder ship at all, and in what order?** L1-L3, L4 and L6 reviewed
   well. **L5 (#83) is the weak rung** and is why this is one branch rather than
   a merge queue — see below.
2. **L5 evidence coverage.** `tests-green` cannot be produced by several major
   runners (Go, minitest, phpunit, mix, rake). In `EXOSUIT_FLOW_MODE=block`
   that is a valveless deadlock: every source edit is refused with a remedy the
   user cannot satisfy. Block mode is opt-in and off by default, so this is not
   live — but it must be fixed before block mode is ever recommended. Options:
   fail open on an unrecognised runner, or add an iteration valve like stop.sh's.
3. **L5 evidence integrity.** The stamp is a substring match on the command, so
   `echo pytest` stamps `tests-green`; a partial run stamps suite-wide green; a
   collection error does not revoke. Fine for an advisory nudge, wrong for
   anything called "deterministic" — FLOW_SPEC's wording should be softened, or
   the stamping tightened.
4. **L5 cost.** `flow-pre-edit.sh` runs on every Edit/Write (~100 ms with no
   cursor, ~15 processes). Cheap short-circuit: test for the cursor file before
   spawning hook-guard and git.
5. **Inline-test languages.** Rust `#[cfg(test)]` and Elixir doctests put tests
   *in* the source file, so a `test-written` gate in block mode blocks the
   TDD-correct action. Needs a documented carve-out.
6. **#80 is still open.** The contracts are a *fifth* description of
   story-cycle's flow. They make drift CI-detectable, but reconciling the four
   existing copies is still a decision only the maintainer can make; once made,
   `flow.generated.md` should replace the hand-drawn ASCII diagram.
7. **Timing vs the pre-launch overhaul.** Contracts pin ~380 SKILL.md heading
   lines. During a large skill rewrite the validator turns every renamed heading
   into a CI failure — a safety net or a drag depending on the plan.

## Verification on this branch

- hook suite: **267 assertions, 0 failures** (exit 0), macOS
- `validate-flows.sh`: **379 passed, 0 warnings, 0 failures** across 7 contracts
- `render-flow.sh --check`: current (7 flows)
- `validate-skills.sh`: 421 passed, **0 failures**; warning set unchanged vs main
- `shellcheck -S error`: clean on every changed script

CI has never run on the original PR branches (first-time-contributor approval was
pending), so the ubuntu leg is unproven for the ladder until this branch is pushed.
