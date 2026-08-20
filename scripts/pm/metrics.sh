#!/usr/bin/env bash
# Framework metrics — skill execution, story flow, rule triggers, tool usage,
# progress dashboard, code churn, and AI effectiveness.
#
# Usage: bash scripts/pm/metrics.sh [subcommand] [options]
#
# Subcommands:
#   (default)          Activity log metrics (skills, stories, tools, rules)
#   --progress         Parse and display docs/progress.md Metrics + Sprint History
#   --churn [--days N] Compute code churn ratio from git (default: 14 days)
#   --ai-effectiveness Compute AI effectiveness score from activity log
#
# Options:
#   --skill <name>     Filter activity log to a specific skill
#   --days <n>         Look-back window in days (default: 30, or 14 for --churn)
#   --help             Show this help
#
# Requirements: grep, awk, sed, git (always available)
# Optional: jq (richer output)

set -euo pipefail

LOG_FILE="docs/sessions/.activity-log.jsonl"
PROGRESS_FILE="docs/progress.md"
SKILL_FILTER=""
DAYS=30
MODE="activity"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --progress)         MODE="progress"; shift ;;
    --churn)            MODE="churn"; DAYS=14; shift ;;
    --ai-effectiveness) MODE="ai"; shift ;;
    --skill) SKILL_FILTER="$2"; shift 2 ;;
    --days)  DAYS="$2"; shift 2 ;;
    --help)
      sed -n '2,/^$/{ s/^# //; s/^#$//; p; }' "$0"
      exit 0 ;;
    *) shift ;;
  esac
done

