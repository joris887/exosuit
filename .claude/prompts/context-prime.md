Load project context knowledge base. Before loading, classify the current task's intent to prioritize the most relevant context.

## Intent Classification

Extract 2-3 keywords from the current task and map to an intent category:

| Intent | Keywords | Priority Order |
|--------|----------|----------------|
| **Security/Auth** | auth, security, credentials, token, encrypt, RBAC | system-patterns → tech-context → project-overview → project-structure → product-context |
| **UI/Frontend** | UI, frontend, form, button, page, component, layout | product-context → project-structure → tech-context → system-patterns → project-overview |
| **Data/API** | API, endpoint, database, query, schema, migration, route, handler, controller, webhook, graphql, grpc | tech-context → API_DOCUMENTATION → system-patterns → project-structure → project-overview → product-context |
| **Refactoring** | refactor, restructure, extract, consolidate, clean up | system-patterns → project-structure → tech-context → project-overview → product-context |
| **New Feature** | add, implement, create, build, feature | product-context → tech-context → system-patterns → project-structure → project-overview |
| **Research/Spike** | research, investigate, evaluate, spike, compare, analyze | tech-context → system-patterns → project-overview → product-context → project-structure |
| **Default** | (no match) | project-overview → tech-context → system-patterns → project-structure → product-context |

## Loading

**v5.0 entry points (load first, before the intent-priority stable pages):**

1. `docs/brain/index.md` — catalog. Tells you which pages exist and which are still template stubs.
2. `docs/brain/current-state.md` — snapshot: what's working / in progress / changed recently.
3. Optional (when resuming after a gap): tail of `docs/brain/log.md` via `grep '^## \[' docs/brain/log.md | tail -5` — see what changed since last session.

Then load the stable pages in the classified priority order. Stop if context budget is tight. For each file: skip if it contains only template placeholders (`<!-- filled by -->`). Only load files that have been populated with actual project content.

All files live in `docs/brain/` unless noted:
- `project-overview.md` — what the project does
- `tech-context.md` — stack and integration patterns
- `system-patterns.md` — design patterns and conventions
- `project-structure.md` — directory layout and module responsibilities
- `product-context.md` — domain terminology and user personas
- `personas.md` — user persona cards (lean 6-field format)
- `error-patterns.md` — cross-session error learning (always load last, low priority but valuable for avoiding known mistakes)
- `API_DOCUMENTATION` → `docs/reference/API_DOCUMENTATION.md` — API contracts, operations, schemas (load for Data/API intent only; skip if template-only)

## Prior Research Check

**For Research/Spike intent only:** Before starting new research, check for prior research that may already cover the topic:

1. Search `docs/research/` for matching topics (Grep frontmatter `title:` and `tags:` fields)
2. Search `docs/solutions/` for related prior learnings (Grep frontmatter `tags:` and `title:` fields)
3. Search `docs/brainstorms/` for related design explorations (Grep frontmatter `title:` field)

If prior research exists and is recent (check `date:` in frontmatter), load it as context to avoid redundant research. Note findings to the user: "Found prior research on [topic] from [date] — loading as context."
