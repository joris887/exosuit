---
name: optimize
version: 1.0.0
description: Use when the user wants to autonomously improve a measurable metric through iterative experimentation with git-based checkpointing and automatic rollback.
trigger: manual
depends-on: []
references: [references/experiment-protocol.md]
micro-components:
  baseline: [discover-commands, verify-clean-git-state]
  experiment: [grep-first-explore, record-failure]
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Bash, Edit, Write
argument-hint: "\"<goal>\" --metric \"<command | grep pattern>\" --target <N> [--direction min|max] [--max <iterations>]"
---
______________________________________________________________________

## optimize

Optimizing: **$ARGUMENTS**

## Argument Parsing

| Argument | Required | Default | Description |
|----------|----------|---------|-------------|
| `<goal>` | Yes | - | What to optimize (e.g., "increase test coverage", "reduce bundle size") |
| `--metric "<command>"` | Yes | - | Shell command that outputs the metric value. Pipe through grep if needed to isolate the number |
| `--target <N>` | Yes | - | Target value to reach |
| `--direction min\|max` | No | `max` | Whether to minimize or maximize the metric |
| `--max <N>` | No | 20 | Maximum experiments before stopping |

**Examples:**

```
/optimize "increase test coverage" --metric "npm test -- --coverage 2>&1 | grep 'All files' | awk '{print $10}'" --target 90 --direction max
/optimize "reduce bundle size" --metric "npm run build 2>&1 | grep 'gzipped' | awk '{print $3}'" --target 150 --direction min --max 30
/optimize "eliminate lint warnings" --metric "npm run lint 2>&1 | tail -1 | grep -oE '[0-9]+ problems'" --target 0 --direction min
```

## Failure State Persistence

At loop entry, write `docs/sessions/.failure-state.md`:

```yaml
---
status: active
skill: optimize
phase: "baseline"
phase_name: "Baseline Measurement"
started_at: "[ISO-8601 timestamp]"
story: "[goal from $ARGUMENTS]"
branch: "[from git branch --show-current]"
next_action: "Measure baseline metric"
files_modified: []
---

## Context
Goal: [goal]
Metric command: [command]
Target: [target] (direction: [min|max])
Max experiments: [max]
Current experiment: 0
Best value: [pending]
```

Update at each experiment iteration. Delete when optimization completes or max experiments reached.

## Process

### 1. Pre-Flight

Run `verify-clean-git-state` micro-component. Confirm:
- Working tree is clean (no uncommitted changes)
- On a feature branch (not main/master)
- Git is available

<HARD-GATE>
Do NOT proceed with uncommitted changes. The experiment loop uses `git reset --hard` — uncommitted work WILL be lost. Stash or commit first.
</HARD-GATE>

### 2. Baseline Measurement

Run the metric command and parse the current value:

```bash
# Run the user's metric command
RESULT=$(<metric-command>)
```

Parse a numeric value from the output. If parsing fails, show the raw output and ask the user to refine the `--metric` command.

Record baseline:
```
docs/sessions/.optimization-log.tsv:
commit	metric_value	delta	status	description	lines_added	lines_removed
<hash>	<value>	0	baseline	Starting point	0	0
```

Print:
```
Baseline: <value>
Target: <target> (direction: <min|max>)
Gap: <difference>
Max experiments: <max>
```

### 3. Experiment Loop

```
LOOP (experiment = 1 to max):
  3a. Analyze → 3b. Implement → 3c. Commit → 3d. Measure → 3e. Decide → 3f. Log

  EXIT when:
  - Target reached
  - Max experiments exhausted
  - 3 consecutive experiments with no improvement (diminishing returns)
  - No more improvement ideas identified
```

### 3a. Analyze & Propose

Study the codebase for the next improvement opportunity. Use `grep-first-explore` to find relevant code.

Consider:
- What specific change could move the metric toward the target?
- Can this be achieved by **removing or simplifying** code? (Prefer this)
- What's the expected impact on the metric?
- What's the risk of regression?

**Simplicity preference:** If two approaches could achieve similar metric improvement, prefer the one that removes code over the one that adds code. Simpler solutions are more maintainable and less likely to introduce bugs.

Print a one-line proposal before implementing:
```
Experiment <N>: <brief description of the change>
```

### 3b. Implement

Make the code change. Keep changes focused — one idea per experiment. Do NOT combine multiple unrelated changes in a single experiment (makes it impossible to attribute metric movement).

