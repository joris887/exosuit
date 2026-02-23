Load project context knowledge base. Before loading, classify the current task's intent to prioritize the most relevant context.

## Intent Classification

Extract 2-3 keywords from the current task and map to an intent category:

| Intent | Keywords | Priority Order |
|--------|----------|----------------|
| **Security/Auth** | auth, security, credentials, token, encrypt, RBAC | system-patterns → tech-context → project-overview → project-structure → product-context |
| **UI/Frontend** | UI, frontend, form, button, page, component, layout | product-context → project-structure → tech-context → system-patterns → project-overview |
| **Data/API** | API, endpoint, database, query, schema, migration | tech-context → system-patterns → project-structure → project-overview → product-context |
| **Refactoring** | refactor, restructure, extract, consolidate, clean up | system-patterns → project-structure → tech-context → project-overview → product-context |
| **New Feature** | add, implement, create, build, feature | product-context → tech-context → system-patterns → project-structure → project-overview |
| **Default** | (no match) | project-overview → tech-context → system-patterns → project-structure → product-context |

## Loading

Load files in the classified priority order. Stop if context budget is tight. For each file: skip if it contains only template placeholders (`<!-- filled by -->`). Only load files that have been populated with actual project content.

All files live in `docs/context/`:
- `project-overview.md` — what the project does
- `tech-context.md` — stack and integration patterns
- `system-patterns.md` — design patterns and conventions
- `project-structure.md` — directory layout and module responsibilities
- `product-context.md` — domain terminology and user personas
- `error-patterns.md` — cross-session error learning (always load last, low priority but valuable for avoiding known mistakes)
