# Development Workflow Reference

Quick reference for session flows and skill sequencing. For skill details, see `.claude/skills/SKILLS_INVENTORY.md`.

## Session Startup

```
New session?
├── First time with this project?
│   └── YES → /bootstrap → /ideate → /sprint-start → /story-cycle
├── Continuing previous work?
│   └── YES → /continue (reads session handoff + git state)
│       ├── Mid-story? → Resumes from last phase
│       ├── Mid-sprint? → /story-cycle <next story>
│       └── Between sprints? → /sprint-start
└── New idea or requirement?
    └── /ideate <idea> → /sprint-start → /story-cycle
```

## Core Development Flow

```
/sprint-start
    ↓
/story-cycle <story>  ←── repeat for each story
    ↓
/sprint-end  →  PR → merge → done
```

### Sprint Start

Pre-flight checks: clean git state, default branch up to date, feature branch created.

### Story Cycle (per story)

```
Phase 0: Decompose intent, classify size/risk
Phase 1: Plan (research, online verify, refine, write plan) → user approval
Phase 2: Context transition (keep insights, discard bulk)
Phase 2.5: Confidence gate (score ≥85 to proceed)
Phase 3: Execute by story type (TDD, reproduce, characterize, etc.)
Phase 3.5: Self-review + disaster prevention
Phase 4: Quality gates, optional UAT, commit
Phase 4.5: Completion verification with evidence
```

### Sprint End

Quality gates → push → PR → squash merge → update progress.

## Testing Workflow

```
Development complete?
├── Ad-hoc exploratory testing
│   └── /manual-test → user tests → /testing-cycle <feedback> (repeat)
├── Structured UAT with tracked test cases
│   └── /UAT-cycle <test-case-id> (repeat per case)
└── Batch code logic verification of UAT cases
    └── /claude-sense-check (2-5 cases per run)
```

## Design & Planning

```
Vague idea?
├── Needs design exploration first
│   └── /brainstorm <idea> → /ideate <refined idea>
└── Ready to decompose into stories
    └── /ideate <requirement>
```

## Debugging

```
Bug or unexpected behavior?
└── /debug-session <error>
    Phase 1: Root cause investigation
    Phase 2: Pattern analysis
    Phase 3: Hypothesis testing
    Phase 4: Fix implementation (TDD)
    Phase 5: Verify + document
```

## Maintenance Schedule

| Frequency | Skill | Purpose |
|-----------|-------|---------|
| Per story | `/story-cycle` | Deliver one backlog item |
| Per sprint | `/sprint-end` | Ship sprint, quality gates, PR |
| Per sprint | `/retrospective` | 4Ls framework + metrics review |
| Weekly | `/weekly-maintenance` | Health check, dependency governance |
| As needed | `/backlog-review` | Backlog health analysis |
| As needed | `/doctor` | Framework health check |

## Session End

Always run `/handoff` before ending a session. Creates a structured handoff note in `docs/sessions/` that `/continue` reads on the next session.

## Parallel Development

For working on multiple stories simultaneously:

```
/parallel-work create <story-id>  →  creates isolated git worktree
/parallel-work list               →  shows active worktrees
/parallel-work cleanup            →  removes merged worktrees
```

Each worktree runs an independent Claude Code instance on a separate branch.
