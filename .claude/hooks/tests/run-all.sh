#!/usr/bin/env bash
# Usage: bash run-all.sh
#   Runs every test-*.sh file in this directory, each in its own bash process,
#   and accumulates the per-file results (a file has failed when it exits
#   non-zero). A failing file never stops the run: every file is reported.
#   Stdout:
#     Hook Test Suite
#     ===============
#     <each test file's own output>
#     Suite complete: <N> test files run, <M> failed.
#     Failing files: <file> [<file> ...]        (only when M > 0)
#   Exit 0 when M = 0, 1 when M > 0.
set -uo pipefail

cd "$(dirname "$0")" || exit 1

echo "Hook Test Suite"
echo "==============="
echo ""

RAN=0
FAILED=0
FAILING=""

for test_file in test-*.sh; do
    if bash "$test_file"; then
        RAN=$((RAN+1))
    else
        RAN=$((RAN+1))
        FAILED=$((FAILED+1))
        FAILING="$FAILING $test_file"
    fi
    echo ""
done

echo "Suite complete: $RAN test files run, $FAILED failed."
if [ "$FAILED" -gt 0 ]; then
    echo "Failing files:$FAILING"
    exit 1
fi
exit 0
