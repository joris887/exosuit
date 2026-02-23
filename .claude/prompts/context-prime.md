Load project context knowledge base in priority order. Stop if context budget is tight.

**Priority 1 (Essential):**
- `docs/context/project-overview.md` — what the project does
- `docs/context/tech-context.md` — stack and integration patterns

**Priority 2 (Helpful):**
- `docs/context/system-patterns.md` — design patterns and conventions
- `docs/context/project-structure.md` — directory layout and module responsibilities

**Priority 3 (If space allows):**
- `docs/context/product-context.md` — domain terminology and user personas

For each file: skip if it contains only template placeholders (<!-- filled by -->). Only load files that have been populated with actual project content.
