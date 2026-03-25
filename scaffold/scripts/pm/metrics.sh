#!/usr/bin/env bash
# Framework metrics — skill execution, story flow, rule triggers, tool usage.
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
  echo "Enable the PostToolUse hook via engine.py and emit skill events to populate metrics."
  exit 0
fi

echo "## Framework Metrics (last ${DAYS} days)"
echo ""

# ─── Skill Execution Metrics ───

echo "### Skill Execution"
echo ""

SKILL_EVENTS=$(grep '"type":"skill"' "$LOG_FILE" 2>/dev/null || echo "")

if [[ -n "$SKILL_EVENTS" ]]; then
  if [[ -n "$SKILL_FILTER" ]]; then
    SKILL_EVENTS=$(echo "$SKILL_EVENTS" | grep "\"skill\":\"$SKILL_FILTER\"" || echo "")
  fi

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
else
  echo "No skill lifecycle events found."
fi

echo ""

# ─── Story Flow Metrics ───

echo "### Story Flow"
echo ""

STORY_EVENTS=$(grep '"type":"story"' "$LOG_FILE" 2>/dev/null || echo "")

if [[ -n "$STORY_EVENTS" ]]; then
  STORIES_STARTED=$(echo "$STORY_EVENTS" | grep '"to":"in-progress"' | wc -l | tr -d ' ')
  STORIES_COMPLETED=$(echo "$STORY_EVENTS" | grep '"to":"done"' | wc -l | tr -d ' ')
  STORIES_BLOCKED=$(echo "$STORY_EVENTS" | grep '"to":"blocked"' | wc -l | tr -d ' ')

  echo "| Metric | Value |"
  echo "|--------|-------|"
  echo "| Stories started | $STORIES_STARTED |"
  echo "| Stories completed | $STORIES_COMPLETED |"
  echo "| Stories blocked | $STORIES_BLOCKED |"

  if (( STORIES_STARTED > 0 )); then
    COMPLETION_RATE=$(( STORIES_COMPLETED * 100 / STORIES_STARTED ))
    echo "| Completion rate | ${COMPLETION_RATE}% |"
  fi

  # Per-type breakdown
  echo ""
  echo "| Type | Started | Completed |"
  echo "|------|---------|-----------|"
  for stype in feature bugfix refactor spike infra testing docs security performance skill; do
    started=$(echo "$STORY_EVENTS" | grep '"to":"in-progress"' | grep "\"story_type\":\"$stype\"" | wc -l | tr -d ' ')
    completed=$(echo "$STORY_EVENTS" | grep '"to":"done"' | grep "\"story_type\":\"$stype\"" | wc -l | tr -d ' ')
    if [[ $started -gt 0 || $completed -gt 0 ]]; then
      echo "| $stype | $started | $completed |"
    fi
  done

  # Per-size breakdown
  echo ""
  echo "| Size | Started | Completed |"
  echo "|------|---------|-----------|"
  for size in TRIVIAL SMALL STANDARD; do
    started=$(echo "$STORY_EVENTS" | grep '"to":"in-progress"' | grep "\"size\":\"$size\"" | wc -l | tr -d ' ')
    completed=$(echo "$STORY_EVENTS" | grep '"to":"done"' | grep "\"size\":\"$size\"" | wc -l | tr -d ' ')
    if [[ $started -gt 0 || $completed -gt 0 ]]; then
      echo "| $size | $started | $completed |"
    fi
  done
else
  echo "No story lifecycle events found."
  echo "Story events are emitted by /story-cycle and /sprint-end."
fi

echo ""

# ─── Tool Usage Summary ───

echo "### Tool Usage"
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

# ─── Rule Triggers ───

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
