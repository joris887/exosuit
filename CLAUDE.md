# [Project Name]

## Project Overview
<!-- Filled by /bootstrap -->

## Commands
```bash
# Filled by /bootstrap with detected commands:
# test:      <test command>
# lint:      <lint command>
# format:    <format command>
# build:     <build command>
# typecheck: <typecheck command>
```

## Architecture
<!-- One-liner filled by /bootstrap. See docs/architecture/ARCHITECTURE.md for details. -->

## Git Workflow
- **Flow:** GitHub Flow (feature branches → squash merge)
- **Branches:** `feature/<story-id>-<description>` or `sprint-<number>`
- **Commits:** Conventional: `<type>(<scope>): <description>`
- **Rules:** Never push to main, never force push, always PR

## Current Focus
<!-- Updated per sprint by /sprint-end -->

## Backlog
- **Index:** @docs/reference/BACKLOG_INDEX.md
- **Epics:** @docs/reference/backlog/E##-name.md (load only current epic)
- **Progress:** @docs/progress.md

## Testing
TDD mandatory for feature, bug fix, and refactoring stories. See `docs/reference/TESTING_STRATEGY.md`.

## Skills — JD-LLM Development Framework v3.2
See `.claude/skills/SKILLS_INVENTORY.md` for full inventory.

### Core Workflow
```
/sprint-start → /story-cycle (repeat) → /sprint-end
```

| I want to...           | Use                            |
|------------------------|--------------------------------|
| Setup framework        | `/bootstrap`                   |
| Resume work            | `/continue`                    |
| Start sprint           | `/sprint-start`                |
| Deliver story          | `/story-cycle <description>`   |
| Plan work              | `/ideate <idea>`               |
| Explore design         | `/brainstorm <idea>`           |
| End sprint             | `/sprint-end`                  |
| End session            | `/handoff`                     |
| Debug an issue         | `/debug-session <error>`       |
| Test plan              | `/manual-test`                 |
| Test feedback          | `/testing-cycle <feedback>`    |
| UAT test case          | `/UAT-cycle <test-case-id>`    |
| Parallel work          | `/parallel-work`               |
| Architecture check     | `/architecture-check`          |
| Framework health check | `/doctor`                      |
| Evaluate a skill       | `/skill-eval <mode> <skill>`   |
| Undo failed work       | `/undo-work`                   |
| Iterative refinement   | `/refine-loop "<task>"`        |

## Important Files
- `docs/reference/CODING_STANDARDS.md` — Code conventions
- `docs/reference/TESTING_STRATEGY.md` — Testing practices
- `docs/architecture/ARCHITECTURE.md` — System architecture
- `docs/reference/GROUND_RULES.md` — Architectural principles
- `docs/testing/UAT_COVERAGE.md` — UAT test cases

## Compaction Directive
When compacting context, use this structured key-value format. Items are tagged by priority — drop LOW first, CRITICAL must survive all compactions verbatim.

```yaml
## Compacted Context

### [CRITICAL — preserve verbatim across all compactions]
goal: "[Current objective — what story/task is in progress]"
commands: {test: "[cmd]", lint: "[cmd]", build: "[cmd]", typecheck: "[cmd]"}
active_plan: |
  [Any in-progress plan, verbatim if possible]

### [HIGH — preserve if space allows]
branch: "[name]"
sprint: [number]
phase: "[current phase or status]"
decisions:
  - choice: "[decision]" | reason: "[rationale]"
in_progress: "[current task and its state]"

### [NORMAL — summarize if needed]
completed: ["[item1]", "[item2]"]
blocked_by: "[blocker or null]"

### [LOW — drop first, these are recoverable]
<files-read>[paths of all files explored this session, one per line]</files-read>
<files-modified>[paths of all files changed this session, one per line]</files-modified>
```

When multiple compactions occur:
- MERGE new file paths into existing `<files-read>` and `<files-modified>` lists — never discard previous entries
- Drop LOW items first if space is tight (files can be re-read)
- CRITICAL items must survive every compaction — never summarize or drop them
