Record a failure pattern for cross-session learning. Invoke when self-review catches issues (story-cycle Phase 4a), when debug-session identifies a root cause (Phase 4), or when a fix attempt fails and the correct approach is found.

## When to Record

- Self-review (Phase 4a) catches a wrong approach that required rework
- Debug-session identifies a root cause that was initially misdiagnosed
- A fix attempt fails and investigation reveals the correct approach
- An architectural decision is reversed after implementation

Do NOT record: normal TDD red-green cycles, expected test failures, or routine corrections.

## Recording Protocol

Append a new entry to `docs/brain/error-patterns.md`:

```markdown
## [Brief description of the error pattern]
- **Date:** [ISO date]
- **Story/Task:** [Story ID or description]
- **Wrong approach:** [What was attempted and why it seemed right]
- **Root cause:** [Why it failed — the actual underlying issue]
- **Correct approach:** [What worked and why]
- **Prevention:** [What to check next time to avoid this — specific, actionable]
- **Affected area:** [Module, file pattern, or technology area for matching]
```

## Guidelines

- Keep entries concise — 3-5 lines per field maximum
- Focus on the PATTERN, not the specific instance — future sessions should recognize similar situations
- The "Prevention" field is most important — it's what gets checked in future planning
- The "Affected area" field enables targeted matching during context-prime loading
- Prune entries older than 6 months during `/weekly-maintenance` if the pattern hasn't recurred
