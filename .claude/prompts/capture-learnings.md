# Capture Learnings

A micro-component for extracting and persisting learnings from completed stories into a searchable solutions database.

## When to Apply

- Story-cycle Phase 4 (after quality gates pass, before commit)
- Debug-session Phase 5 (after root cause is identified and fixed)
- Any time a non-obvious approach or integration gotcha is discovered

## Process

### Step 1: Assess Learning Value

Not every story produces a learning worth persisting. Skip this step if:
- The story was TRIVIAL (typo, config, comment)
- The implementation followed a well-established pattern with no surprises
- No architectural decisions, integration gotchas, or non-obvious approaches were involved

### Step 2: Extract Key Insights

From the completed work, identify:
- **Approach taken:** What design pattern or strategy was used and why?
- **Key decisions:** What alternatives were considered and rejected?
- **Gotchas:** What was non-obvious or surprising during implementation?
- **Integration notes:** How does this connect to other modules? What API contracts matter?

### Step 3: Write Solution Document

Save to `docs/solutions/<topic-slug>.md` with YAML frontmatter:

```yaml
---
title: "<Descriptive title>"
tags: [<relevant-tags>]
module: <primary-module-affected>
component: <specific-component>
story: "<story-id-or-description>"
date: <YYYY-MM-DD>
---

## Problem
[One paragraph: what was the challenge?]

## Approach
[What was done and why this approach was chosen over alternatives]

## Key Decisions
- [Decision 1]: [Rationale]
- [Decision 2]: [Rationale]

## Gotchas
- [Non-obvious thing 1]
- [Non-obvious thing 2]
```

### Step 4: Keep It Brief

Solution documents should be 20-40 lines. They're for future reference, not comprehensive documentation. The code itself and git history provide the details.

## How Solutions Are Used

During story-cycle Phase 1b, the grep-first-explore micro-component searches `docs/solutions/` for prior learnings on affected modules:
- Grep frontmatter fields (tags, module, component) for relevance
- Read only matching solution documents
- Apply learnings to avoid repeating mistakes or rediscovering patterns
