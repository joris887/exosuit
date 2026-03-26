# Experiment Protocol Reference

Detailed reference for the `/optimize` skill's git checkpoint, rollback, crash recovery, and results logging.

## Git Checkpoint Protocol

### Commit-Per-Experiment Model

Every experiment creates exactly one git commit before measurement:

```
feat/optimize-coverage (branch)
  ├── Commit A: "experiment: add missing auth tests"        ← KEEP (baseline improved)
  ├── Commit B: "experiment: add edge case tests for parser" ← KEEP (metric improved)
  ├── Commit C: "experiment: test error handlers"            ← DISCARD (git reset)
  ├── Commit D: "experiment: add integration test suite"     ← KEEP (metric improved)
  └── HEAD → Commit D
```

**Why commit before measuring:** If the metric command crashes the process or takes too long, the code change is preserved in git. We can always recover by checking the commit and its diff.

**Why one change per commit:** Attribution. When a metric improves, we know exactly which change caused it. When it regresses, we discard exactly that change.

### Rollback Mechanics

**Discard an experiment:**
```bash
git reset --soft HEAD~1
git restore .
```

This undoes the last commit and restores the working tree to the previous (known-good) state. Uses safe alternatives to `git reset --hard` (which is blocked by safety hooks).

**Important:** Only the most recent experiment can be discarded. Once a KEEP decision advances the branch, all prior keeps are permanent. This is by design — the frontier only moves forward.

### Branch Requirements

- MUST be on a feature branch (not main/master/develop)
- MUST have a clean working tree (no uncommitted changes)
- The feature branch acts as the experiment workspace
- After optimization completes, the branch contains only the kept improvements

## Crash Recovery

### Metric Command Failures

| Failure | Detection | Recovery |
|---------|-----------|----------|
| Non-zero exit code | `$? != 0` | Read last 50 lines, attempt one fix, re-run |
| No parseable number | Regex fails | Show raw output, attempt one fix, re-run |
| Timeout (>5 minutes) | Wall clock | Kill process, mark as crash |
| OOM / segfault | Signal detection | Mark as crash |

### Fix Attempt Protocol

When a metric command fails after a code change:

1. **Read the error output** — last 50 lines of stdout+stderr
2. **Diagnose** — Is it a syntax error? Missing import? Type mismatch?
3. **Fix** — Make ONE targeted fix (no refactoring, no scope expansion)
4. **Amend** — `git add -A && git commit --amend --no-edit`
5. **Re-measure** — Run metric command again
6. **If still failing** — Rollback: `git reset --soft HEAD~1 && git restore .`, log as crash

### Session Interruption

If a session ends mid-optimization:

1. The Stop hook saves state to `.auto-save.md`
2. `.failure-state.md` contains the optimization context (goal, metric, progress)
3. `.optimization-log.tsv` contains all experiment results so far
4. `/continue` can detect the active optimization and offer to resume
5. Resume reads the log, identifies best value, and continues the loop

## TSV Results Log

### File Location

`docs/sessions/.optimization-log.tsv` — NOT committed to git (prefixed with `.`, gitignored by framework convention).

### Schema

```
commit	metric_value	delta	status	description	lines_added	lines_removed
```

| Column | Type | Description |
|--------|------|-------------|
| `commit` | string | Short git commit hash (7 chars), or `baseline` for first entry |
| `metric_value` | number | Parsed metric value from command output |
| `delta` | number | Change from previous best value (0 for baseline, negative for regression) |
| `status` | enum | `baseline`, `keep`, `discard`, `crash` |
| `description` | string | Brief description of the experiment (from commit message) |
| `lines_added` | number | Lines added in this experiment |
| `lines_removed` | number | Lines removed in this experiment |

### Status Codes

| Status | Meaning | Git Action |
|--------|---------|------------|
| `baseline` | Initial measurement, no change made | None |
| `keep` | Metric improved, change retained | Commit stays |
| `discard` | Metric same or worse, change reverted | `git reset --soft HEAD~1 && git restore .` |
| `crash` | Metric command failed, change reverted | `git reset --soft HEAD~1 && git restore .` |

### Example Log

```tsv
commit	metric_value	delta	status	description	lines_added	lines_removed
baseline	72.5	0	baseline	Starting point	0	0
a1b2c3d	75.1	2.6	keep	Add missing auth module tests	45	0
b2c3d4e	75.1	0.0	discard	Add redundant validation tests	30	0
c3d4e5f	78.3	3.2	keep	Test error handling paths	22	5
d4e5f6a	0	0	crash	Reorganize test fixtures (import error)	15	20
e5f6a7b	80.1	1.8	keep	Add integration tests for API layer	55	3
```

## Diminishing Returns Detection

### Algorithm

Track a rolling window of the last 3 experiment outcomes:

```
window = [status_n-2, status_n-1, status_n]

IF all three are "discard" or "crash":
  → Trigger diminishing returns warning
  → Shift strategy (see below)
  → If next experiment ALSO fails: stop early
```

### Strategy Shifting

When diminishing returns detected, the next experiment should try a fundamentally different approach:

| Previous attempts | Shift to |
|-------------------|----------|
| Parameter tuning (config values, thresholds) | Structural change (new test files, refactored modules) |
| Adding code (new tests, new functions) | Removing code (dead code elimination, test consolidation) |
| Focused changes (single file) | Cross-cutting changes (multiple files, architectural) |
| Incremental improvement | Step-function change (new capability, new tool integration) |

### Early Termination Report

When stopping early due to diminishing returns:

```
Stopped early: diminishing returns after [N] experiments
Last 3+ experiments showed no improvement.
Attempted strategy shift at experiment [N-1] — also unsuccessful.

Possible reasons:
- Metric is near its practical ceiling/floor for this codebase
- Remaining improvements require architectural changes beyond current scope
- The metric command may not be sensitive enough to detect small improvements
```

## Simplicity Scoring

### Heuristic

For each kept experiment, compute a simplicity score:

```
net_lines = lines_added - lines_removed
simplicity_impact = IF net_lines < 0 THEN "simplified" ELSE IF net_lines == 0 THEN "neutral" ELSE "expanded"
```

### Reporting

In the completion report, highlight experiments that improved the metric while reducing code:

```
Simplicity highlights:
- Experiment 3: +3.2 coverage by REMOVING 5 lines (test consolidation)
- Experiment 5: +1.8 coverage with only 3 net lines added
```

Flag experiments with disproportionate growth:
```
Complexity concerns:
- Experiment 7: +0.5 coverage but added 120 lines — consider if this is worth the maintenance cost
```

### Preference Rule

When proposing experiments (step 3a), explicitly prefer approaches that:
1. Remove dead or redundant code (metric improves by reducing noise)
2. Consolidate duplicated patterns (fewer lines, same or better metric)
3. Add minimal, targeted code (small additions with outsized metric impact)

Over approaches that:
4. Add large amounts of new code (even if metric improves)
5. Add boilerplate or scaffolding (low metric-per-line ratio)
