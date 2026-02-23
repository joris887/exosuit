---
paths:
  - "docs/**"
  - "**/*.md"
---

# Documentation Rules

- Only create documentation files when explicitly requested by the user
- Prefer updating existing docs over creating new files
- Keep documentation concise — every line should earn its place
- Never add auto-generated boilerplate without user approval
- Archive or remove stale content rather than letting it accumulate
- Documentation in CLAUDE.md, progress.md, and BACKLOG_INDEX.md is loaded every session — keep these files lean
- Reference other docs by path rather than inlining their content
- `.claude-context.md` files in directories provide module-specific context — read the nearest one when working in a directory, but never create them proactively

## Reference File Size Budgets

On-demand reference files are loaded into context when skills request them. Without size limits, they silently consume context budget as projects grow.

| File Type | Budget | Action If Over Budget |
|-----------|--------|----------------------|
| Skill SKILL.md entry point | ≤150 lines | Split into SKILL.md + references/ |
| Individual reference file | ≤200 lines | Split by topic into focused sub-files |
| Total references per skill | ≤500 lines | Extract rarely-used content to separate files |
| CODING_STANDARDS.md | ≤200 lines | Split by language if multi-language project |
| TESTING_STRATEGY.md | ≤250 lines | Keep core workflow; move examples to reference |
| GROUND_RULES.md | ≤100 lines | Principles only; tracked violations in separate section |
| ARCHITECTURE.md | ≤200 lines | Overview only; module details in .claude-context.md files |

When loading a reference file, load only the section relevant to the current task — use grep hints (search for `## Section Name`) rather than reading the entire file.
