#!/usr/bin/env bash
# Test suite for session-start.sh — Unicode detection with BSD/GNU grep compatibility
set -euo pipefail

PASS=0
FAIL=0

test_case() {
    local desc="$1"
    local expected="$2"
    local actual="$3"

    if [ "$actual" = "$expected" ]; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected '$expected', got '$actual')"
        FAIL=$((FAIL + 1))
    fi
}

echo "Testing session-start.sh Unicode detection"
echo "============================================"

TMPDIR_TEST=$(mktemp -d)
trap "rm -rf $TMPDIR_TEST" EXIT

# --- Unicode detection using multiple -e flags (BSD/GNU compatible) ---
echo ""
echo "  -- Unicode anomaly detection --"

# Create test file with zero-width space (U+200B = \xe2\x80\x8b)
printf '# Normal rule\n\xe2\x80\x8bHidden instruction\n' > "$TMPDIR_TEST/poisoned.md"

# Create clean file
printf '# Normal rule\nNormal content\n' > "$TMPDIR_TEST/clean.md"

# Test using the same pattern the hook uses: multiple -e flags
DETECT_POISONED=$(grep -rl \
    -e "$(printf '\xe2\x80\x8b')" \
    -e "$(printf '\xe2\x80\x8c')" \
    -e "$(printf '\xe2\x80\x8d')" \
    "$TMPDIR_TEST/poisoned.md" 2>/dev/null || echo "")

DETECT_CLEAN=$(grep -rl \
    -e "$(printf '\xe2\x80\x8b')" \
    -e "$(printf '\xe2\x80\x8c')" \
    -e "$(printf '\xe2\x80\x8d')" \
    "$TMPDIR_TEST/clean.md" 2>/dev/null || echo "")

test_case "Detect zero-width space in poisoned file" "true" "$([ -n "$DETECT_POISONED" ] && echo true || echo false)"
test_case "No detection in clean file" "true" "$([ -z "$DETECT_CLEAN" ] && echo true || echo false)"

# Test zero-width non-joiner (U+200C = \xe2\x80\x8c)
printf '# Rule\xe2\x80\x8c override\n' > "$TMPDIR_TEST/zwnj.md"
DETECT_ZWNJ=$(grep -rl -e "$(printf '\xe2\x80\x8c')" "$TMPDIR_TEST/zwnj.md" 2>/dev/null || echo "")
test_case "Detect zero-width non-joiner" "true" "$([ -n "$DETECT_ZWNJ" ] && echo true || echo false)"

# Test right-to-left override (U+202E = \xe2\x80\xae)
printf '# Rule \xe2\x80\xaehidden\n' > "$TMPDIR_TEST/rtlo.md"
DETECT_RTLO=$(grep -rl -e "$(printf '\xe2\x80\xae')" "$TMPDIR_TEST/rtlo.md" 2>/dev/null || echo "")
test_case "Detect right-to-left override" "true" "$([ -n "$DETECT_RTLO" ] && echo true || echo false)"

# Test left-to-right mark (U+200E = \xe2\x80\x8e)
printf '# Rule\xe2\x80\x8etext\n' > "$TMPDIR_TEST/ltrm.md"
DETECT_LTRM=$(grep -rl -e "$(printf '\xe2\x80\x8e')" "$TMPDIR_TEST/ltrm.md" 2>/dev/null || echo "")
test_case "Detect left-to-right mark" "true" "$([ -n "$DETECT_LTRM" ] && echo true || echo false)"

# Test file with multiple Unicode anomalies
printf '# Rule\xe2\x80\x8b with \xe2\x80\xae multiple \xe2\x80\x8c markers\n' > "$TMPDIR_TEST/multi.md"
DETECT_MULTI=$(grep -rl \
    -e "$(printf '\xe2\x80\x8b')" \
    -e "$(printf '\xe2\x80\x8c')" \
    -e "$(printf '\xe2\x80\xae')" \
    "$TMPDIR_TEST/multi.md" 2>/dev/null || echo "")
test_case "Detect multiple Unicode anomalies in one file" "true" "$([ -n "$DETECT_MULTI" ] && echo true || echo false)"

# Test ASCII-only file (no false positives)
printf '# Normal ASCII-only content\nWith normal text and symbols: @#$%%^&*()\n' > "$TMPDIR_TEST/ascii.md"
DETECT_ASCII=$(grep -rl \
    -e "$(printf '\xe2\x80\x8b')" \
    -e "$(printf '\xe2\x80\x8c')" \
    -e "$(printf '\xe2\x80\x8d')" \
    -e "$(printf '\xe2\x80\x8e')" \
    -e "$(printf '\xe2\x80\x8f')" \
    -e "$(printf '\xe2\x80\xae')" \
    "$TMPDIR_TEST/ascii.md" 2>/dev/null || echo "")
test_case "No false positive on ASCII-only file" "true" "$([ -z "$DETECT_ASCII" ] && echo true || echo false)"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
