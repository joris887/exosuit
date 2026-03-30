# Hooks Directory

POSIX shell hook scripts with text-based rule configuration. No Python or other runtime required.

- Each hook event has its own `.sh` script (self-contained)
- Rules in `rules/*.patterns` (@@-delimited) and `rules/*.conf` (key=value)
- State in `state/` directory (plain text files: counters, timestamps)
- JSON extraction: tries `jq`, falls back to `sed` (no hard dependency on jq)
- Profile gating via `lib/hook-guard.sh` and `JD_HOOK_PROFILE` env var

## Adding a new hook:
1. Create `<event-name>.sh` (POSIX sh) that reads JSON from stdin
2. Add `"$HOOKS_DIR/lib/hook-guard.sh" "<hook-id>" "<min-profile>" || exit 0` near the top
3. Add rules in `rules/<name>.patterns` if needed
4. Register the event in `.claude/settings.json`
5. Document in README.md

See README.md for full hook documentation including profiles, runtime disabling, and pattern severity.

## Hook Guard

All hooks call `lib/hook-guard.sh` to check:
- `JD_HOOK_PROFILE` (minimal/standard/strict) — skips hooks below the current profile
- `JD_DISABLED_HOOKS` (comma-separated IDs) — skips individually disabled hooks
- `JD_EXPLAIN_MODE` (off/brief/verbose) — controls message verbosity (brief = default)
- `JD_STOP_MAX_ITERATIONS` — overrides stop hook safety valve (default 5, ≤0 = no limit)

## Performance
- Pre-edit and post-edit hooks MUST complete in <5 seconds — slow hooks get disabled
- Use staged-only file checks, not full repo scans
- Format only the edited file, not the entire project
- If a hook consistently exceeds 5s, split into fast (local hook) and comprehensive (CI) checks
