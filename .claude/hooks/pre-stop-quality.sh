#!/usr/bin/env bash
# Pre-stop hook: Run quality suite before Claude reports completion.
# If any check fails, Claude must fix the issue before completing.
#
# Customize the commands below based on your project's stack.
# /bootstrap will configure these for your detected tools.

ERRORS=0

# Run linter (if configured)
# Uncomment and customize for your project:
# echo "Running linter..."
# npm run lint 2>&1 || ERRORS=$((ERRORS + 1))
# ruff check . 2>&1 || ERRORS=$((ERRORS + 1))
# cargo clippy 2>&1 || ERRORS=$((ERRORS + 1))

# Run type checker (if configured)
# echo "Running type checker..."
# npx tsc --noEmit 2>&1 || ERRORS=$((ERRORS + 1))
# mypy . 2>&1 || ERRORS=$((ERRORS + 1))

# Run tests
# echo "Running tests..."
# npm test 2>&1 || ERRORS=$((ERRORS + 1))
# pytest 2>&1 || ERRORS=$((ERRORS + 1))
# cargo test 2>&1 || ERRORS=$((ERRORS + 1))

if [ $ERRORS -gt 0 ]; then
    echo "QUALITY GATE FAILED: $ERRORS check(s) failed. Fix issues before completing."
    exit 1
fi

exit 0
