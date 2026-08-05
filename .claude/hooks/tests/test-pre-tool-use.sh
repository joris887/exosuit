#!/usr/bin/env bash
# Test suite for pre-tool-use.sh safety patterns
set -euo pipefail

HOOK="../pre-tool-use.sh"
PASS=0
FAIL=0

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

echo "Testing pre-tool-use.sh"
echo "========================"

# Override framework repo check so it doesn't interfere with safety pattern tests
export EXOSUIT_FRAMEWORK_REPO="nonexistent/repo-that-wont-match"

# Should BLOCK (exit 2)
test_case "Block git push --force" '{"command":"git push --force origin main"}' 2
test_case "Block git push -f" '{"command":"git push -f"}' 2
test_case "Block git checkout ." '{"command":"git checkout ."}' 2
test_case "Block git reset --hard" '{"command":"git reset --hard HEAD"}' 2
test_case "Block git clean -f" '{"command":"git clean -f"}' 2
test_case "Block rm -rf /" '{"command":"rm -rf /"}' 2
test_case "Block npm publish" '{"command":"npm publish"}' 2
test_case "Block DROP TABLE" '{"command":"psql -c \"DROP TABLE users\""}' 2

# Should ALLOW (exit 0)
test_case "Allow git push" '{"command":"git push origin feature/my-branch"}' 0
test_case "Allow git status" '{"command":"git status"}' 0
test_case "Allow npm test" '{"command":"npm test"}' 0
test_case "Allow rm file" '{"command":"rm src/old-file.ts"}' 0
test_case "Allow empty command" '{"command":""}' 0
test_case "Allow no command field" '{}' 0

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
