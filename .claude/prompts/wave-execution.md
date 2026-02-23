Parallel execution pattern for independent operations. Use when a phase involves multiple operations that don't depend on each other's results.

## Wave → Checkpoint → Wave

### Wave 1: Independent Reads (Parallel)

Launch all independent read/explore/search operations simultaneously:
- Multiple file reads with no cross-dependency
- Multiple grep/glob searches targeting different areas
- Multiple explore subagent dispatches with independent questions

**Rule:** NO operation in Wave 1 may depend on another Wave 1 result.

### Checkpoint: Sequential Analysis

Collect all Wave 1 results and analyze together:
- Combine findings into a unified understanding
- Identify dependencies, conflicts, or gaps
- Decide which Wave 2 operations are needed
- If checkpoint reveals new reads needed → add a Wave 1.5 before proceeding

### Wave 2: Independent Actions (Parallel)

Launch all independent write/edit/create operations simultaneously:
- Multiple file edits targeting different files
- Multiple test runs for independent modules
- Multiple subagent dispatches for independent tasks

**Rule:** NO operation in Wave 2 may depend on another Wave 2 result.

## Anti-Patterns

- DO NOT parallelize operations with data dependencies (one edit depends on another's result)
- DO NOT skip the checkpoint (it catches conflicting results from Wave 1)
- DO NOT exceed 5 parallel operations (context pressure from concurrent results)
- DO NOT use for sequential workflows where order matters (test → fix → retest)

## When to Apply

| Situation | Apply? |
|-----------|--------|
| Reading 3+ files for research | Yes — Wave 1 |
| Editing 2+ independent files | Yes — Wave 2 |
| Running quality agents | Yes — already parallel in sprint-end |
| TDD red-green-refactor cycle | No — sequential by nature |
| Debugging with hypothesis testing | No — one variable at a time |
