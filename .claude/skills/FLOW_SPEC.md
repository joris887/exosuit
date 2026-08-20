# Flow Contract Specification (`flow.yaml`)

**Spec version: 1** · Validated by `doctor/scripts/validate-flows.sh` · See issue #77

A flow contract is an optional, declarative description of a skill's control
flow — its steps, gates, branches, and loops — as a graph. It lives beside the
skill as `.claude/skills/<skill>/flow.yaml`.

**A flow contract is NOT executed.** Nothing changes at runtime. It serves as:

1. **The control contract the model reads** — one authoritative statement of
   the flow, instead of prose spread across sections that can drift apart.
2. **A drift detector** — the validator cross-checks every node's `doc` anchor
   against the skill's SKILL.md headings and fails CI on mismatch.
3. **A generator source** — flow diagrams can be generated from it instead of
   hand-maintained.

A skill **without** `flow.yaml` behaves byte-identically to today. Adoption is
opt-in per skill, following the STORY_SIZING precedent (4.2.0).

## File Format

A restricted, line-oriented subset of YAML — every file is valid YAML, but the
grammar is strict enough that POSIX `grep`/`sed`/`awk` parse it (the framework
has no yq/python dependency).

```yaml
# Comments are full-line only, starting with '#'
flow: sprint-start          # must equal the skill directory name
spec: 1                     # spec version this file conforms to
start: emit-start-event     # entry node id
nodes:
  emit-start-event: {type: step, next: read-profile, doc: "## sprint-start"}
  verify-clean-tree: {type: gate.hard, ok: sync-branch, fail: STOP, doc: "### 1b. Verify clean working tree"}
  branch-mode: {type: router, worktree: create-worktree, default: create-branch}
  done: {type: terminal, next_skill: story-cycle, doc: "## 4. Done"}
```

Grammar rules:

- Top-level keys `flow:`, `spec:`, `start:`, `nodes:` each on their own line.
- One node per line under `nodes:`, exactly two-space indented:
  `  <id>: {<attr>: <value>, ...}`
- Node ids are kebab-case: `[a-z0-9][a-z0-9-]*`.
- Values are bare words (node ids, `STOP`, skill names, numbers) except `doc`
  and `profile`, whose values are double-quoted strings. Lists use `[a, b]`.
- `STOP` is a pseudo-target: the flow halts and the user decides.

## Node Types

| Type | Required attrs | Optional attrs | Meaning |
|------|---------------|----------------|---------|
| `step` | `next` | | An action; proceed to `next` |
| `gate.hard` | `ok`, `fail` | `evidence` | Deterministic check; `fail` edge on violation (often `STOP`) |
| `gate.human` | `ok` | `fail` | User checkpoint/approval; `fail` = decline path |
| `router` | `default` + ≥1 named edge | | Conditional branch; edge keys name the conditions |
| `loop` | `back`, `done`, `max` | | Bounded retry: repeat via `back` at most `max` times, then `done` |
| `fanout` | `to` (list of ≥2 ids) | | Parallel branches (e.g. worktree streams, subagents) |
| `join` | `next` | `require` (default `all`) | Wait for fanout branches, then proceed |
| `terminal` | — | `next_skill` | Flow ends; `next_skill` documents the follow-up command(s) |

Gates may carry additional named edges beyond the required ones (e.g.
`user-override: <target>`) to document sanctioned bypass paths the prose
defines. A `router` may also express a bounded set of user choices when a
checkpoint offers more than approve/decline (edge keys name the options).

Every node may also carry:

- `doc: "<exact SKILL.md line>"` — the anchor tying the node to prose,
  typically the section heading (or the exact bold lead-in line for checks
  that live inside a section). The validator requires the quoted text to
  exist in SKILL.md as a whole line, character-for-character. **This is the
  anti-drift contract**: rename a heading without updating the flow (or vice
  versa) and CI fails.
- `profile: "<conditional>"` — profile-adaptive behavior, free text by
  convention `"lean: skip"` / `"strict: required"`. Documentation, not edges:
  the graph shows the standard-profile flow; profile attrs annotate deviations.

## Validation

`bash .claude/skills/doctor/scripts/validate-flows.sh [--verbose]` — run from
the repo root. Checks per flow file:

| # | Check | Level |
|---|-------|-------|
| 1 | `flow` matches the skill directory name | FAIL |
| 2 | `spec` is a supported version | FAIL |
| 3 | `start` resolves to a node | FAIL |
| 4 | Node lines parse; ids are kebab-case; no duplicates | FAIL |
| 5 | Node types are known; required attrs present per type | FAIL |
| 6 | Every edge target resolves to a node id or `STOP` | FAIL |
| 7 | `next_skill` values name existing skill directories | FAIL |
| 8 | At least one `terminal` node exists | FAIL |
| 9 | Every node is reachable from `start` | WARN |
| 10 | Every reachable node can reach a `terminal` or `STOP` (no trap regions) | FAIL |
| 11 | Cycles are bounded — evaluated per strongly-connected component: some node in the component carries `max` or is a gate | WARN |
| 12 | `doc` anchors exist verbatim as whole lines in SKILL.md | FAIL |
| 13 | Nodes lacking a `doc` anchor | WARN (summary) |

A project with zero `flow.yaml` files passes vacuously — the validator changes
nothing for skills that have not adopted flow contracts.

## Cursor & Resume

Skills with a flow contract keep a **flow cursor** — three additive keys in
the YAML frontmatter of the existing `docs/sessions/.failure-state.md`:

```yaml
flow: story-cycle    # which flow contract this run follows
node: write-plan     # the node currently executing
attempt: 1           # attempt count at this node (loops/retries)
```

Maintained via one-line calls to the helper (advisory, always exit 0 — a
cursor failure never breaks a skill):

