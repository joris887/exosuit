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
- Subdirectory `CLAUDE.md` files provide module-specific context — Claude Code lazy-loads them when you read or edit files in that directory. Keep them under 20 lines.

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
| ARCHITECTURE.md | ≤200 lines | Overview only; module details in subdirectory CLAUDE.md files |

When loading a reference file, load only the section relevant to the current task — use grep hints (search for `## Section Name`) rather than reading the entire file.

## Cross-Skill Output Optimization

When a skill's output will be consumed by another skill or a future session (plans, session files, debug reports):

- **Bullet points over prose** — scannable beats readable for LLM consumption
- **file:line references over descriptions** — `src/auth/login.ts:42` over "the login function in the auth module"
- **Imperative instructions over explanations** — "Add rate limiter middleware to /api/auth" over "We should consider adding..."
- **Front-load critical information** — put key facts in the first 5 lines
- **YAML frontmatter for machine-parseable metadata** — dates, status, phase, story type
- **Section budgets** — No plan section should exceed 20 lines; split into sub-sections if needed
- **Use output templates** — Skills with `assets/` templates should copy and fill them rather than generating structure from scratch

## Documentation Accuracy

When creating or updating project documentation (architecture, context, coding standards, progress):

- **Evidence-based claims only** — every technical claim must reference specific files or code
- **Qualify uncertain claims** — use "appears to", "likely", "based on [file]" for indirect evidence
- **Flag assumptions** — mark unverified claims with `[Assumed — needs verification]`
- **Post-creation validation** — after generating documentation, re-read and verify each technical claim against actual files
- **No pattern inference from training data** — describe what THIS codebase does, not what similar projects typically do

See `.claude/skills/bootstrap/references/accuracy-safeguards.md` for the full anti-hallucination protocol.
