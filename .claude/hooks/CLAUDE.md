# Hooks Directory

POSIX shell hook scripts with text-based rule configuration. No Python or other runtime required.

- Each hook event has its own `.sh` script (self-contained)
- Rules in `rules/*.patterns` (@@-delimited) and `rules/*.conf` (key=value)
- State in `state/` directory (plain text files: counters, timestamps)
- JSON extraction: tries `jq`, falls back to `sed` (no hard dependency on jq)

## Adding a new hook:
1. Create `<event-name>.sh` (POSIX sh) that reads JSON from stdin
2. Add rules in `rules/<name>.patterns` if needed
3. Register the event in `.claude/settings.json`
4. Document in README.md

See README.md for full hook documentation.

## Performance
- Pre-edit and post-edit hooks MUST complete in <5 seconds — slow hooks get disabled
- Use staged-only file checks, not full repo scans
- Format only the edited file, not the entire project
- If a hook consistently exceeds 5s, split into fast (local hook) and comprehensive (CI) checks
