# Team Workflow Guide

How to use the Exosuit framework with a team of 2–15 developers. AI-assisted development shifts the bottleneck from code production to code verification — this guide structures your team around that reality.

## Branch Strategy

Each developer works in an isolated git worktree on a short-lived feature branch:
```
main
├── feature/S42-auth-login    (Dev A — worktree: ~/project-wt-auth)
├── feature/S43-payment-flow  (Dev B — worktree: ~/project-wt-pay)
└── feature/S44-ui-dashboard  (Dev C — worktree: ~/project-wt-ui)
```

- **Worktrees over branch switching** — each AI session gets its own working directory, preventing cross-session interference
- **Short-lived branches only** — merge within the sprint; long-lived branches diverge catastrophically with AI velocity
- Squash-merge to main via PR to keep history clean
- Use `/parallel-work` to set up worktrees automatically

## Sprint Lifecycle for Teams

### Sprint Planning — Decompose for Parallelism
Break stories into tasks that touch **non-overlapping file sets**. Identify convergence-point files (routes, configs, registries) and assign a single owner per file. Write a brief spec for each story before AI implementation: what it does, how it interacts with existing systems, and acceptance criteria.

### During Sprint — Isolate and Document
- Each developer works in their own worktree on their own branch
- AI sessions receive the project's `CLAUDE.md` and relevant ADRs as context
- At session end, write a **2–3 sentence session summary** in the PR description: what was decided, what alternatives were rejected, what the AI struggled with
- For critical decisions, create an ADR in `docs/adr/`
- Cap AI-generated PRs at **200 lines changed** — use stacked PRs for larger work

### Sprint-End — Team Review Checkpoint
`/sprint-end` triggers the human review gate (see "Code Review Process" below). Additionally, hold a **30-minute architecture sync** to:
- Check for **agentic drift** — semantically incompatible implementations that merged cleanly
- Review architectural consistency across all sprint PRs
- Update `CLAUDE.md` with new patterns or anti-patterns discovered
- Run retrospective with an explicit "AI learnings" section

## AI Agent Governance

**Core principle: autonomy should be proportional to reversibility.** An AI agent can autonomously fix lint errors or update documentation. It must not autonomously modify database migrations, authentication logic, or payment flows without human review of both the plan and the implementation.

| Risk Level | Examples | Agent Autonomy | Review Required |
|------------|----------|---------------|-----------------|
| Low | Docs, formatting, config comments, typos | Full autonomy | Post-hoc review |
| Medium | Feature code, tests, refactoring | Implement freely, human verifies before merge | Before merge |
| High | Auth, payments, migrations, infrastructure, security | Spec-only — human reviews plan AND implementation | Before AND after |

**Concurrent session ceiling:** Cap at **5–7 active AI agent sessions** across the team. Beyond this threshold, merge complexity and review bottleneck consume productivity gains. This applies to both a solo developer running multiple worktrees and a team of developers each running their own sessions.

## Code Review Process

Four-layer defense with clear responsibility boundaries. Each layer catches issues the previous one misses.

### Layer 1 — Pre-commit (automated, instant)
Formatters and linters run before code leaves the developer's machine. Catches ~40% of surface issues. Include architectural boundary rules in linter config.

### Layer 2 — CI Gate (automated, 2–10 min)
Full static analysis, security scanning, type checking, full test suite, dependency vulnerability scanning. **Blocks merge on any failure.** Checks for hallucinated packages and known CVEs.

### Layer 3 — AI Review (automated, on PR)
`.github/workflows/claude-pr-review.yml` analyzes the diff against codebase context. Catches contextual issues: abstraction bypass, code duplication of existing utilities, naming inconsistencies. Treat AI review comments as suggestions for human attention.

### Layer 4 — Human Review (15–30 min per 200-line PR)
Humans focus on what automation cannot catch:
- **Architecture alignment** — fits system design and documented ADRs?
- **Business logic** — solves the right problem?
- **Intent verification** — matches the spec?
- **Security threat modeling** — auth, authz, PII, payment flows
- **Over-engineering** — solving hypothetical future problems?
- **Comprehension check** — can the author explain every significant decision?

### Scrutiny Gap
Research shows developers accept AI suggestions with **less scrutiny** than they would from a human colleague. Counter this by treating AI-generated PRs as if they came from a capable but new team member — helpful but unproven. The checklist below exists specifically for this reason.

### AI-Specific Review Checklist
For every PR with AI-generated code, verify:

| # | Check | Why |
|---|-------|-----|
| 1 | No phantom packages (all deps exist in registry) | 19.7% of AI-suggested packages don't exist |
| 2 | Uses project wrappers, not raw libraries | AI bypasses abstractions and uses underlying libs |
| 3 | No duplicated utilities (grep for similar functions) | AI reimplements instead of reusing existing code |
| 4 | Tests verify behavior, not implementation | AI writes tautological tests that mock and assert the same values |
| 5 | No deprecated API usage | Models trained on historical code suggest outdated APIs |
| 6 | No over-engineering or excess abstraction | 80–90% of AI repos show over-engineering |
| 7 | No filler comments or obvious narration | 90–100% of AI repos have excessive comments |
| 8 | Secrets not leaked in code or config | 40% higher secret leakage rate with AI assistance |