```bash
sh .claude/hooks/lib/graph-state.sh enter <flow> <node>    # on node transition
sh .claude/hooks/lib/graph-state.sh attempt <flow> <node>  # on retry of the same node
sh .claude/hooks/lib/graph-state.sh clear <flow>           # at COMPLETION terminals only
```

Rules:

- The cursor stores the **(flow, node) pair** — node ids are unique per flow,
  not globally.
- **Branch-scoped**: readers (session-start's resume advisory, `/continue`)
  act on the cursor only when the file's `branch:` equals
  `git branch --show-current`. New worktrees inherit a verbatim copy of the
  file by design; the branch check makes an inherited cursor inert.
- **Ownership**: the cursor is a rider, never a squatter. If the file's
  `skill:` names a different skill, every verb is a silent no-op — another
  skill's interrupted state is never touched. If no file exists, `enter`
  creates a minimal one marked `cursor_owned: true`, and `clear` DELETES a
  cursor-owned file (a normal completed run leaves no phantom "interrupted
  workflow"); on skill-owned files `clear` strips only the cursor keys, and
  the owning skill's create/delete lifecycle is unchanged.
- Cursor reads and writes are **frontmatter-scoped**: free-form `## Context`
  body lines can never masquerade as a cursor. Corrupt files (frontmatter
  not opening at line 1 or missing its closing `---`) are left byte-for-byte
  untouched.
- The keys are additive: every existing consumer of `.failure-state.md`
  ignores them. Never name new frontmatter keys `skill:`, `phase_name:`, or
  `goal:` — those are parsed by stop.sh, pre-compact.sh, and status-line.sh.

## Gate Evidence & Enforcement

A `gate.hard` node may declare `evidence: <marker>` — a mechanically
observable fact the harness stamps into `.claude/hooks/state/flow/<marker>`
(per session, cleared at session start by session-start.sh):

| Marker | Stamped by post-tool-use.sh when |
|--------|----------------------------------|
| `test-written` | an Edit/Write touches a test path (patterns in `lib/test-paths.sh`, overridable via `test_path_patterns` in `rules/quality.conf` — the SAME list exempts those edits from gate checks, so a stamping edit can never itself be blocked) |
| `tests-green` | a test command's output shows a pass pattern AND no failure pattern — a mixed run never stamps, and a failing run revokes the marker (requires `jq`; without it the marker is unproducible and enforcement of such gates fails open) |

Evidence is **per-session by design** (cleared by session-start.sh): a
resumed session must re-produce evidence rather than trust last session's
runs. The advisory warns once per (flow, node, evidence), not on every edit.

Only mechanically checkable facts may be evidence — judgment gates
(`gate.human`, review quality, plan approval) are never enforced by machine.

`EXOSUIT_FLOW_MODE` controls what missing evidence does
(`off | advisory | block`; default derived from the project profile —
lean: `off`, standard/strict: `advisory`; **blocking is an explicit opt-in,
never a default**):

- **advisory** — flow-pre-edit.sh prints a one-line warning when a source
  file is edited while the cursor sits on an unevidenced `gate.hard`;
  nothing is ever blocked. Test/docs/config edits are always exempt
  (writing the test IS the evidence being asked for).
- **block** — the same condition blocks the edit (exit 2), and stop.sh
  refuses completion while a branch-matched cursor sits on a non-terminal
  node (bounded by the existing stop-iteration safety valve).

Kill switches: `EXOSUIT_FLOW_MODE=off` disables both checks;
`EXOSUIT_DISABLED_HOOKS=flow-pre-edit` disables only the edit-time check
(the stop-time check exists only in `block` mode, so any non-block mode
disables it). Everything fails open: no cursor, corrupt state, missing
flow.yaml, or any error means no warning and no block.

## Generated Views

`bash .claude/skills/doctor/scripts/render-flow.sh --write` generates
`flow.generated.md` beside each flow.yaml — a mermaid diagram plus a
grep-friendly edge table, marked GENERATED, byte-deterministic. Never edit
it; regenerate it. CI runs `render-flow.sh --check`, so a generated view can
never rot behind its flow.yaml — the drift class that motivated flow
contracts cannot re-emerge in the generated artifacts. Hand-maintained
diagrams inside SKILL.md prose are unaffected (reconciling those is #80's
territory).

## Authoring a Flow Contract

Transcribe what the prose **actually says today** — a flow contract is a
faithful 1:1 transcription, not a redesign. Improvements to the flow itself
are separate changes with their own review.

1. Read the full SKILL.md. Each numbered step/section that performs an action
   becomes a node. Merge trivial sub-steps into their parent node; keep every
   gate and branch explicit.
2. Early exits ("Do NOT proceed…", "stop and alert user") are `gate.hard`
   nodes with `fail: STOP`.
3. User checkpoints, approvals, and offers are `gate.human`.
4. `<IF>` blocks and argument forks (`--worktree`) are `router` nodes; purely
   profile-driven conditionals become `profile` attrs instead.
5. Bounded retries ("max 2 passes") are `loop` nodes. Unbounded retry cycles
   ("fix and re-run") are ordinary back-edges — the validator will WARN,
   which is a signal about the prose, not the transcription.
6. Copy `doc` anchors exactly — whole heading lines, character-for-character.
7. Run the validator. Fix FAILs; read WARNs — they often reveal real
   ambiguities in the prose worth fixing upstream in the skill itself.

## Relationship to SKILL.md

SKILL.md remains the instruction source the model executes. The flow contract
is the map of that territory: compact, checkable, and diffable. When the two
disagree, that is a bug — the validator exists to catch it at CI time instead
of letting the versions drift silently (story-cycle's flow is currently
described in four places that disagree; flow contracts end that class of bug
for adopting skills).
