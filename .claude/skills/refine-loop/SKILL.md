---
name: refine-loop
version: 2.5.0
description: Use when the user wants iterative self-improvement on a deliverable (document, implementation, prompt, design) until completion criteria are met.
trigger: manual
depends-on: []
references: []
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Edit, Write
argument-hint: ""<task>" --until "<criteria>" [--max <N>] [--autonomous]"
---
______________________________________________________________________

## refine-loop

Refining: **$ARGUMENTS**

## Argument Parsing

| Argument | Required | Default | Description |
|----------|----------|---------|-------------|
| `<task>` | Yes | - | What to produce or improve |
| `--until "<criteria>"` | Yes | - | Completion condition (must be verifiable) |
| `--max <N>` | No | 5 (50 if `--autonomous`) | Maximum iterations before stopping |
| `--autonomous` | No | false | Extended unattended mode: higher iteration cap, TSV logging, diminishing-returns auto-stop |

## Failure State Persistence

At loop entry, write `docs/sessions/.failure-state.md` with YAML frontmatter so the Stop hook and `/continue` can programmatically detect incomplete workflows.

**At loop entry** (before first execution):

```yaml
---
status: active
skill: refine-loop
phase: "1"
phase_name: "Initial Execution"
started_at: "[ISO-8601 timestamp from date -u +%Y-%m-%dT%H:%M:%SZ]"
story: "[from $ARGUMENTS — the task description]"
branch: "[from git branch --show-current]"
next_action: "Execute task and produce first draft"
autonomous: [true|false]
files_modified: []
---

## Context
Task: [task description]
Criteria: [completion criteria]
Iteration: 1 of [max]
Mode: [standard | autonomous]
```

**At each iteration:** Update `phase` to the iteration number, `phase_name` to `"Iteration N"`, `next_action` to the specific improvement being applied, and append to `files_modified`. Update the Context section with iteration progress and remaining gaps.

**When criteria are met (or max iterations reached):** Delete `.failure-state.md` — clean state means no failure to recover from.

## Process

### 1. Initial Execution

Execute the task to produce the first draft/version.

**If `--autonomous`:** Initialize the iteration log file:
```
docs/sessions/.refine-log.tsv:
iteration	criteria_met	criteria_total	gap_description	action_taken	timestamp
0	0	<total>	Initial execution	Produced first draft	<ISO-8601>
```

### 2. Self-Review Against Criteria

Evaluate the current output against the completion criteria. For each criterion:
- **MET**: Criterion is satisfied with evidence
- **NOT MET**: Criterion fails — identify the specific gap

### 3. Decision Point

```
[All criteria MET?]
  → YES: Output final result → DONE
  → NO: [iterations < max?]
    → YES: Identify SPECIFIC improvements → Apply → Go to step 2
    → NO: Output best result + remaining gaps → DONE
```

**Autonomous mode additional check:** Before continuing to next iteration, check for diminishing returns (see Diminishing Returns Detection below).

### 4. Iteration (if continuing)

Each iteration MUST:
1. **Name the gap**: What specific criterion is not met?
2. **Describe the fix**: What concrete change will address it?
3. **Apply the fix**: Make the change
4. **Re-evaluate**: Check ALL criteria again (not just the one fixed)

<HARD-GATE>
Each iteration must identify SPECIFIC improvements with concrete descriptions. "Make it better" or "improve quality" are NOT valid improvement descriptions. If you cannot name a specific gap, the loop is done — output the current result.
</HARD-GATE>

**If `--autonomous`:** After each iteration, append to `docs/sessions/.refine-log.tsv`:
```
<iteration>	<criteria_met_count>	<criteria_total>	<gap_addressed>	<action_taken>	<ISO-8601>
```

### 5. Completion Report

```markdown
### Refinement Complete

**Task:** [description]
**Completion criteria:** [criteria]
**Iterations:** X of Y max
**Mode:** [standard | autonomous]
**Status:** [All criteria met / Stopped at max / No further improvements identified / Stopped: diminishing returns]

**Iteration log:**
1. [What was changed and why]
2. [What was changed and why]
...

**Remaining gaps (if any):**
- [Gap]: [Why it couldn't be resolved]
```

## Diminishing Returns Detection (Autonomous Mode)

When `--autonomous` is active, track progress across iterations:

**Trigger:** 3 consecutive iterations where `criteria_met` count does not increase.

**Action:**
1. Print: "Diminishing returns: 3 consecutive iterations with no criteria progress."
2. Attempt ONE strategy shift — try a fundamentally different approach to the remaining gaps
3. If the next iteration ALSO shows no progress: stop the loop early
4. Report: "Stopped early: diminishing returns after [N] iterations"

**Why this exists:** In autonomous mode, the iteration cap is high (50). Without diminishing-returns detection, the loop could spend 40+ iterations making no meaningful progress. This auto-stop preserves context budget for productive work.

## Safety

- Default `--max 5` prevents runaway loops (raised to 50 only with explicit `--autonomous`)
- Each iteration must make measurable progress — if an iteration doesn't change anything, stop
- If the same gap persists after 2 attempts, flag it as potentially unresolvable and move on
- The loop produces a completion report regardless of how it ends
- **Autonomous mode:** Diminishing-returns detection auto-stops after 3+ consecutive no-progress iterations

## When to Use

- Polishing documentation (architecture docs, READMEs, ADRs)
- Iterating on prompt/skill content
- Refining complex implementations with multi-faceted quality criteria
- Any task where "good enough on first try" is unlikely
- **With `--autonomous`:** Long-running refinement tasks (test suite generation, comprehensive documentation, prompt optimization) where extended unattended iteration is acceptable

## When NOT to Use

- Simple one-shot tasks (just do them directly)
- Tasks without clear completion criteria
- During story-cycle execution (use the story-cycle's own phases instead)
- **`--autonomous` specifically:** When each iteration requires human judgment or approval
