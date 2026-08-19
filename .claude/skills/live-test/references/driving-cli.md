# Driving Guide — CLI Surface (run the binary)

How to test a running CLI tool end-to-end. Project specifics (invocation command,
subcommands, fixtures, timing budgets) come from `docs/testing/APP_MAP.md`.

## The probe

A scenario's probe is invoking the tool exactly as a user would:

```bash
cd <project-root> && <invocation from app map> <args> < <stdin fixture if any>
```

- Run from the directory the app map declares; capture stdout, stderr, and exit code
  separately.
- Timeouts from the app map's timing budgets (wrap long commands with `timeout <s>`).
- Work in a scratch area for anything that writes files: copy fixtures into a temp
  directory first so runs are repeatable and the repo stays clean.
- Interactive prompts: drive with piped input (`printf 'answer\n' | <cmd>`); if the
  tool has a non-interactive flag (`--yes`, `--no-input`), prefer testing BOTH modes.
- Long-running/watch modes: launch in background, verify the expected output appears,
  then terminate cleanly.

## Three-signal verification (run after EVERY scenario)

| Signal | Source | Pass condition |
|--------|--------|----------------|
| 1. Exit code | `$?` | Matches expectation (0 for success scenarios; documented non-zero for error scenarios) |
| 2. Output | stdout + stderr | Expected content present on the right stream; no unexpected warnings/tracebacks (ignore known noise from the map § Known issues) |
| 3. Side effects | filesystem / config / target state | Files created/modified as expected (or NOT, for dry-run and validation tests): diff the scratch area before/after |

Never declare PASS from exit code alone — a 0 exit with wrong output or a missing/extra
side effect is a false pass.

## Scenario anatomy

Each scenario declares: `id · invocation · stdin/fixtures · expected exit · expected
output assertions · expected side effects`.

- **Error scenarios**: bad flags, missing args, unreadable input — expect a non-zero
  exit, a helpful message on stderr, and NO partial side effects.
- **Help/version**: `--help`/`--version` are cheap first scenarios and double as the
  "does it start?" smoke check.
- **Edge cases**: empty input, huge input, unicode/spaces in paths, re-running the same
  command (idempotency), interrupted runs (Ctrl-C mid-write → no corrupt state).

## Safety

- Only invoke the project's own tool and the fixtures/scratch area — a scenario must
  never touch files outside the project root and the scratch directory.
- Destructive subcommands (delete, overwrite, deploy) run only against scratch
  fixtures, and only if the approved plan lists them explicitly.

## Failure evidence bundle

When a scenario fails, capture:

1. The exact invocation (command line, cwd, stdin) — reproducible one-liner
2. Exit code + full stderr, stdout excerpt → `docs/testing/findings/assets/<run-id>/<scenario-id>.txt`
3. Side-effect state: the before/after diff of the scratch area
4. Environment note: tool version (`--version`) and any env vars the scenario set
