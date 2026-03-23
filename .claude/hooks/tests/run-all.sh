#!/usr/bin/env bash
# Run all hook tests
set -euo pipefail

cd "$(dirname "$0")"

echo "Hook Test Suite"
echo "==============="
echo ""

TOTAL_PASS=0
TOTAL_FAIL=0

for test_file in test-*.sh; do
    bash "$test_file"
    echo ""
done

echo "All hook tests complete."
