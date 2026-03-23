#!/usr/bin/env bash
# Test suite for stop.sh completion evidence validation
set -euo pipefail

HOOK="../stop.sh"
PASS=0
FAIL=0

# Ensure clean state
rm -f ../state/stop-iteration ../state/tests-passed

test_case() {
    local desc="$1"
    local input="$2"
    local expected_exit="$3"
    
    actual_exit=0
    echo "$input" | sh "$HOOK" >/dev/null 2>/dev/null || actual_exit=$?
    
    if [ "$actual_exit" -eq "$expected_exit" ]; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected exit $expected_exit, got $actual_exit)"
        FAIL=$((FAIL + 1))
    fi
}

echo "Testing stop.sh"
echo "================"

# Reset state between tests
reset_state() {
    echo "0" > ../state/stop-iteration 2>/dev/null || true
    rm -f ../state/tests-passed 2>/dev/null || true
}

# Should BLOCK (claims done without evidence)
reset_state
test_case "Block 'done' without evidence" '{"last_assistant_message":"The implementation is done."}' 2

# Should ALLOW (has test evidence)
reset_state
test_case "Allow done with test output" '{"last_assistant_message":"Implementation complete. 15 tests passed."}' 0

# Should ALLOW (no completion claim)
reset_state
test_case "Allow non-completion message" '{"last_assistant_message":"Here is the code change I made."}' 0

# Should ALLOW (tests-passed state file exists)
reset_state
date -u +"%Y-%m-%dT%H:%M:%SZ" > ../state/tests-passed
test_case "Allow with tests-passed state" '{"last_assistant_message":"Implementation is done."}' 0

# Clean up
rm -f ../state/tests-passed

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
