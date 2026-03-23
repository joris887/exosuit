# Sessions Directory

Session persistence layer for cross-session continuity.

## Files
- `session-YYYY-MM-DD.md` — handoff notes written by `/handoff` skill
- `.auto-save.md` — automatic state snapshot (branch, phase, plan, decisions)
- `.activity-log.jsonl` — rule/skill tracking events (append-only)

## How It Works
- `/handoff` writes a session file with accomplishments, blockers, next steps
- `/continue` reads the latest session file to restore context
- Pre-stop hook auto-saves state to `.auto-save.md` before session ends
- Rules emit tracking events to `.activity-log.jsonl` for retrospectives

## Conventions
- Session files are append-only — never edit previous sessions
- Keep handoff notes under 50 lines — they load into the next session's context
- `.auto-save.md` is overwritten each session (not cumulative)