### 3c. Commit (Checkpoint)

Stage and commit the change as an experiment checkpoint:

```bash
git add -A
git commit -m "experiment: <brief description>"
```

This commit exists so we can cleanly rollback if the metric regresses.

### 3d. Measure

Run the metric command again. Parse the new value.

**Crash handling:** If the metric command fails (non-zero exit, no parseable output):

1. Read the last 50 lines of output for error diagnosis
2. Attempt ONE fix (typo, missing import, syntax error)
3. If fix works: re-measure
4. If fix fails: mark as `crash`, rollback, continue to next experiment

```bash
# If command fails or output isn't parseable:
git reset --hard HEAD~1  # Rollback the experiment
# Log as crash, continue loop
```

### 3e. Decide: Keep or Discard

Compare new metric value against the best value so far:

```
IF (direction == max AND new_value > best_value) OR
   (direction == min AND new_value < best_value):
  → KEEP: Branch advances. Update best_value.
ELSE:
  → DISCARD: git reset --hard HEAD~1
```

**Important:** Compare against **best value**, not baseline. The frontier only advances.

Print decision:
```
Experiment <N>: <description>
  Result: <new_value> (was: <best_value>, delta: <change>)
  Decision: KEEP ✓ / DISCARD ✗
  [If KEEP: New best: <new_value>, gap to target: <remaining>]
```

### 3f. Log

Append to `docs/sessions/.optimization-log.tsv`:
```
<commit-hash>	<metric_value>	<delta_from_best>	<keep|discard|crash>	<description>	<lines_added>	<lines_removed>
```

Lines added/removed from `git diff --stat HEAD~1` (for kept experiments) or from the discarded diff.

### 4. Diminishing Returns Detection

Track consecutive non-improvements. If 3 experiments in a row are discarded (no metric improvement):

1. Print: "3 consecutive experiments without improvement."
2. Consider a **different approach category** — if you've been tuning parameters, try restructuring; if restructuring, try a different algorithm
3. If the next experiment also fails: stop the loop early
4. Report: "Stopped early: diminishing returns after <N> experiments"

### 5. Completion Report

```markdown
### Optimization Complete

**Goal:** [description]
**Metric:** [command]
**Direction:** [min|max]

**Results:**
- Baseline: [initial value]
- Final: [best value]
- Target: [target value]
- Improvement: [delta] ([percentage]%)
- Target reached: [Yes/No]

**Experiments:** [total] run, [kept] kept, [discarded] discarded, [crashed] crashed

**Experiment Log:**
| # | Description | Value | Delta | Status |
|---|-------------|-------|-------|--------|
| 0 | Baseline | ... | — | baseline |
| 1 | ... | ... | ... | keep/discard |

**Simplicity:** Net code change: +[added] / -[removed] lines ([net] net)

**Remaining gap (if target not reached):**
- [What else could be tried]
- [Why further improvement may be difficult]
```

## Safety

- **Git safety:** Every experiment is a commit. Discards use `git reset --hard HEAD~1`. Only the latest uncommitted experiment can be lost on crash — all previous kept experiments are safe in git history.
- **Working tree guard:** Hard gate prevents starting with uncommitted changes.
- **Crash isolation:** Failed metric commands trigger at most one fix attempt before rollback.
- **Diminishing returns:** Auto-stop after 3+ consecutive failures prevents infinite loops.
- **Branch protection:** Pre-flight checks refuse to run on main/master.
- **Max cap:** Default 20 experiments, configurable up to any limit.

## When to Use

- Improving test coverage toward a target percentage
- Reducing bundle size, build time, or binary size
- Eliminating lint warnings or type errors
- Optimizing benchmark scores (latency, throughput)
- Any task with a clear numeric metric and a target value

## When NOT to Use

- Tasks without a measurable, command-line-accessible metric
- Subjective quality improvements (use `/refine-loop` instead)
- During story-cycle execution (use story-cycle's own phases)
- On main/master branch (create a feature branch first)

## Relationship to Other Skills

- **`/refine-loop`** — Criteria-based iteration (subjective). Use `/optimize` when you have a measurable metric; use `/refine-loop` when quality is assessed by inspection.
- **`/story-cycle`** — Story delivery workflow. `/optimize` is a standalone tool for metric improvement, not part of the sprint workflow.
- **`/undo-work`** — Manual rollback. `/optimize` handles its own rollback automatically via git checkpoint/reset.
