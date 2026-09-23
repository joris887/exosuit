#!/bin/sh
# test-paths.sh — single source of truth for "is this path a test file?"
#
# Consumed by BOTH flow-pre-edit.sh (test edits are exempt from gate checks)
# and post-tool-use.sh (test edits stamp the test-written evidence marker).
# One list feeding both sides guarantees the invariant that makes block mode
# safe: any edit exempted as a test also stamps the evidence — writing the
# test the gate demands can never itself be blocked.
#
# Usage: sh .claude/hooks/lib/test-paths.sh <path>
#   exit 0 -> test path; exit 1 -> not a test path
#
# Patterns are case-insensitive globs, pipe-separated. Projects can override
# via test_path_patterns in .claude/hooks/rules/quality.conf (MERGE-strategy
# config). Defaults cover: pytest/unittest, Jest/Vitest (__tests__, .test.,
# .spec.), RSpec/Elixir/Lua (_spec., spec/), Go/C/Java (_test., test/,
# tests/), Perl (.t), Cucumber (.feature), Cypress/Playwright (e2e/),
# C#/.NET (.tests/ via case folding), pytest conftest. Inline-test
# languages (Rust #[cfg(test)], Elixir doctests/inline ExUnit) are caught
# by a content check when no path pattern matches — see the carve-out at
# the bottom.
# POSIX-compliant — no bash required.

HOOKS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
QUALITY_CONF="$HOOKS_DIR/rules/quality.conf"

DEFAULT_PATTERNS='test_*|*/test_*|*_test.*|*.test.*|*.spec.*|*_spec.*|tests/*|*/tests/*|test/*|*/test/*|spec/*|*/spec/*|*__tests__/*|conftest.py|*/conftest.py|*.t|*.feature|e2e/*|*/e2e/*|*.tests/*'

PATTERNS="$DEFAULT_PATTERNS"
if [ -f "$QUALITY_CONF" ]; then
    CONF_PATTERNS=$(grep '^test_path_patterns=' "$QUALITY_CONF" 2>/dev/null | head -1 | sed 's/^test_path_patterns=//')
    [ -n "$CONF_PATTERNS" ] && PATTERNS="$CONF_PATTERNS"
fi

# Case-insensitive: fold BOTH path and patterns to lowercase (covers
# Foo.Tests/ in paths and *.Tests/* in user overrides alike)
PATH_LC=$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')
[ -n "$PATH_LC" ] || exit 1
PATTERNS=$(printf '%s' "$PATTERNS" | tr '[:upper:]' '[:lower:]')

# set -f: the patterns are GLOBS — without noglob, the unquoted $PATTERNS
# expansion would match them against the CURRENT DIRECTORY's files (any repo
# with an existing tests/ dir would destroy the patterns and re-open the
# block-mode deadlock this file exists to prevent).
set -f
OLD_IFS="$IFS"
IFS='|'
MATCHED=1
for pat in $PATTERNS; do
    # shellcheck disable=SC2254
    case "$PATH_LC" in
        $pat) MATCHED=0; break ;;
    esac
done
IFS="$OLD_IFS"
set +f

# --- Inline-test carve-out (content-based) ---
# Rust and Elixir put tests IN source files. If no path pattern matched,
# a .rs file containing #[cfg(test)] — or an .ex/.exs containing an
# inline ExUnit case or doctest — still counts as a test file, for BOTH
# the gate exemption and the test-written stamp (this file is the single
# source of truth for both sides, so the exempt⟺stamps invariant holds
# by construction). One grep of one file; fail-open when the file does
# not exist yet — a Write CREATING a new inline-test file cannot be
# content-checked at PreToolUse time, so it gets at most one advisory
# and then stamps at PostToolUse (never a block: test-written has no
# red analog).
if [ "$MATCHED" -ne 0 ] && [ -f "${1:-}" ]; then
    case "$PATH_LC" in
        *.rs)       grep -q '#\[cfg(test)\]' "$1" 2>/dev/null && MATCHED=0 ;;
        *.ex|*.exs) grep -qE 'doctest |use ExUnit\.Case' "$1" 2>/dev/null && MATCHED=0 ;;
    esac
fi
exit "$MATCHED"