# ─────────────────────────────────────────────
# Subcommand: --progress
# Parse docs/progress.md Metrics table and Sprint History
# ─────────────────────────────────────────────
if [[ "$MODE" == "progress" ]]; then
  if [[ ! -f "$PROGRESS_FILE" ]]; then
    echo "No progress file found at $PROGRESS_FILE"
    exit 1
  fi

  echo "## Sprint Metrics Dashboard"
  echo ""

  # Extract and display the Metrics table (between ## Metrics and next ##)
  in_metrics=0
  in_history=0
  while IFS= read -r line; do
    if [[ "$line" == "## Metrics"* ]]; then
      in_metrics=1; in_history=0; continue
    fi
    if [[ "$line" == "## Sprint History"* ]]; then
      in_metrics=0; in_history=1
      echo ""
      echo "$line"
      continue
    fi
    if [[ "$line" == "## "* && "$line" != "## Metrics"* && "$line" != "## Sprint History"* ]]; then
      in_metrics=0; in_history=0; continue
    fi

    # Print table rows (skip HTML comments)
    if [[ $in_metrics -eq 1 || $in_history -eq 1 ]]; then
      if [[ "$line" == "|"* ]]; then
        echo "$line"
      elif [[ "$line" == "**Sprint note:"* ]]; then
        echo ""
        echo "$line"
      fi
    fi
  done < "$PROGRESS_FILE"

  # Trend analysis: check for 3-sprint signals in Sprint History
  echo ""
  echo "### Trend Signals"
  echo ""

  # Extract numeric values from last 3 Sprint History rows for each metric column
  # Columns: Sprint|Goal|✓|Tasks|CycleT|CFR|CovΔ|Churn|AIEff|Sat|PR
  HISTORY_ROWS=$(grep -E '^\| [0-9]' "$PROGRESS_FILE" 2>/dev/null || echo "")
  if [[ -z "$HISTORY_ROWS" ]]; then
    ROW_COUNT=0
  else
    ROW_COUNT=$(echo "$HISTORY_ROWS" | wc -l | tr -d ' ')
    HISTORY_ROWS=$(echo "$HISTORY_ROWS" | tail -3)
  fi

  if [[ "$ROW_COUNT" -lt 3 ]]; then
    echo "Need ≥3 sprints for trend analysis (have $ROW_COUNT)."
  else
    # Parse each metric column from last 3 rows
    # Column indices (1-based, pipe-separated): 4=Tasks, 5=CycleT, 6=CFR, 7=CovΔ, 8=Churn, 9=AIEff, 10=Sat
    for col_spec in "4:Tasks completed:higher" "5:Cycle time:lower" "6:Change failure rate:lower" \
                    "7:Test coverage Δ:higher" "8:Code churn ratio:lower" "9:AI effectiveness:higher" \
                    "10:Sprint satisfaction:higher"; do
      col_idx="${col_spec%%:*}"
      rest="${col_spec#*:}"
      col_name="${rest%%:*}"
      direction="${rest##*:}"

      # Extract 3 values (satisfaction "X/5" → extract numerator only)
      vals=()
      while IFS= read -r row; do
        if [[ "$col_idx" == "10" ]]; then
          val=$(echo "$row" | awk -F'|' -v c="$col_idx" '{split($c, a, "/"); gsub(/[^0-9.\-+]/, "", a[1]); print a[1]}')
        else
          val=$(echo "$row" | awk -F'|' -v c="$col_idx" '{gsub(/[^0-9.\-+]/, "", $c); print $c}')
        fi
        [[ -n "$val" ]] && vals+=("$val")
      done <<< "$HISTORY_ROWS"

      if [[ ${#vals[@]} -eq 3 ]]; then
        v1="${vals[0]}"; v2="${vals[1]}"; v3="${vals[2]}"
        # Check monotonic trend (all increasing or all decreasing)
        if awk "BEGIN { exit !(($v1 < $v2) && ($v2 < $v3)) }" 2>/dev/null; then
          if [[ "$direction" == "higher" ]]; then
            echo "- **$col_name**: ↑ improving (3 sprints rising)"
          else
            echo "- **$col_name**: ⚠ degrading (3 sprints rising — lower is better)"
          fi
        elif awk "BEGIN { exit !(($v1 > $v2) && ($v2 < $v3)) }" 2>/dev/null; then
          : # Not monotonic, skip
        elif awk "BEGIN { exit !(($v1 > $v2) && ($v2 > $v3)) }" 2>/dev/null; then
          if [[ "$direction" == "lower" ]]; then
            echo "- **$col_name**: ↑ improving (3 sprints falling)"
          else
            echo "- **$col_name**: ⚠ degrading (3 sprints falling — higher is better)"
          fi
        fi
      fi
    done

    # Check if any signals were printed
    echo ""
    echo "Signals use the three-sprint rule: 3 consecutive sprints trending = investigate."

    # ── Section B: Relative Change (Δ from 3-sprint average) ──
    echo ""
    echo "### Relative Change (Δ from 3-sprint average)"
    echo ""
    echo "| Metric | Current | 3-Sprint Avg | Δ% | Signal |"
    echo "|--------|---------|-------------|-----|--------|"

    for col_spec in "4:Tasks completed:higher" "5:Cycle time:lower" "6:Change failure rate:lower" \
                    "7:Test coverage Δ:higher" "8:Code churn ratio:lower" "9:AI effectiveness:higher" \
                    "10:Sprint satisfaction:higher"; do
      col_idx="${col_spec%%:*}"
      rest="${col_spec#*:}"
      col_name="${rest%%:*}"
      direction="${rest##*:}"

      vals=()
      while IFS= read -r row; do
        if [[ "$col_idx" == "10" ]]; then
          val=$(echo "$row" | awk -F'|' -v c="$col_idx" '{split($c, a, "/"); gsub(/[^0-9.\-+]/, "", a[1]); print a[1]}')
        else
          val=$(echo "$row" | awk -F'|' -v c="$col_idx" '{gsub(/[^0-9.\-+]/, "", $c); print $c}')
        fi
        [[ -n "$val" ]] && vals+=("$val")
      done <<< "$HISTORY_ROWS"

      if [[ ${#vals[@]} -eq 3 ]]; then
        v1="${vals[0]}"; v2="${vals[1]}"; v3="${vals[2]}"
        avg=$(awk "BEGIN { printf \"%.2f\", ($v1 + $v2 + $v3) / 3 }")
        current="$v3"

        if awk "BEGIN { exit !($avg == 0) }" 2>/dev/null; then
          echo "| $col_name | $current | $avg | — | — |"
        else
          delta_pct=$(awk "BEGIN { printf \"%.0f\", (($current - $avg) / $avg) * 100 }")

          # Determine signal based on direction and delta
          # For "lower is better": positive delta = worse. For "higher is better": negative delta = worse.
          if [[ "$direction" == "lower" ]]; then
            abs_delta=$(awk "BEGIN { v=$delta_pct; if (v<0) v=-v; print v }")
            if awk "BEGIN { exit !($delta_pct > 0) }" 2>/dev/null; then
              # Higher than average — worse for lower-is-better
              if awk "BEGIN { exit !($abs_delta > 100) }" 2>/dev/null; then
                signal="critical"
              elif awk "BEGIN { exit !($abs_delta > 50) }" 2>/dev/null; then
                signal="warning"
              elif awk "BEGIN { exit !($abs_delta > 30) }" 2>/dev/null; then
                signal="watch"
              else
                signal="—"
              fi
            else
              signal="—"
            fi
          else
            abs_delta=$(awk "BEGIN { v=$delta_pct; if (v<0) v=-v; print v }")
            if awk "BEGIN { exit !($delta_pct < 0) }" 2>/dev/null; then
              # Lower than average — worse for higher-is-better
              if awk "BEGIN { exit !($abs_delta > 100) }" 2>/dev/null; then
                signal="critical"
              elif awk "BEGIN { exit !($abs_delta > 50) }" 2>/dev/null; then
                signal="warning"
              elif awk "BEGIN { exit !($abs_delta > 30) }" 2>/dev/null; then
                signal="watch"
              else
                signal="—"
              fi
            else
              signal="—"
            fi
          fi

          echo "| $col_name | $current | $avg | ${delta_pct}% | $signal |"
        fi
      fi
    done

    # ── Section C: Leading vs Lagging Analysis ──
    echo ""
    echo "### Leading vs Lagging Analysis"
    echo ""

    # Helper: assess 3-value trend direction
    assess_trend() {
      local v1="$1" v2="$2" v3="$3" dir="$4"
      if awk "BEGIN { exit !(($v1 < $v2) && ($v2 < $v3)) }" 2>/dev/null; then
        [[ "$dir" == "higher" ]] && echo "improving" || echo "degrading"
      elif awk "BEGIN { exit !(($v1 > $v2) && ($v2 > $v3)) }" 2>/dev/null; then
        [[ "$dir" == "lower" ]] && echo "improving" || echo "degrading"
      else
        echo "stable"
      fi
    }

    # Extract values for leading indicators: churn (8, lower), coverage Δ (7, higher), satisfaction (10, higher)
    leading_trends=()
    for col_spec in "8:lower" "7:higher" "10:higher"; do
      ci="${col_spec%%:*}"; di="${col_spec#*:}"
      lvals=()
      while IFS= read -r row; do
        if [[ "$ci" == "10" ]]; then
          lv=$(echo "$row" | awk -F'|' -v c="$ci" '{split($c, a, "/"); gsub(/[^0-9.\-+]/, "", a[1]); print a[1]}')
        else
          lv=$(echo "$row" | awk -F'|' -v c="$ci" '{gsub(/[^0-9.\-+]/, "", $c); print $c}')
        fi
        [[ -n "$lv" ]] && lvals+=("$lv")
      done <<< "$HISTORY_ROWS"
      [[ ${#lvals[@]} -eq 3 ]] && leading_trends+=("$(assess_trend "${lvals[0]}" "${lvals[1]}" "${lvals[2]}" "$di")")
    done

    # Extract values for lagging indicators: CFR (6, lower), tasks (4, higher)
    lagging_trends=()
    for col_spec in "6:lower" "4:higher"; do
      ci="${col_spec%%:*}"; di="${col_spec#*:}"
      lvals=()
      while IFS= read -r row; do
        lv=$(echo "$row" | awk -F'|' -v c="$ci" '{gsub(/[^0-9.\-+]/, "", $c); print $c}')
        [[ -n "$lv" ]] && lvals+=("$lv")
      done <<< "$HISTORY_ROWS"
      [[ ${#lvals[@]} -eq 3 ]] && lagging_trends+=("$(assess_trend "${lvals[0]}" "${lvals[1]}" "${lvals[2]}" "$di")")
    done

    # Summarize leading trend
    leading_degrading=0; leading_improving=0
    for t in "${leading_trends[@]}"; do
      [[ "$t" == "degrading" ]] && leading_degrading=$((leading_degrading + 1))
      [[ "$t" == "improving" ]] && leading_improving=$((leading_improving + 1))
    done
    if [[ $leading_degrading -ge 2 ]]; then
      leading_summary="degrading"
    elif [[ $leading_improving -ge 2 ]]; then
      leading_summary="improving"
    else
      leading_summary="stable"
    fi

    # Summarize lagging trend
    lagging_degrading=0; lagging_improving=0
    for t in "${lagging_trends[@]}"; do
      [[ "$t" == "degrading" ]] && lagging_degrading=$((lagging_degrading + 1))
      [[ "$t" == "improving" ]] && lagging_improving=$((lagging_improving + 1))
    done
    if [[ $lagging_degrading -ge 1 ]]; then
      lagging_summary="degrading"
    elif [[ $lagging_improving -ge 1 ]]; then
      lagging_summary="improving"
    else
      lagging_summary="stable"
    fi

    echo "- **Leading indicators** (churn, coverage Δ, satisfaction): **$leading_summary**"
    echo "- **Lagging indicators** (CFR, tasks): **$lagging_summary**"

    # Divergence detection
    if [[ "$leading_summary" == "degrading" && "$lagging_summary" != "degrading" ]]; then
      echo ""
      echo "⚠ **Early warning:** Leading indicators degrading while lagging indicators are $lagging_summary."
      echo "  Quality problems may be building — expect lagging metrics to follow in 1-2 sprints."
    elif [[ "$lagging_summary" == "degrading" && "$leading_summary" == "improving" ]]; then
      echo ""
      echo "↑ **Delayed effect:** Leading indicators improving but lagging still degrading."
      echo "  Course correction is underway — maintain patience, lagging metrics should follow."
    fi

    # ── Section D: Hotspot pointer (conditional) ──
    # Check current churn from Metrics table
    CURRENT_CHURN=$(grep 'Code churn ratio' "$PROGRESS_FILE" 2>/dev/null \
      | awk -F'|' '{gsub(/[^0-9.\-+]/, "", $3); print $3}' | head -1)
    if [[ -n "$CURRENT_CHURN" ]] && awk "BEGIN { exit !($CURRENT_CHURN > 0.12) }" 2>/dev/null; then
      echo ""
      echo "### Hotspot Files"
      echo ""
      echo "Code churn ratio ($CURRENT_CHURN) is elevated. Run for file-level analysis:"
      echo '```bash'
      echo "bash scripts/pm/metrics.sh --churn"
      echo '```'
    fi
  fi

  exit 0
fi

# ─────────────────────────────────────────────
# Subcommand: --churn
# Compute code churn ratio from git history
# ─────────────────────────────────────────────
if [[ "$MODE" == "churn" ]]; then
  echo "## Code Churn Ratio (${DAYS}-day window)"
  echo ""

  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Not inside a git repository."
    exit 1
  fi

  SINCE_DATE=$(date -v-${DAYS}d +%Y-%m-%d 2>/dev/null || date -d "${DAYS} days ago" +%Y-%m-%d 2>/dev/null || echo "")
  if [[ -z "$SINCE_DATE" ]]; then
    echo "Could not compute date. Provide --days as integer."
    exit 1
  fi

  # Total lines added in the analysis window
  TOTAL_ADDED=$(git log --since="$SINCE_DATE" --numstat --format="" -- '*.py' '*.ts' '*.tsx' '*.js' '*.jsx' '*.go' '*.rs' '*.rb' '*.java' '*.cs' '*.php' '*.dart' 2>/dev/null \
    | awk '{ added += $1 } END { print added+0 }')

  # Lines that were subsequently modified (churn = edits to recently-added code)
  # Approximation: count lines in files that were both added-to and modified within the window
  CHURNED=0
  CHURN_FILES=""

  # Find files changed more than once in the window (proxy for churn)
  CHURN_FILES=$(git log --since="$SINCE_DATE" --name-only --format="" -- '*.py' '*.ts' '*.tsx' '*.js' '*.jsx' '*.go' '*.rs' '*.rb' '*.java' '*.cs' '*.php' '*.dart' 2>/dev/null \
    | sort | uniq -c | sort -rn | awk '$1 > 1 { print $2 }' | head -20)

  if [[ -n "$CHURN_FILES" ]]; then
    # For multi-edited files, count total modifications as churn
    while IFS= read -r file; do
      if [[ -n "$file" ]]; then
        file_churn=$(git log --since="$SINCE_DATE" --numstat --format="" -- "$file" 2>/dev/null \
          | awk '{ added += $1; deleted += $2 } END { print (deleted < added ? deleted : added)+0 }')
        CHURNED=$((CHURNED + file_churn))
      fi
    done <<< "$CHURN_FILES"
  fi

  if [[ "$TOTAL_ADDED" -gt 0 ]]; then
    # Use awk for floating point division
    RATIO=$(awk "BEGIN { printf \"%.2f\", $CHURNED / $TOTAL_ADDED }")
    echo "| Metric | Value |"
    echo "|--------|-------|"
    echo "| Lines added | $TOTAL_ADDED |"
    echo "| Lines churned | $CHURNED |"
    echo "| **Churn ratio** | **$RATIO** |"
    echo "| Window | ${DAYS} days |"
    echo ""

    # Threshold check
    if awk "BEGIN { exit !($RATIO > 0.15) }" 2>/dev/null; then
      echo "⚠ Churn ratio above 0.15 threshold — investigate high-churn files below."
    elif awk "BEGIN { exit !($RATIO > 0.12) }" 2>/dev/null; then
      echo "🟡 Churn ratio approaching threshold (target: ≤0.15)."
    else
      echo "🟢 Churn ratio within target."
    fi
  else
    echo "No code changes found in the last $DAYS days."
    RATIO="0.00"
  fi

  # Top churned files
  if [[ -n "$CHURN_FILES" ]]; then
    echo ""
    echo "### High-Churn Files (changed >1 time in ${DAYS}d)"
    echo ""
    echo "| File | Changes | Added | Deleted |"
    echo "|------|---------|-------|---------|"
    echo "$CHURN_FILES" | head -10 | while IFS= read -r file; do
      if [[ -n "$file" ]]; then
        changes=$(git log --since="$SINCE_DATE" --oneline -- "$file" 2>/dev/null | wc -l | tr -d ' ')
        stats=$(git log --since="$SINCE_DATE" --numstat --format="" -- "$file" 2>/dev/null \
          | awk '{ a += $1; d += $2 } END { printf "%d | %d", a+0, d+0 }')
        echo "| $file | $changes | $stats |"
      fi
    done
  fi

  exit 0
fi

# ─────────────────────────────────────────────
# Subcommand: --ai-effectiveness
# Compute AI effectiveness from activity log
# ─────────────────────────────────────────────
if [[ "$MODE" == "ai" ]]; then
  echo "## AI Effectiveness Score (last ${DAYS} days)"
  echo ""

  if [[ ! -f "$LOG_FILE" ]]; then
    echo "No activity log found at $LOG_FILE"
    exit 1
  fi

  # Apply the documented --days window. ISO-8601 UTC timestamps compare
  # lexicographically, so a plain string compare is a correct date filter.
  # Fail-open: if no cutoff can be computed or no temp file is available,
  # fall back to the whole log (previous behavior).
  CUTOFF=$(date -u -d "$DAYS days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null \
    || date -u -v-"${DAYS}"d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "")
  AI_LOG="$LOG_FILE"
  if [[ -n "$CUTOFF" ]] && AI_LOG_TMP=$(mktemp 2>/dev/null); then
    trap 'rm -f "$AI_LOG_TMP"' EXIT
    awk -v c="$CUTOFF" 'match($0, /"ts":"[^"]*"/) { if (substr($0, RSTART + 6, RLENGTH - 7) >= c) print; next } { print }' \
      "$LOG_FILE" > "$AI_LOG_TMP" 2>/dev/null && AI_LOG="$AI_LOG_TMP"
  fi

  # Helper: count grep matches without failing on zero
  count_matches() { grep -c "$1" "$2" 2>/dev/null || true; }

  # Component 1: Skill success rate (weight: 60%)
  SKILL_STARTS=$(count_matches '"event":"start"' "$AI_LOG")
  SKILL_SUCCESS=$(count_matches '"outcome":"success"' "$AI_LOG")

  if [[ "$SKILL_STARTS" -gt 0 ]]; then
    SKILL_RATE=$(awk "BEGIN { printf \"%.2f\", $SKILL_SUCCESS / $SKILL_STARTS }")
  else
    SKILL_RATE="0.00"
  fi

  # Component 2: Context reset frequency (weight: 40%)
  # Lower resets = better effectiveness. Normalize: 0 resets = 1.0, ≥3/session = 0.0
  CR1=$(count_matches '"context_reset"' "$AI_LOG")
  CR2=$(count_matches '"context-reset"' "$AI_LOG")
  CR3=$(count_matches '"fresh-start"' "$AI_LOG")
  CONTEXT_RESETS=$((CR1 + CR2 + CR3))

  # Count sessions from start events only — skills emit start AND end
  # lifecycle events that both contain the skill name; matching every line
  # would double-count each session.
  SC1=$(count_matches '"event":"start".*"skill":"continue"' "$AI_LOG")
  SC2=$(count_matches '"event":"start".*"skill":"story-cycle"' "$AI_LOG")
  SESSION_COUNT=$((SC1 + SC2))
  # Avoid division by zero — at least 1 session
  [[ "$SESSION_COUNT" -eq 0 ]] && SESSION_COUNT=1

  RESETS_PER_SESSION=$(awk "BEGIN { printf \"%.2f\", $CONTEXT_RESETS / $SESSION_COUNT }")
  # Normalize: 0 resets/session = 1.0, ≥3 resets/session = 0.0
  RESET_SCORE=$(awk "BEGIN { v = 1.0 - ($RESETS_PER_SESSION / 3.0); if (v < 0) v = 0; if (v > 1) v = 1; printf \"%.2f\", v }")

  # Composite: 60% skill success + 40% context stability
  AI_SCORE=$(awk "BEGIN { printf \"%.2f\", ($SKILL_RATE * 0.6) + ($RESET_SCORE * 0.4) }")

  echo "| Component | Value | Weight |"
  echo "|-----------|-------|--------|"
  echo "| Skill success rate | $SKILL_RATE ($SKILL_SUCCESS/$SKILL_STARTS) | 60% |"
  echo "| Context stability | $RESET_SCORE ($CONTEXT_RESETS resets / $SESSION_COUNT sessions) | 40% |"
  echo "| **AI effectiveness** | **$AI_SCORE** | |"
  echo ""

  # Threshold check
  if awk "BEGIN { exit !($AI_SCORE >= 0.70) }" 2>/dev/null; then
    echo "🟢 AI effectiveness on target (≥0.70)."
  elif awk "BEGIN { exit !($AI_SCORE >= 0.58) }" 2>/dev/null; then
    echo "🟡 AI effectiveness below target — check skill failures and context resets."
  else
    echo "🔴 AI effectiveness critically low — review skill error patterns."
  fi

  # Show top failing skills if any
  FAILED_SKILLS=$(grep '"type":"skill".*"outcome":"failed"' "$AI_LOG" 2>/dev/null \
    | sed -n 's/.*"skill":"\([^"]*\)".*/\1/p' | sort | uniq -c | sort -rn | head -5 || true)
  if [[ -n "$FAILED_SKILLS" ]]; then
    echo ""
    echo "### Top Failing Skills"
    echo ""
    echo "| Skill | Failures |"
    echo "|-------|----------|"
    echo "$FAILED_SKILLS" | while read -r count skill; do
      [[ -n "$skill" ]] && echo "| $skill | $count |"
    done
  fi

  exit 0
fi

# ─────────────────────────────────────────────
# Default: Activity log metrics
# ─────────────────────────────────────────────
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
