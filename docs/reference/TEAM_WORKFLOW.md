# Team Workflow Guide

How to use the JD-LLM Development Framework with a team of developers.

## Branch Strategy

Each developer creates their own sprint branches from main:
```
main
├── sprint-42  (Developer A — working on auth stories)
├── sprint-43  (Developer B — working on payment stories)
└── sprint-44  (Developer C — working on UI stories)
```

Branches are squash-merged to main via PR. The squash merge keeps main history clean while preserving detailed commit history in the PR.

## Code Review Workflow

### AI Review (Automatic)
- `/sprint-end` runs quality agents (code-quality, test-validator, security-audit, architecture-check)
- CI workflow (`.github/workflows/claude-pr-review.yml`) runs automated review on PRs
- Findings with confidence ≥80 are actionable

### Human Review (Recommended for Teams)
- Configure CODEOWNERS for critical paths (auth, security, test infra, deps)
- Enable branch protection rules in GitHub repo settings
- `/sprint-end` detects required reviewers and requests review automatically

### Review Priorities
| Path | Why Human Review | AI Review Catches |
|------|-----------------|-------------------|
| Auth/security code | Trust decisions, compliance | CWE patterns, injection, secrets |
| Test infrastructure | Test reliability affects all devs | Weakened assertions, deleted tests |
| Dependencies | Supply chain risk | Phantom packages, version issues |
| Architecture docs | Design decisions | Drift detection |

## Shared Ground Rules

`docs/reference/GROUND_RULES.md` defines architectural principles checked during:
- Story planning (Phase 1e of /story-cycle)
- Sprint shipping (/sprint-end quality gates)
- Retrospective review (/retrospective)

**For teams:**
- Ground rules are committed to the repo — all team members share them
- Changes to ground rules should go through PR review
- Use CODEOWNERS to require team review on GROUND_RULES.md changes
- `/sprint-end` records compliance in `docs/progress.md` — visible to all

## Backlog Coordination

### Epic Ownership
Assign epics to developers by adding an "Owner" field to epic files:
```markdown
**Owner:** @developer-name
**Sprint:** sprint-42
```

### Story Locking
When starting a story, mark it `IN_PROGRESS` in the epic file and commit the change. This signals to other developers that the story is being worked on.

### Conflict Prevention
- Each story should touch distinct files (the 5-8 file limit helps)
- Use `/parallel-work` with worktrees for concurrent stories on the same repo
- If stories overlap, coordinate via the dependency graph in `/ideate` output

## Communication Patterns

### Handoff Between Developers
Use `/handoff` to create structured session files. Another developer can use `/continue` to pick up context from the handoff.

### Shared Decisions
Use `docs/adr/` for Architecture Decision Records. These are committed to the repo and reviewed in PRs.

### Sprint Coordination
- `docs/progress.md` — shared sprint history
- `docs/reference/BACKLOG_INDEX.md` — shared story status
- `scripts/pm/status.sh` — quick sprint status check
