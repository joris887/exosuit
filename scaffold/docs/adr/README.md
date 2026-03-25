# Architecture Decision Records

This directory contains Architecture Decision Records (ADRs) — short documents capturing significant technical decisions, the alternatives considered, and why they were rejected.

## Index

| ID | Title | Status | Date | Tags |
|----|-------|--------|------|------|
<!-- ADR-001 | [Title] | accepted | YYYY-MM-DD | [tags] -->

## When to Write an ADR

Apply the **reversibility test** — write an ADR when:

- The decision would be **costly to reverse** (technology choices, data models, auth strategy)
- It **affects multiple components** or crosses service/module boundaries
- It **changes system structure** (new patterns, decomposition, new dependencies)
- It **will be questioned in 6 months** by future team members or AI assistants
- A **spike/research** story results in a technology recommendation
- `/architecture-check` **detects drift** from documented architecture

Skip ADRs for: library minor version bumps, code style choices already in linting config, single-file refactors, decisions already covered by an existing ADR.

## Process

1. **Author:** Any developer who makes or discovers an architecturally significant decision. `/architecture-check` auto-generates `status: proposed` drafts when it detects drift.
2. **File:** Copy `TEMPLATE.md` to `NNNN-short-title.md`. Number sequentially, never reuse numbers.
3. **Review:** Commit the ADR as `status: proposed` in the same PR as the code change. One approving review from someone not involved in the decision. Merge = acceptance.
4. **On merge:** Update status to `accepted` and add a row to the Index table above.
5. **Never edit accepted ADRs.** To change a decision, create a new ADR that supersedes the old one. Update the old ADR's `superseded-by` field and status only.

## Status Lifecycle

```
proposed → accepted → deprecated (no longer relevant)
                    → superseded (replaced by new ADR)
proposed → rejected (decided against — preserved as negative knowledge)
```

## Ground Rule Graduation

When an accepted ADR has been stable for 2+ sprints and the team wants it enforced automatically:

1. Add the constraint to `docs/reference/GROUND_RULES.md` as a MUST/SHOULD rule
2. Update the ADR's `linked-ground-rules` field with the GR-NNN reference
3. Optionally create a fitness function for CI enforcement

The ADR remains as the full rationale; the ground rule becomes the enforceable constraint.

## AI Integration

- `/story-cycle` Phase 1e scans ADR frontmatter before planning — it checks `rejected-options` to avoid re-proposing rejected approaches
- `/architecture-check` generates ADR drafts when drift is detected
- Ground rules in `GROUND_RULES.md` link back to ADRs for full context
- The `rejected-options` YAML field enables fast filtering without reading full records

## Periodic Review

- Review `confidence: low` ADRs every sprint boundary
- Review all ADRs at architecture health checks
- Check `Reconsider when` conditions during `/architecture-check` runs
