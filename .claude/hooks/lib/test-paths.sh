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
# C#/.NET (.tests/ via case folding), pytest conftest.
# POSIX-compliant — no bash required.

HOOKS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
QUALITY_CONF="$HOOKS_DIR/rules/quality.conf"

DEFAULT_PATTERNS='test_*|*/test_*|*_test.*|*.test.*|*.spec.*|*_spec.*|tests/*|*/tests/*|test/*|*/test/*|spec/*|*/spec/*|*__tests__/*|conftest.py|*/conftest.py|*.t|*.feature|e2e/*|*/e2e/*|*.tests/*'

PATTERNS="$DEFAULT_PATTERNS"
if [ -f "$QUALITY_CONF" ]; then
    CONF_PATTERNS=$(grep '^test_path_patterns=' "$QUALITY_CONF" 2>/dev/null | head -1 | sed 's/^test_path_patterns=//')
    [ -n "$CONF_PATTERNS" ] && PATTERNS="$CONF_PATTERNS"
fi

# Case-insensitive: fold the path to lowercase (covers Foo.Tests/, Test_/ ...)
PATH_LC=$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')
[ -n "$PATH_LC" ] || exit 1

OLD_IFS="$IFS"
IFS='|'
for pat in $PATTERNS; do
    # shellcheck disable=SC2254
    case "$PATH_LC" in
        $pat) IFS="$OLD_IFS"; exit 0 ;;
    esac
done
IFS="$OLD_IFS"
exit 1
