#!/usr/bin/env bash
# Skill execution metrics — query activity log for skill-level events.
# Usage: bash scripts/pm/metrics.sh [--skill <name>] [--days <n>]
#
# Requirements: grep, awk (always available)
# Optional: jq (richer output)

set -euo pipefail

LOG_FILE="docs/sessions/.activity-log.jsonl"
SKILL_FILTER=""
DAYS=30

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skill) SKILL_FILTER="$2"; shift 2 ;;
    --days)  DAYS="$2"; shift 2 ;;
    --help)
      echo "Usage: bash scripts/pm/metrics.sh [--skill <name>] [--days <n>]"
      echo "  --skill  Filter to a specific skill name"
      echo "  --days   Look back N days (default: 30)"
      exit 0 ;;
    *) shift ;;
  esac
done

if [[ ! -f "$LOG_FILE" ]]; then
  echo "No activity log found at $LOG_FILE"
  echo "Enable the PostToolUse hook via post-tool-use.sh in .claude/settings.json and emit skill events to populate metrics."
  exit 0
fi

echo "## Skill Execution Metrics (last ${DAYS} days)"
echo ""

# Extract skill events
SKILL_EVENTS=$(grep '"type":"skill"' "$LOG_FILE" 2>/dev/null || echo "")

if [[ -z "$SKILL_EVENTS" ]]; then
  echo "No skill lifecycle events found in the activity log."
  echo ""
  echo "Skills emit events via:"
  echo '  echo "{\"type\":\"skill\",\"event\":\"start\",\"skill\":\"<name>\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> docs/sessions/.activity-log.jsonl'
  exit 0
fi

if [[ -n "$SKILL_FILTER" ]]; then
  SKILL_EVENTS=$(echo "$SKILL_EVENTS" | grep "\"skill\":\"$SKILL_FILTER\"" || echo "")
fi

# Count starts and completions
STARTS=$(echo "$SKILL_EVENTS" | grep '"event":"start"' | wc -l | tr -d ' ')
COMPLETIONS=$(echo "$SKILL_EVENTS" | grep '"event":"end".*"outcome":"success"' | wc -l | tr -d ' ')
FAILURES=$(echo "$SKILL_EVENTS" | grep '"event":"end".*"outcome":"failed"' | wc -l | tr -d ' ')
PARTIALS=$(echo "$SKILL_EVENTS" | grep '"event":"end".*"outcome":"partial"' | wc -l | tr -d ' ')

echo "| Metric | Value |"
echo "|--------|-------|"
echo "| Total starts | $STARTS |"
echo "| Completed | $COMPLETIONS |"
echo "| Failed | $FAILURES |"
echo "| Partial | $PARTIALS |"

if (( STARTS > 0 )); then
  SUCCESS_RATE=$(( COMPLETIONS * 100 / STARTS ))
  echo "| Success rate | ${SUCCESS_RATE}% |"
fi

echo ""

# Per-skill breakdown
echo "### Per-Skill Breakdown"
echo ""
echo "| Skill | Starts | Success | Failed | Partial |"
echo "|-------|--------|---------|--------|---------|"

echo "$SKILL_EVENTS" | grep '"event":"start"' | \
  sed -n 's/.*"skill":"\([^"]*\)".*/\1/p' | sort | uniq | while read -r skill; do
    s=$(echo "$SKILL_EVENTS" | grep "\"skill\":\"$skill\"" | grep '"event":"start"' | wc -l | tr -d ' ')
    c=$(echo "$SKILL_EVENTS" | grep "\"skill\":\"$skill\"" | grep '"outcome":"success"' | wc -l | tr -d ' ')
    f=$(echo "$SKILL_EVENTS" | grep "\"skill\":\"$skill\"" | grep '"outcome":"failed"' | wc -l | tr -d ' ')
    p=$(echo "$SKILL_EVENTS" | grep "\"skill\":\"$skill\"" | grep '"outcome":"partial"' | wc -l | tr -d ' ')
    echo "| $skill | $s | $c | $f | $p |"
done

echo ""

# Tool usage summary
echo "### Tool Usage Summary"
echo ""
EDITS=$(grep '"tool":"Edit"' "$LOG_FILE" 2>/dev/null | wc -l | tr -d ' ')
WRITES=$(grep '"tool":"Write"' "$LOG_FILE" 2>/dev/null | wc -l | tr -d ' ')
BASHES=$(grep '"tool":"Bash"' "$LOG_FILE" 2>/dev/null | wc -l | tr -d ' ')
TOTAL=$((EDITS + WRITES + BASHES))

echo "| Tool | Count | % |"
echo "|------|-------|---|"
if (( TOTAL > 0 )); then
  echo "| Edit | $EDITS | $((EDITS * 100 / TOTAL))% |"
  echo "| Write | $WRITES | $((WRITES * 100 / TOTAL))% |"
  echo "| Bash | $BASHES | $((BASHES * 100 / TOTAL))% |"
else
  echo "| (no tool events) | 0 | — |"
fi

# Rule trigger summary
echo ""
echo "### Rule Triggers"
echo ""
RULE_EVENTS=$(grep '"type":"rule"' "$LOG_FILE" 2>/dev/null || echo "")
if [[ -z "$RULE_EVENTS" ]]; then
  echo "No rule trigger events found."
else
  echo "| Rule | Triggers |"
  echo "|------|----------|"
  echo "$RULE_EVENTS" | sed -n 's/.*"rule":"\([^"]*\)".*/\1/p' | sort | uniq -c | sort -rn | while read -r count rule; do
    echo "| $rule | $count |"
  done
fi
