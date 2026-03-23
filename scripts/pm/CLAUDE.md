# PM Scripts

Shell scripts for project management automation. Run from the project root.

## Scripts
- `metrics.sh` — collect sprint metrics (test count, coverage, duplication)
- `next-story.sh` — identify the next story to work on from the backlog
- `standup.sh` — generate standup summary from recent activity
- `status.sh` — show current sprint status and progress

## Conventions
- POSIX sh compatible — no bash-isms, no Python dependency
- Scripts read from `docs/` files (progress.md, backlog, sessions)
- Output is human-readable text, suitable for terminal display
- These are helper utilities, not enforcement — hooks handle enforcement
