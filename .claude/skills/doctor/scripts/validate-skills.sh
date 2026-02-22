#!/usr/bin/env bash
set -euo pipefail

# validate-skills.sh — Check skill conformance against framework standards
# Usage: bash validate-skills.sh [--verbose]

if [[ "${1:-}" == "--help" ]]; then
  echo "Usage: bash validate-skills.sh [--verbose]"
  echo ""
  echo "Validates all .claude/skills/*/SKILL.md files against framework standards:"
  echo "  - YAML frontmatter exists with required fields"
  echo "  - Line count <= 150"
  echo "  - Required sections present"
  echo "  - Reference file budgets (individual <= 200, total <= 500)"
  echo "  - Version match with skills-registry.json (if exists)"
  echo ""
  echo "Options:"
  echo "  --verbose  Show detailed output for each check"
  exit 0
fi

VERBOSE=false
[[ "${1:-}" == "--verbose" ]] && VERBOSE=true

SKILLS_DIR=".claude/skills"
REGISTRY="$SKILLS_DIR/skills-registry.json"
SCHEMA="$SKILLS_DIR/skills-registry.schema.json"

pass=0
warn=0
fail=0
total=0

report() {
  local status="$1" skill="$2" msg="$3"
  case "$status" in
    PASS) pass=$((pass + 1)) ; if $VERBOSE; then echo "  PASS  $skill: $msg"; fi ;;
    WARN) warn=$((warn + 1)) ; echo "  WARN  $skill: $msg" ;;
    FAIL) fail=$((fail + 1)) ; echo "  FAIL  $skill: $msg" ;;
  esac
}

echo "Skill Conformance Validation"
echo "============================"
echo ""

for skill_file in "$SKILLS_DIR"/*/SKILL.md; do
  [[ -f "$skill_file" ]] || continue
  total=$((total + 1))

  skill_dir=$(dirname "$skill_file")
  skill_name=$(basename "$skill_dir")

  # --- 1. YAML frontmatter exists ---
  if head -1 "$skill_file" | grep -q "^---$"; then
    # Extract frontmatter
    frontmatter=$(sed -n '/^---$/,/^---$/p' "$skill_file" | sed '1d;$d')

    # Check required fields
    for field in name version description trigger depends-on references; do
      if echo "$frontmatter" | grep -q "^${field}:"; then
        report PASS "$skill_name" "has $field"
      else
        report FAIL "$skill_name" "missing required frontmatter field: $field"
      fi
    done
  else
    report FAIL "$skill_name" "no YAML frontmatter (must start with ---)"
  fi

  # --- 2. Line count <= 150 ---
  line_count=$(wc -l < "$skill_file" | tr -d ' ')
  if (( line_count <= 150 )); then
    report PASS "$skill_name" "line count: $line_count (<= 150)"
  else
    report WARN "$skill_name" "line count: $line_count (exceeds 150-line budget)"
  fi

  # --- 3. Required sections ---
  # Every skill should have at least a description header line and output/process section
  if grep -q "^## " "$skill_file"; then
    report PASS "$skill_name" "has section headings"
  else
    report WARN "$skill_name" "no section headings found"
  fi

  # --- 4. Reference file budgets ---
  if [[ -d "$skill_dir/references" ]]; then
    total_ref_lines=0
    for ref_file in "$skill_dir"/references/*.md; do
      [[ -f "$ref_file" ]] || continue
      ref_lines=$(wc -l < "$ref_file" | tr -d ' ')
      ref_name=$(basename "$ref_file")
      if (( ref_lines > 200 )); then
        report WARN "$skill_name" "reference $ref_name is $ref_lines lines (> 200)"
      else
        report PASS "$skill_name" "reference $ref_name: $ref_lines lines"
      fi
      total_ref_lines=$((total_ref_lines + ref_lines)) || true
    done
    if (( total_ref_lines > 500 )); then
      report WARN "$skill_name" "total reference lines: $total_ref_lines (> 500 budget)"
    else
      report PASS "$skill_name" "total reference lines: $total_ref_lines (<= 500)"
    fi
  fi

  # --- 5. Version match with registry ---
  if [[ -f "$REGISTRY" ]]; then
    skill_version=$(sed -n '/^---$/,/^---$/p' "$skill_file" | grep "^version:" | sed 's/version: *//' | head -1)
    if [[ -n "$skill_version" ]]; then
      if command -v jq &>/dev/null; then
        registry_version=$(jq -r ".[] | select(.name == \"$skill_name\") | .version" "$REGISTRY" 2>/dev/null || echo "")
      else
        registry_version=$(grep -A1 "\"name\": \"$skill_name\"" "$REGISTRY" | grep '"version"' | sed 's/.*: *"\(.*\)".*/\1/' | head -1)
      fi
      if [[ -n "$registry_version" && "$skill_version" != "$registry_version" ]]; then
        report WARN "$skill_name" "version mismatch: SKILL.md=$skill_version registry=$registry_version"
      elif [[ -n "$registry_version" ]]; then
        report PASS "$skill_name" "version matches registry ($skill_version)"
      fi
    fi
  fi

done

# --- 6. Registry schema validation (if schema exists) ---
if [[ -f "$SCHEMA" && -f "$REGISTRY" ]]; then
  echo ""
  echo "Registry Schema Validation"
  echo "--------------------------"
  if command -v jq &>/dev/null; then
    # Basic structural validation with jq
    if jq empty "$REGISTRY" 2>/dev/null; then
      report PASS "registry" "valid JSON"
      # Check each entry has required fields
      missing=$(jq -r '.[] | select(.name == null or .version == null or .description == null or .trigger == null or .path == null) | .name // "unknown"' "$REGISTRY" 2>/dev/null)
      if [[ -z "$missing" ]]; then
        report PASS "registry" "all entries have required fields"
      else
        report FAIL "registry" "entries missing required fields: $missing"
      fi
    else
      report FAIL "registry" "invalid JSON"
    fi
  else
    echo "  SKIP  jq not available — skipping schema validation"
  fi
fi

echo ""
echo "============================"
echo "Skills checked: $total"
echo "Results: $pass passed, $warn warnings, $fail failures"
echo ""
if (( fail > 0 )); then
  echo "Overall: ACTION REQUIRED"
  exit 1
elif (( warn > 0 )); then
  echo "Overall: NEEDS ATTENTION"
  exit 0
else
  echo "Overall: ALL CONFORMANT"
  exit 0
fi
