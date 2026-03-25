# [Project Name]

## Project Overview
<!-- Filled by /bootstrap -->

## Tech Stack
<!-- /bootstrap: Fill with detected versions. Prevents AI from mixing incompatible API versions. -->
<!-- Example: Python 3.12 / FastAPI 0.109 / SQLAlchemy 2.0 / Pydantic 2.5 -->

## Critical Rules
<!-- /bootstrap: Promote the 3-5 most project-damaging violations from CODING_STANDARDS.md -->
<!-- These load every session. Only rules where violation causes real damage belong here. -->
<!-- Example:
- NEVER hardcode secrets — use environment variables
- NEVER use `any` types without justification comment
- NEVER weaken test assertions to make tests pass
-->

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

## Architecture Rules
<!-- Derived from accepted ADRs. See the linked ADR for full rationale. -->
<!-- /bootstrap: Populate from existing docs/adr/ records. Add manually as ADRs are accepted. -->
<!-- Example:
- All API endpoints use REST, not GraphQL (ADR-0003)
- Authentication uses Auth0; do not implement custom auth (ADR-0015)
-->
- Before proposing any architectural change, check @docs/adr/ for prior decisions.

## Git Workflow
- **Default branch:** <!-- Detected by /bootstrap (main, master, develop, etc.) -->
- **Flow:** GitHub Flow (feature branches → squash merge)
- **Branches:** `feature/<story-id>-<description>` or `sprint-<number>`
- **Commits:** Conventional: `<type>(<scope>): <description>`
- **Rules:** Never push to default branch, never force push, always PR

## Current Focus
<!-- Updated per sprint by /sprint-end -->

## Backlog
- **Index:** @docs/reference/BACKLOG_INDEX.md
- **Epics:** @docs/reference/backlog/E##-name.md (load only current epic)
- **Progress:** @docs/progress.md

## Testing
TDD mandatory for feature, bug fix, and refactoring stories. See `docs/reference/TESTING_STRATEGY.md`.

## Skills — JD-LLM Development Framework v3.7
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
| Deep research          | `/research <topic>`            |
| End sprint             | `/sprint-end`                  |
| End session            | `/handoff`                     |
| Debug an issue         | `/debug-session <error>`       |
| Test plan              | `/manual-test`                 |
| Test feedback          | `/testing-cycle <feedback>`    |
| UAT test case          | `/UAT-cycle <test-case-id>`    |
| Sense check UAT cases  | `/claude-sense-check`          |
| Parallel work          | `/parallel-work`               |
| Architecture check     | `/architecture-check`          |
| Framework health check | `/doctor`                      |
| Upgrade framework      | `/framework-upgrade`           |
| Evaluate a skill       | `/skill-eval <mode> <skill>`   |
| Undo failed work       | `/undo-work`                   |
| Iterative refinement   | `/refine-loop "<task>"`        |
| Optimize a metric      | `/optimize "<goal>"`           |

## Important Files
- `docs/reference/CODING_STANDARDS.md` — Code conventions
- `docs/reference/TESTING_STRATEGY.md` — Testing practices
- `docs/architecture/ARCHITECTURE.md` — System architecture
- `docs/reference/GROUND_RULES.md` — Architectural principles
- `docs/adr/` — Architecture decision records (prior decisions and rejected alternatives)
- `docs/reference/MCP_INTEGRATION.md` — MCP server selection and integration guide
- `docs/testing/UAT_COVERAGE.md` — UAT test cases

## Compaction Directive
When compacting context, use this structured key-value format. Items are tagged by priority — drop LOW first, CRITICAL must survive all compactions verbatim.

```yaml
## Compacted Context

### [CRITICAL — preserve verbatim across all compactions]
goal: "[Current objective — what story/task is in progress]"
sprint_goal: "[Current sprint goal — one sentence from sprint spec]"
sprint_spec: "docs/sprints/sprint-[N].md"
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
