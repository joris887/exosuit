#!/usr/bin/env bash
# Test suite for skill-create's init-skill.sh scaffold script
set -euo pipefail

PASS=0
FAIL=0
SCRIPT="$(cd "$(dirname "$0")/../.." && pwd)/skills/skill-create/scripts/init-skill.sh"

test_case() {
    local desc="$1" expected="$2" actual="$3"
    if [ "$actual" = "$expected" ]; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected '$expected', got '$actual')"
        FAIL=$((FAIL + 1))
    fi
}

echo "Testing init-skill.sh"
echo "====================="

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
cd "$TMP"
mkdir -p .claude/skills

rc=0; bash "$SCRIPT" my-tech >/dev/null 2>&1 || rc=$?
test_case "scaffold exits 0" "0" "$rc"
test_case "name substituted in frontmatter" "name: my-tech" "$(sed -n 2p .claude/skills/my-tech/SKILL.md)"
test_case "no placeholder left" "0" "$(grep -c SKILL_NAME_PLACEHOLDER .claude/skills/my-tech/SKILL.md || true)"
test_case "file still ends with a newline" "" "$(tail -c1 .claude/skills/my-tech/SKILL.md | tr -d '\n')"

rc=0; bash "$SCRIPT" my-tech >/dev/null 2>&1 || rc=$?
test_case "existing skill directory refused" "1" "$rc"

rc=0; bash "$SCRIPT" "../escape" >/dev/null 2>&1 || rc=$?
test_case "invalid name refused" "1" "$rc"
test_case "invalid name creates nothing" "false" "$([ -e .claude/escape ] && echo true || echo false)"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
