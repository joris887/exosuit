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

## Skills — JD-LLM Development Framework v2.0
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
| End sprint             | `/sprint-end`                  |
| End session            | `/handoff`                     |
| Test plan              | `/manual-test`                 |
| Test feedback          | `/testing-cycle <feedback>`    |
| UAT test case          | `/UAT-cycle <test-case-id>`    |
| Parallel work          | `/parallel-work`               |
| Architecture check     | `/architecture-check`          |

## Important Files
- `docs/reference/CODING_STANDARDS.md` — Code conventions
- `docs/reference/TESTING_STRATEGY.md` — Testing practices
- `docs/architecture/ARCHITECTURE.md` — System architecture
- `docs/testing/UAT_COVERAGE.md` — UAT test cases

## Compaction Directive
When compacting context, always preserve: current branch name, modified files list, test commands from Commands section, current story status, current sprint number, and any in-progress plan.
