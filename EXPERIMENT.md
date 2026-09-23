# Experiment: flow contracts (#77)

**Status:** under evaluation. NOT merged to `main`, NOT part of any release.

This branch carries @albertsanz's **restacked** flow-contracts ladder (Aug 23),
brought up to date with `main` (2026-09-23). The restack superseded the
Aug 20 version of this branch. Every review fix made here on Aug 20 is now
in Albert's commits at the rung it belongs to, with authorship kept, so
this branch's tree is his restack plus `main`. The Aug 20 history is still
reachable as the first parent of the 2026-09-23 merge.

## What the ladder adds

| Level | PR | What | Runtime change |
|---|---|---|---|
| L2 | #79 | `FLOW_SPEC.md`, `flow.yaml` grammar, `validate-flows.sh`, sprint-start/sprint-end contracts | none (declaration + CI) |
| L3 | #81 | story-cycle contract (70 nodes) | none |
| L4 | #82 | flow cursor: interrupted runs resume at the exact node | additive state keys, advisory resume hint |
| L6 | #84 | generated `flow.generated.md` views, CI staleness check | dev/CI only |
| adopters | #85-#88 | contracts for bootstrap, discover, brainstorm, ideate | none |
| **L5 (side rung)** | #83 | gate evidence + enforcement hook, opt-in | one PreToolUse Edit\|Write hook, advisory by default |

The main line is #79 → #88. **L5 (#83) sits on top as an opt-in side rung,
and this branch includes it**, so everything can be evaluated in one place.
To take the ladder without L5, merge #88's tip (`aef889c`) instead of this branch.

A `flow.yaml` is **declarative only, never executed**. A skill without one
behaves byte-identically to today.

## What happened to the Aug 20 open decisions

| # | Decision | Albert's restack |
|---|---|---|
| 1 | Ship order | Restacked so L5 is off the main line; merging bottom-up is unblocked. |
| 2 | L5 deadlock for unrecognised runners | **Fail-open by construction**: block mode acts only on *positive red evidence* (`tests-red` from a recognised runner that failed this session, revoked by the next green). Iteration valve too (`EXOSUIT_FLOW_MAX_BLOCKS`, default 3, then advisory). Runner patterns extended to go, minitest, phpunit, mix, rake, cargo, dotnet, swift. |
| 3 | L5 evidence integrity | "Deterministic" wording removed from FLOW_SPEC: markers are described as best-effort heuristics and block mode as a speed bump, not a boundary. Spoof guard added (`echo pytest - 12 passed` no longer stamps). |
| 4 | L5 cost on every edit | Checks for the cursor file with builtins before spawning anything, so zero processes when no flow is active. |
| 5 | Inline-test languages | Carve-out in `lib/test-paths.sh`: Rust `#[cfg(test)]`, Elixir doctests/ExUnit. |
| 6 | #80 story-cycle drift | **Still yours.** Suggestion: once contracts land, `flow.generated.md` replaces the hand-drawn ASCII diagram. |
| 7 | Timing vs the skill overhaul | Albert offers to maintain the anchors through the rewrite, or to merge L2-L4+L6 now and take the adopters skill by skill. |

Albert's review of the Aug 20 fixes found three problems, all fixed in the restack:
- The advisory's `permissionDecision: "allow"` **auto-approved** the edit it
  warned about. It now emits no permission decision.
- The closed edge-key vocabulary skipped `max`/`require`, and `evidnce:` typos
  passed silently. Both are now caught.
- `post-tool-use.sh` read `.tool_output` instead of `tool_response`. That is
  fixed on `main` since #100; this branch uses main's version.

## Remaining decisions (maintainer)

1. Merge the main line (#79 → #88) to `main`, all or bottom-up?
2. L5: ship as opt-in, or keep it experimental?
3. #80: which copy of story-cycle's flow is authoritative.

## Verification (2026-09-23, Linux, after merging main)

- hook suite: **350 assertions, 0 failures** (exit 0)
- `validate-flows.sh`: ALL CONFORMANT (7 contracts)
- `render-flow.sh --check`: current (7 flows)
- `validate-skills.sh`: 45 skills, 424 passed, **0 failures**
- `shellcheck -S error`: clean
