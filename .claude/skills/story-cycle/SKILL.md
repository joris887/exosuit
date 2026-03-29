---
name: story-cycle
version: 4.5.0
description: Use when the user wants to implement a single story or deliver a backlog item.
trigger: manual
depends-on: [code-quality, test-validator, security-audit]
requires: [git]
optional-requires: [test-command, lint-command, typecheck-command]
references: [references/story-types.md, references/self-review.md, references/disaster-prevention.md, references/reasoning-tools.md, references/elicitation-techniques.md, references/error-recovery.md, references/plan-template.md, references/parallel-streams.md, references/phase-0-intent.md, references/phase-1-planning.md, references/phase-3-execution.md, references/phase-4-verification.md]
micro-components:
  phase-0: [context-prime]
  phase-1: [discover-commands, verify-clean-git-state, wave-execution, grep-first-explore]
  phase-2: [confidence-gate]
  phase-4: [record-failure, quality-gate-sequence, capture-learnings, capture-outcome]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Edit, Write, WebSearch, WebFetch, Agent
argument-hint: "<story-description-or-id>"
---
______________________________________________________________________

## story-cycle

Delivering story: **$ARGUMENTS**

```bash
echo "{\"type\":\"skill\",\"event\":\"start\",\"skill\":\"story-cycle\",\"story\":\"$ARGUMENTS\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl
```

## Process Flow (authoritative)

```
START → Phase 0: Intent Decomposition (identify ALL deliverables, mark uncertainties)
  → Size Classification:
    → [TRIVIAL] → Phase 3-lite → DONE
    → [SMALL]   → Lightweight Phase 1 (skip 1f-1g) → Phase 2 → Phase 3 → Phase 4 → DONE
    → [STANDARD] → Full Phase 0-4:
      → Phase 1: Plan Mode (research, type, plan — *** HARD-GATE: Research Decision block ***)
        → [User approved?] → NO: Revise → YES: Continue
      → Phase 2: Context Transition + Confidence Gate (≥85 proceed, 70-84 clarify, <70 re-plan)
      → Phase 3: Execute (*** HARD-GATE: TDD — tests BEFORE implementation ***)
      → Phase 4: Verify (*** HARD-GATE: all quality gates pass, evidence for every AC ***)
        → [All criteria met?] → NO: Fix (max 2 passes) → YES: Report → DONE
```

## Phase 0: Intent Decomposition

Read `references/phase-0-intent.md` for: backlog lookup (0a), sprint context (0a.5), PRD scope guard (0b), scope analysis (0c).

## Size & Risk Classification

| Size | Criteria | Workflow |
|------|----------|----------|
| **TRIVIAL** | Single file, <10 lines, no behavioral change | Phase 3-lite → DONE |
| **SMALL** | Single file, <50 lines, clear AC, no external deps | Lightweight Phase 1 → Phase 2-4 |
| **STANDARD** | Everything else | Full Phase 0-4 |

**Guard rails:** TRIVIAL + multiple files → reclassify SMALL. SMALL + unclear AC or research needed → reclassify STANDARD.

### Phase 3-lite (TRIVIAL only)

1. Make the change
2. Run tests (if test command configured)
3. Abbreviated self-review: Does the diff match intent? Any unintended side effects?
4. Commit with conventional format
5. Print completion report

### Risk Classification (modifies workflow depth)

Score each dimension 1-3, sum for total:

| Dimension | 1 (Low) | 2 (Medium) | 3 (High) |
|-----------|---------|-----------|----------|
| **Domain risk** | Well-understood, internal-only | Some external integration | Security, payments, auth, data |
| **Integration surface** | Isolated module | Touches 2-3 modules | Cross-cutting concern |
| **Reversibility** | Easy rollback, feature flag | Moderate (migration, schema) | Hard to reverse (data loss, API contract) |

| Score | Level | Workflow modification |
|-------|-------|----------------------|
| 3-4 | **Low** | Lightweight quality checks |
| 5-6 | **Medium** | All quality agents + integration-tester |
| 7-9 | **High** | All agents + architecture-check + mandatory research |

**Historical calibration:** If previous stories in same module (check `docs/sessions/.story-outcomes.tsv`) had CFR >15%, bump risk one level. **Sprint context modifier:** Goal-critical stories treat ambiguous risk as one level higher.

## Phase 1: Story Analysis (Plan Mode)

Read `references/phase-1-planning.md` for full details: type identification (1a), codebase exploration (1b), research (1c), online verification (1c.5), dependency freshness (1c.5+), skills (1d), discovery gate (1d.5), refinement (1d.7), plan writing (1e), clarification (1f), completeness (1g), depth check (1h).

