# Parallel Stream Decomposition

Optional Phase 3a: decompose a story into independent parallel work streams.

## When to Use

- Story is classified as **STANDARD** size
- Risk level is **Low** or **Medium** (3-6)
- Plan identifies ≥2 independent work units with non-overlapping file scopes
- User approves parallel execution

**Do NOT parallelize when:**
- Files overlap between streams
- Streams have sequential dependencies that can't be resolved
- Story is TRIVIAL or SMALL
- Risk is High (7-9) — serial execution provides better oversight

## Stream Analysis

After Phase 2 (Context Transition), analyze the approved plan:

1. Identify independent work units from the Implementation Approach
2. Map each unit to its file scope (which files it creates/modifies)
3. Check for overlaps — if ANY file appears in multiple streams, merge those streams
4. Identify dependencies between streams (e.g., "Tests" depends on "Service Layer")

## Stream Definition Format

```yaml
Streams:
  - name: Database Layer
    files: [src/db/*, migrations/*]
    dependencies: []
  - name: API Layer
    files: [src/api/*]
    dependencies: []
  - name: Tests
    files: [tests/*]
    dependencies: [Database Layer, API Layer]
```

## Execution

1. Present stream analysis to user with file scopes
2. If approved: create worktrees per stream via `/parallel-work create`
3. Each stream agent receives:
   - The approved plan (full)
   - Its stream scope (files it may touch)
   - Shared context: CODING_STANDARDS.md, TESTING_STRATEGY.md
4. Streams without dependencies start simultaneously
5. Dependent streams start after their prerequisites merge
6. Coordinate merges in dependency order

## Fallback

If parallel execution fails (merge conflicts, agent errors):
- Merge what succeeded
- Continue remaining work serially in the main worktree
- Report what was parallelized and what fell back to serial
