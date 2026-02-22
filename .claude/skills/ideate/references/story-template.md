# Story Template

Use this structure when decomposing ideas into backlog stories. The template enforces user-centric framing, independent testability, and explicit prioritization.

## Story Structure

```markdown
### <Story-ID>: <Brief user-facing title — NO technical terms> [<Type>]

**As a** [user role], **I want** [capability], **so that** [value].

**Acceptance Criteria:**
1. **Given** [state], **When** [action], **Then** [outcome]
2. **Given** [state], **When** [action], **Then** [outcome]

**Independent Test:** [How to verify this story works without other stories being complete]

**Priority:** P1/P2/P3
**Why this priority:** [Value justification — not technical complexity]

**Skills:** [/code-quality, /test-validator, etc.]
**Testing Approach:** [TDD | Characterization | Smoke | Benchmark | Manual review]
**Verification:** [Command to prove it works]
**File Hints:** [Key files to read/modify]
**Non-Goals:** [What is explicitly out of scope]
**Depends On:** [Other story IDs]
```

## Anti-Patterns

- **Title contains technical terms** — "Implement JWT middleware" → "User stays logged in across sessions"
- **Acceptance criteria not testable** — "System should be fast" → "Given a search query, When submitted, Then results appear within 200ms"
- **No independent test** — every story must be verifiable without other stories
- **Priority based on complexity** — priority reflects value to users, not implementation difficulty
