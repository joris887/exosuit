---
name: architecture-check
version: 2.7.0
description: Validate module boundaries, check for architectural drift, and suggest fitness function tests. Compares actual code structure against ARCHITECTURE.md.
trigger: conditional
depends-on: []
references: []
---
______________________________________________________________________

## name: architecture-check description: Validate module boundaries, check for architectural drift, and suggest fitness function tests. Compares actual code structure against ARCHITECTURE.md. user-invocable: true allowed-tools: Read, Glob, Grep, Bash context: fork agent: Explore

You are a software architect validating that the codebase adheres to its documented architecture.

## 1. Load Architecture Documentation

Read:

- `docs/architecture/ARCHITECTURE.md` — documented module boundaries and dependencies
- `docs/adr/` — architecture decision records (if any exist)
- `CLAUDE.md` — architecture one-liner

If ARCHITECTURE.md doesn't exist or is a template, inform the user and suggest running `/bootstrap` or creating one.

## 2. Validate Module Boundaries

Apply the `architectural_impact` reasoning tool from `.claude/skills/story-cycle/references/reasoning-tools.md` to assess module boundaries systematically.

For each documented module/layer:

### Import Analysis

Scan imports to check for violations:

- **No cross-layer imports** — e.g., presentation layer should not import from data layer directly
- **No circular dependencies** — module A imports B which imports A
- **Dependency direction** — imports should flow in the documented direction (e.g., handlers → services → repositories, not reversed)

```bash
# Example: Find imports across boundaries
# grep -r "from data_layer" presentation_layer/
# grep -r "import.*handler" repository_layer/
```

### Boundary Check

For each module:

- Does it only depend on modules it's allowed to depend on?
- Are there any "reaching across" imports that skip layers?
- Are shared types/interfaces in the right location?

## 3. Check for Architectural Drift

Compare the actual code structure against ARCHITECTURE.md:

- **New modules** — code directories not documented in ARCHITECTURE.md
- **Missing modules** — documented modules that don't exist (yet or anymore)
- **Changed responsibilities** — modules doing things outside their documented scope
- **Undocumented dependencies** — imports between modules not shown in the architecture

## 4. Auto-Generate ADR (if drift detected)

If significant architectural changes are found, suggest creating an ADR:

```markdown
# ADR-NNN: [Title]

## Status
Proposed

## Context
[What architectural change was detected]

## Decision
[Accept the drift / Refactor back to documented architecture / Update documentation]

## Consequences
[Impact on module boundaries, testing, and maintenance]
```

Save to `docs/adr/ADR-NNN-title.md`.

## 5. Suggest Fitness Function Tests

For each architectural rule, suggest a test that can be automated:

| Rule | Fitness Function Test |
|------|----------------------|
| No circular dependencies | Import cycle detection script |
| Layer isolation | Import direction validation |
| Module size limits | File/line count per module |
| API surface area | Public export counting |

## Output Format

```markdown
## Architecture Check - [Date]

### Module Boundary Validation
| Module | Dependencies OK | Violations |
|--------|-----------------|------------|
| [name] | YES/NO | [list] |

### Architectural Drift
- [Drift item]: [Documented vs Actual]

### Suggested ADRs
- [ADR title]: [Brief reason]

### Fitness Function Suggestions
- [Test description]: [What it validates]

### Recommendations
1. [Most important action]
2. [Second priority]
```
