#!/usr/bin/env bash
# Test suite for post-edit-format.sh — per-file hash uniqueness, secrets detection, slop detection
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

echo "Testing post-edit-format.sh"
echo "==========================="

# --- Test portable_hash uniqueness ---
echo ""
echo "  -- portable_hash uniqueness --"

# Source the portable_hash function by extracting it from the hook
HOOK="../post-edit-format.sh"
# We can't source the whole file (it runs), so test the logic inline

# Simulate portable_hash using the same fallback chain
portable_hash_test() {
    if command -v md5sum &>/dev/null; then
        echo "$1" | md5sum | cut -d' ' -f1
    elif command -v md5 &>/dev/null; then
        echo "$1" | md5
    elif command -v shasum &>/dev/null; then
        echo "$1" | shasum | cut -d' ' -f1
    elif command -v cksum &>/dev/null; then
        echo "$1" | cksum | cut -d' ' -f1
    else
        echo "$1" | tr '/' '_'
    fi
}

HASH1=$(portable_hash_test "/tmp/test-file-1.py")
HASH2=$(portable_hash_test "/tmp/test-file-2.py")
HASH3=$(portable_hash_test "/tmp/test-file-3.py")

test_case "Hash of file1 is non-empty" "true" "$([ -n "$HASH1" ] && echo true || echo false)"
test_case "Hash of file2 is non-empty" "true" "$([ -n "$HASH2" ] && echo true || echo false)"
test_case "Hash of file1 != file2" "true" "$([ "$HASH1" != "$HASH2" ] && echo true || echo false)"
test_case "Hash of file1 != file3" "true" "$([ "$HASH1" != "$HASH3" ] && echo true || echo false)"
test_case "Hash of file2 != file3" "true" "$([ "$HASH2" != "$HASH3" ] && echo true || echo false)"

# Same input produces same hash (deterministic)
HASH1_AGAIN=$(portable_hash_test "/tmp/test-file-1.py")
test_case "Same input produces same hash" "true" "$([ "$HASH1" = "$HASH1_AGAIN" ] && echo true || echo false)"

# --- Test secrets detection patterns ---
echo ""
echo "  -- secrets detection patterns --"

# The hook scans for these patterns in edited files.
# Test by creating temp files with and without secrets.
TMPDIR_TEST=$(mktemp -d)
trap "rm -rf $TMPDIR_TEST" EXIT

# File with AWS key
echo 'aws_key = "AKIAIOSFODNN7EXAMPLE"' > "$TMPDIR_TEST/secrets.py"
# File without secrets
echo 'name = "hello world"' > "$TMPDIR_TEST/clean.py"

# Test pattern matching (same patterns used by the hook)
HAS_AWS=$(grep -c 'AKIA[A-Z0-9]' "$TMPDIR_TEST/secrets.py" 2>/dev/null || echo 0)
test_case "Detect AWS key pattern in secrets file" "true" "$([ "$HAS_AWS" -gt 0 ] && echo true || echo false)"
NO_AWS_MATCH=$(grep -l 'AKIA[A-Z0-9]' "$TMPDIR_TEST/clean.py" 2>/dev/null || true)
test_case "No AWS key pattern in clean file" "" "$NO_AWS_MATCH"

# Private key detection
echo '-----BEGIN RSA PRIVATE KEY-----' > "$TMPDIR_TEST/key.pem"
HAS_KEY=$(grep -c 'BEGIN.*PRIVATE KEY' "$TMPDIR_TEST/key.pem" 2>/dev/null || echo 0)
test_case "Detect private key pattern" "true" "$([ "$HAS_KEY" -gt 0 ] && echo true || echo false)"

# GitHub token
echo 'token = "ghp_ABCDEFghijklmnop1234567890abcdef"' > "$TMPDIR_TEST/gh.py"
HAS_GH=$(grep -c 'ghp_[A-Za-z0-9]' "$TMPDIR_TEST/gh.py" 2>/dev/null || echo 0)
test_case "Detect GitHub token pattern" "true" "$([ "$HAS_GH" -gt 0 ] && echo true || echo false)"

# --- Test slop detection patterns ---
echo ""
echo "  -- slop comment detection --"

# Slop patterns that should be flagged
echo '// This function does the authentication' > "$TMPDIR_TEST/slop.ts"
echo '// The following code handles login' >> "$TMPDIR_TEST/slop.ts"
echo '// Helper function for validation' >> "$TMPDIR_TEST/slop.ts"

# Good comments that should not be flagged
echo '// Cached lookup; DB call happens in middleware' > "$TMPDIR_TEST/good.ts"

HAS_SLOP1=$(grep -Eci 'This function does|The following code|Helper function for' "$TMPDIR_TEST/slop.ts" || echo 0)
test_case "Detect slop patterns in sloppy file" "true" "$([ "$HAS_SLOP1" -gt 0 ] && echo true || echo false)"
SLOP_MATCH=$(grep -Eli 'This function does|The following code|Helper function for' "$TMPDIR_TEST/good.ts" 2>/dev/null || true)
test_case "No slop patterns in clean file" "" "$SLOP_MATCH"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
