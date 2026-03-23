# Reference Documentation

On-demand reference files loaded by skills when needed. Not auto-loaded at session start.

## Files
- `BACKLOG_INDEX.md` — epic/story index (loaded by sprint skills)
- `CODING_STANDARDS.md` — language-specific code conventions
- `TESTING_STRATEGY.md` — TDD workflow, coverage targets, test patterns
- `GROUND_RULES.md` — architectural MUST/SHOULD principles
- `GIT_WORKFLOW.md` — branching, commit, and PR conventions
- `MCP_INTEGRATION.md` — MCP server selection and usage guide
- `WORKFLOW.md` — development workflow phases
- `READINESS_REPORT.md` — bootstrap readiness assessment
- `PRD_SUMMARY.md` — product requirements summary
- `backlog/` — individual epic files (load only the current one)

## Conventions
- Individual files: max 200 lines. Split by topic if larger.
- Load only the section you need — use grep hints, not full file reads
- Updated by skills that own the content (bootstrap, sprint-end, ideate)
