---
name: refine-loop
version: 2.4.0
description: Use when the user wants iterative self-improvement on a deliverable (document, implementation, prompt, design) until completion criteria are met.
trigger: manual
depends-on: []
references: []
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Edit, Write
argument-hint: ""<task>" --until "<criteria>" [--max <N>]"
---
______________________________________________________________________

## refine-loop

Refining: **$ARGUMENTS**

## Argument Parsing

| Argument | Required | Default | Description |
|----------|----------|---------|-------------|
| `<task>` | Yes | - | What to produce or improve |
| `--until "<criteria>"` | Yes | - | Completion condition (must be verifiable) |
| `--max <N>` | No | 5 | Maximum iterations before stopping |

## Process

### 1. Initial Execution

Execute the task to produce the first draft/version.

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

### 4. Iteration (if continuing)

Each iteration MUST:
1. **Name the gap**: What specific criterion is not met?
2. **Describe the fix**: What concrete change will address it?
3. **Apply the fix**: Make the change
4. **Re-evaluate**: Check ALL criteria again (not just the one fixed)

<HARD-GATE>
Each iteration must identify SPECIFIC improvements with concrete descriptions. "Make it better" or "improve quality" are NOT valid improvement descriptions. If you cannot name a specific gap, the loop is done — output the current result.
</HARD-GATE>

### 5. Completion Report

```markdown
### Refinement Complete

**Task:** [description]
**Completion criteria:** [criteria]
**Iterations:** X of Y max
**Status:** [All criteria met / Stopped at max / No further improvements identified]

**Iteration log:**
1. [What was changed and why]
2. [What was changed and why]
...

**Remaining gaps (if any):**
- [Gap]: [Why it couldn't be resolved]
```

## Safety

- Default `--max 5` prevents runaway loops
- Each iteration must make measurable progress — if an iteration doesn't change anything, stop
- If the same gap persists after 2 attempts, flag it as potentially unresolvable and move on
- The loop produces a completion report regardless of how it ends

## When to Use

- Polishing documentation (architecture docs, READMEs, ADRs)
- Iterating on prompt/skill content
- Refining complex implementations with multi-faceted quality criteria
- Any task where "good enough on first try" is unlikely

## When NOT to Use

- Simple one-shot tasks (just do them directly)
- Tasks without clear completion criteria
- During story-cycle execution (use the story-cycle's own phases instead)
