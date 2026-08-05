# Project Complexity Profiles — Design Document

**Status:** Approved
**Date:** 2026-03-30
**Stories:** E14-S17 (design), E14-S18 (engine), E14-S19 (Lean), E14-S20 (Strict), E14-S21 (auto-detect)

## Problem

The framework has one mode: full ceremony. Every project gets the same 844-line story-cycle, 5 quality gate agents, sprint planning, documentation generation, and retrospectives. This serves experienced developers on production codebases but fails for:
- Solo builders shipping prototypes (too heavy)
- Skeptical seniors on established projects (too much redundant ceremony)
- Non-technical founders (completely inaccessible)
- AI-native developers (too many manual checkpoints)

The framework needs adaptive complexity based on **project characteristics**, not team size.

## Design Decisions

### 1. Three Profiles

| Aspect | Lean | Standard | Strict |
|--------|------|----------|--------|
| **Target** | Prototype, MVP, internal tool, learning | Production SaaS, API, library | Regulated, fintech, healthcare, high-stakes |
| **Story-cycle** | Plan (optional for SMALL) -> Build -> Verify | Full 8-phase workflow | Full 8-phase, no fast-tracking even for TRIVIAL |
| **Quality gates** | Code (lint+complexity) | Code + Tests + Security | All 5 agents + integration-tester |
| **Sprint ceremony** | Create branch, build, PR | Full: spec, planning, retrospective | Full + mandatory audit trail |
| **Docs generated** | CLAUDE.md + progress.md | Full docs/reference/ suite | Full + audit trail + compliance docs |
| **Skills visible** | ~12 core | ~25 skills | All 39+ skills |
| **TDD enforcement** | Standard (block without tests for non-trivial) | Standard | Strict (block + require coverage delta >= 0) |
| **Hook profile** | minimal | standard | strict |
| **Stop iterations** | 5 (default) | 5 (default) | 10 (more verification passes) |

### 2. Storage Mechanism

**Primary:** `**Profile:** lean|standard|strict` line in CLAUDE.md (Project Overview section).
- Always loaded into context, readable by skills (markdown, not scripts)
- Shared via git (team-wide consistency)
- Human-readable and human-editable

**Override:** `EXOSUIT_PROJECT_PROFILE` environment variable (session-level).
- Takes precedence over CLAUDE.md
- For temporary needs (e.g., strict mode for a sensitive feature on a standard project)
- Set in `.claude/settings.local.json` (per-user, gitignored)

**Resolution order:** env var > CLAUDE.md > default (standard)

### 3. Hook Profile vs Project Profile

Two separate concepts:
- `EXOSUIT_PROJECT_PROFILE` (lean/standard/strict) — controls **skill** behavior (ceremony depth, agent dispatch, doc generation)
- `EXOSUIT_HOOK_PROFILE` (minimal/standard/strict) — controls **hook** behavior (which hooks run based on minimum profile)

Default mapping (project -> hook):
- lean -> minimal
- standard -> standard
- strict -> strict

Both independently overridable. A developer on a lean project can set `EXOSUIT_HOOK_PROFILE=strict` for personal rigor without changing the project profile.

### 4. Profile Detection in Skills

Skills are markdown, not scripts. They read the profile from CLAUDE.md's `**Profile:**` line using the existing `<IF condition="...">` control flow markers (already used in doctor, sprint-end, architecture-check, etc.):

```markdown
<IF condition="Profile is lean">
Skip quality agent dispatch. Run lint + test only.
</IF>
```

### 5. Profile Detection Heuristics (Bootstrap)

**Strict indicators** (2+ = recommend Strict):
- Compliance files: HIPAA, SOC2, PCI-DSS, GDPR references
- Domain: fintech, healthcare, insurance, payments
- Multi-service: docker-compose with 3+ services, k8s/, terraform/
- Strict CI: branch protection, required reviewers

**Standard indicators** (default):
- CI/CD configured, test framework present, >5K LOC, deployment configs

**Lean indicators** (ALL must be true):
- No CI/CD, no test framework, <2K LOC, no deployment config

### 6. Constraints

- No different install.sh paths — same install, profile set afterward
- Switchable after bootstrap — projects evolve
- Overridable per-session — for temporary needs
- Profile changes don't break project state
- Safety is never reduced — Lean is less ceremony, not less safe

### 7. Migration Path

Existing projects: No `**Profile:**` line = `standard`. Zero behavioral change.
New projects: Bootstrap recommends a profile during setup.
Switching: Edit CLAUDE.md or set env var. No migration steps needed.
