Run the quality gate sequence using commands from `CLAUDE.md`:

1. **Lint** (if configured): Run the lint command. Check exit code.
2. **Typecheck** (if configured): Run the typecheck command. Check exit code.
3. **Test** (if configured): Run the full test suite. Check exit code and verify zero failures.

For each gate:
- If the command exists: run it, report pass/fail with output
- If the command is NOT configured: skip with note "Not configured — skipping"

Stop on first failure unless explicitly told to continue. Report which gates passed and which failed.