### PR Template
PRs should include:
```markdown
## Intent
<!-- 1-2 sentences: what this PR does and why -->

## Proof it works
<!-- Test output, screenshots, or verification evidence -->

## AI disclosure
<!-- AI-assisted: [components]. Human-written: [components] -->

## Review focus
<!-- What specifically needs human attention -->
```

## Knowledge Sharing

Counteract session amnesia — every AI session creates knowledge that vanishes when the session ends.

### Three Required Artifacts
1. **`CLAUDE.md`** (under 150 lines of project-specific content): code style, architectural constraints, build/test commands, known AI pitfalls for this codebase
2. **`docs/adr/`**: lightweight ADRs capturing the "why" behind significant choices — especially when AI proposed the approach. Prevents AI from re-litigating decided architecture
3. **Sprint retrospective notes** with "AI learnings" section: what prompting strategies worked, what anti-patterns appeared, what rules to add to `CLAUDE.md`

### Multi-Tool Team Context
If your team uses multiple AI coding tools (Claude Code, Copilot, Cursor, Windsurf, etc.), the framework creates an `AGENTS.md` symlink pointing to `CLAUDE.md`. This provides a universal context file — adopted by 60,000+ open-source projects under the Linux Foundation — consumed by all major AI coding assistants. Keep combined project-specific content under **150 lines**; bloated context files degrade AI performance and increase inference costs.

### Session Summaries
When closing an AI session that produced a PR, add to the PR description:
- What was decided and why
- What alternatives were rejected
- What the AI struggled with or got wrong

This is the minimum viable knowledge transfer. Without it, the next developer (or future you) re-discovers everything from scratch.

## Backlog Coordination

### Epic Ownership
Assign epics to developers in epic files:
```markdown
**Owner:** @developer-name
**Sprint:** sprint-42
```

### Story Locking
Mark stories `IN_PROGRESS` in the epic file and commit the change. This signals to other developers that the story is taken.

### Conflict Prevention
- Stories should touch distinct files (cohesion-sized stories keep file footprints focused)
- Assign convergence-point files (routes, configs) to a single owner
- Use `/parallel-work` with worktrees for concurrent stories
- If stories overlap, coordinate via the dependency graph in `/ideate` output

## Scaling Guide

### Small Teams (2–5 developers)
Minimal overhead — AI is a pure force multiplier at this size.
- Async-first with a single 15-min daily sync
- Shared `CLAUDE.md` committed to git — everyone updates it
- Informal code ownership — everyone reviews everything
- Session summaries in PR descriptions
- ADRs when AI suggests structural changes
- Real-time conflict avoidance in team chat ("I'm refactoring auth")

### Medium Teams (5–15 developers)
Review becomes the bottleneck — invest in structure.
- **Formal CODEOWNERS** mapping directories to team members (see `.github/CODEOWNERS`)
- **Stacked PR workflow** with 200-line caps on AI-generated PRs
- **Mandatory AI disclosure** in PR template for all PRs
- **Weekly 30-min architecture sync** to review AI-suggested patterns
- **Rotating AI review lead** each sprint — one reviewer focused on AI anti-patterns
- **Sub-team decomposition** at 10+: split into 2–3 sub-teams of 4–5 with clear domain boundaries
- **Shared prompt templates** for common tasks, versioned in the repo
- **Comprehension debt tracking** — 59% of developers ship AI code they don't fully understand; in retrospectives, ask: "Can every team member explain the code they merged?" Schedule code walkthroughs where the answer is no
- **Cost monitoring** — at 5+ developers ($200–500/dev/month), track cost per PR merged and cost per feature delivered to justify AI tooling investment
- **Training investment** — teams without AI workflow training see 60% lower gains

## CODEOWNERS Setup

`.github/CODEOWNERS` ships with framework defaults covering critical paths. For teams:

```
# Default — all files require team review
*                           @your-team

# Critical paths — require domain expert review
**/auth/**                  @security-lead
**/tests/**                 @test-lead
docs/architecture/**        @tech-lead
docs/adr/**                 @tech-lead
docs/reference/GROUND_RULES.md  @tech-lead

# Framework config — affects all developers
.claude/**                  @tech-lead
```

Replace `@your-team` and role placeholders with actual GitHub usernames or team handles. `/bootstrap` detects team projects and suggests this configuration.

## Integration Points

| Framework feature | Team behavior |
|-------------------|--------------|
| `/bootstrap` | Detects team (multiple contributors or CODEOWNERS exists), recommends tier-specific practices |
| `/sprint-end` | Runs four-layer review, PR size check, detects required human reviewers, guides Layer 4 focus |
| `/story-cycle` | Stories scoped by cohesion to focused file footprints — natural conflict prevention |
| `/parallel-work` | Sets up worktrees for concurrent development |
| `/handoff` + `/continue` | Structured context transfer between developers, PR session summaries, agentic drift detection |
| `/retrospective` | Team reviews AI learnings, comprehension debt, updates `CLAUDE.md` |
| `GROUND_RULES.md` | Shared architectural principles — changes require PR review |
| `docs/progress.md` | Shared sprint visibility — updated by `/sprint-end` |