<HARD-GATE>
Phase 1c.5: MUST print a Research Decision block before proceeding to 1d.
Do NOT write implementation code until the plan is presented and user has explicitly approved it.
</HARD-GATE>

<HARD-GATE>
**POST-PLAN-MODE EXECUTION — THIS IS NOT OPTIONAL**

When you exit Plan Mode (ExitPlanMode) during a story-cycle, you are NOT done. Planning is only Phase 1 of 4. After Plan Mode exits, you MUST:
1. Read the plan's `remaining_steps` to get your execution checklist
2. Re-read this skill file from Phase 2 onwards
3. Continue executing Phase 2 → 3 → 4 → Completion Report

The plan approval is a checkpoint, not the finish line.
</HARD-GATE>

## Phase 2: Context Transition + Confidence Gate

### 2a. Context Pruning

**KEEP:** Approved plan (with Story-Cycle Context header), file paths, edge cases/gotchas, pattern snippets.
**DISCARD:** Full file contents from exploration, dead-end investigations, irrelevant search results.
**RELOAD for Phase 3:** Target source/test files. From `CODING_STANDARDS.md` load ONLY the story's language section + Universal Conventions + AI-Specific Anti-Patterns. From `TESTING_STRATEGY.md` load ONLY Test Infrastructure + the matching story-type section.
**SKIP until Phase 4:** progress.md, ARCHITECTURE.md, backlog files, GROUND_RULES.md (already checked in 1e).

### 2b. Confidence Gate

Run `confidence-gate` micro-component from `.claude/prompts/confidence-gate.md`. Score 5 dimensions (ambiguity, architecture, patterns, test strategy, dependencies) 0–20 each.

| Total | Action |
|-------|--------|
| **85–100** | Proceed to Phase 3 |
| **70–84** | Flag low dimensions, ask user, re-score |
| **< 70** | Return to Phase 1 |

<HARD-GATE>
Do NOT skip the confidence gate. Output the 5-dimension score table before proceeding.
</HARD-GATE>

## Phase 3: Execute by Story Type

Read `references/phase-3-execution.md` for full details: parallel streams (3a), git checkpoint (3.pre), intermediate commits, story-type dispatch, web-assisted error recovery.

<HARD-GATE>
**TDD Ordering Enforcement (Feature, Bug Fix, Refactoring):** You MUST write and run test code BEFORE writing implementation code. The first Edit/Write to a source file MUST be preceded by Edit/Write to a test file AND a Bash call running the test. Exceptions: Spike/Research, Infrastructure, Documentation, Testing, Performance, Security, Skill/Tooling.
</HARD-GATE>

## Phase 4: Verify + Wrap Up

Read `references/phase-4-verification.md` for full details: self-review + disaster prevention (4a), quality gates (4b), UAT generation (4c), UAT sense check (4c.1), completion verification (4d), docs + commit (4e).

<HARD-GATE>
Do NOT skip self-review for ANY story size. Do NOT proceed past quality gates until ALL pass with zero failures (show output). Do NOT print completion report until every AC has evidence.
</HARD-GATE>

### Completion Report

```markdown
### Story Complete

**Story:** [description]
**Type:** [story type]
**Approach:** [methodology used]
**Files modified:** [list]
**Tests:** [count] passing, [new tests added]
**Commit:** [hash and message]
**Verification:** [All N acceptance criteria verified — see evidence above]

**Next Steps:**
→ `/story-cycle "[next story from backlog]"` — deliver the next story
→ `/sprint-end` — if this was the last story in the sprint
→ `/handoff` — if ending the session
```

## Recovery

For phase-specific recovery, consult `references/error-recovery.md` (search for `## Phase N`).

- **Test failure (new code):** Fix implementation, re-run. Do not weaken the test.
- **Test failure (pre-existing):** Inform user. Log to `docs/technical-debt.md` if out of scope.
- **Context exhaustion:** Save to `docs/plans/`, commit WIP, new session with `/continue`.
- **Git conflict:** Show to user. Do NOT auto-resolve without approval.
- **Implementation fundamentally wrong:** Use checkpoint rollback (Phase 4d).

## Rules

- NEVER skip the plan phase — always plan first
- NEVER carry exploration context into execution — clear and reload
- NEVER merge to main or create a PR — that's sprint-end
- NEVER add features not in the acceptance criteria
- NEVER weaken or delete existing tests
- Follow `docs/reference/CODING_STANDARDS.md`, `docs/reference/TESTING_STRATEGY.md`, `docs/architecture/ARCHITECTURE.md`, `docs/reference/GROUND_RULES.md`
