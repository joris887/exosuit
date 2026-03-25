---
name: architecture-check
version: 2.7.0
description: Validate module boundaries, check for architectural drift, and suggest fitness function tests. Compares actual code structure against ARCHITECTURE.md.
trigger: conditional
depends-on: []
references: []
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash
context: fork
agent: Explore
---
______________________________________________________________________

## architecture-check

You are a software architect validating that the codebase adheres to its documented architecture.

## 1. Load Architecture Documentation

Read:

- `docs/architecture/ARCHITECTURE.md` — documented module boundaries and dependencies
- `docs/reference/GROUND_RULES.md` — architectural ground rules with enforcement channels (if exists)
- `docs/adr/` — architecture decision records (if any exist)
- `CLAUDE.md` — architecture one-liner

If ARCHITECTURE.md doesn't exist or is a template, inform the user and suggest running `/bootstrap` or creating one.

## 2. Validate Module Boundaries

Apply the `architectural_impact` reasoning tool from `.claude/skills/story-cycle/references/reasoning-tools.md` to assess module boundaries systematically.

For each documented module/layer:

If the Module Map section contains explicit Dependency Rules (MUST/NEVER statements), use those as the primary validation criteria rather than inferring boundaries from the diagram alone.

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

### 3.5. Validate Dependency Rules

If the Module Map section contains Dependency Rules (MUST/NEVER/MAY statements):

For each rule:
1. Parse the rule into: `[subject] [MUST/NEVER/MAY] [action] [target]`
2. Verify with import analysis: scan actual imports in the subject modules
3. Report violations with file:line evidence

Example: Rule "Controllers MUST only call services" → grep controller directory for imports outside the services layer.

### 3.7. Check Update Triggers

Read the Update Triggers section. For each trigger, check if recent changes match:

```bash
LAST_VERIFIED=$(grep -oP 'Last Verified: \K[\d-]+' docs/architecture/ARCHITECTURE.md 2>/dev/null)
if [ -n "$LAST_VERIFIED" ]; then
    git log --since="$LAST_VERIFIED" --name-only --pretty=format: | sort -u | head -30
fi
```

Compare changed files against trigger conditions (new top-level directories, new data stores, changed API boundaries). Flag any matches as "Architecture doc may be stale."

### 3.7b. Validate API Documentation Currency (if API project)

<IF condition="docs/reference/API_DOCUMENTATION.md exists and has populated Operations section (not just template placeholders)">

1. Grep for route/endpoint definitions in the codebase (framework-specific: `@app.route`, `router.get`, `@RequestMapping`, `func (h *Handler)`, etc.)
2. Compare discovered endpoints against documented Operations in `docs/reference/API_DOCUMENTATION.md`
3. Flag: **undocumented endpoints** (in code but not in docs), **stale documentation** (in docs but removed from code)
4. Check consistency: do all endpoints use the documented authentication method? Do error responses follow the documented error format?
5. If an API spec file exists (`openapi.yaml`, `asyncapi.yaml`, etc.): verify it is referenced in the API documentation header

Report findings in the output under `### API Documentation Currency`.
</IF>

### 3.8. Validate Known Landmines

For each entry in the Known Landmines section:
- If it references a file: verify the file still exists and the described condition is still present
- If it references a pattern: grep for it
- Flag entries that appear to be resolved (file removed, pattern no longer present)

## 3.9. Validate Ground Rules

<IF condition="docs/reference/GROUND_RULES.md exists and has GR-NNN rules">
Read `docs/reference/GROUND_RULES.md`. For each rule:
- **`Enforced-by: review:`** — perform the specified check against the codebase, report violations with file:line evidence
- **`Enforced-by: auto:`** — verify the referenced tool/test is configured and running (e.g., ArchUnit test exists, dependency-cruiser config present). Flag unconfigured enforcement as "enforcement gap"
- **`Enforced-by: ai:`** — check that recent changes don't violate the ai instruction

Check the **Exception Log** — any violation covered by a non-expired exception is compliant.
</IF>

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

**ADR-to-principle promotion:** If `docs/adr/` contains 2+ ADRs addressing the same architectural concern (e.g., repeated boundary violations, recurring dependency decisions), suggest promoting it to a ground rule in `docs/reference/GROUND_RULES.md`. Recurring decisions indicate a missing principle.

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

### Ground Rules Compliance
| Rule | Level | Status | Evidence |
|------|-------|--------|----------|
| [GR-NNN: name] | MUST/SHOULD | PASS/FAIL/ENFORCEMENT GAP | [file:line or tool status] |

### API Documentation Currency
- [Undocumented endpoints / Stale docs / Consistent — or "N/A (no API detected)"]

### Fitness Function Suggestions
- [Test description]: [What it validates]

### Recommendations
1. [Most important action]
2. [Second priority]
```
