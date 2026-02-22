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
