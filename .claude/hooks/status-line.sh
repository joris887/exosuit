#!/usr/bin/env bash
# Rich status line: sprint, branch, context bar, model, rate limits.
# Reads session data from stdin JSON + git/sprint state from CLI/files.
# Requirements: git (always available), jq (optional, for context/cost data)

source "$(dirname "$0")/lib/paths.sh"

# Read session data from stdin
INPUT=$(cat)

# --- Git state ---
# Outside a repo every git call fails, which must not render as detached/dirty.
# Inside a repo, --show-current prints nothing (exit 0) on a detached HEAD.
if git rev-parse --git-dir >/dev/null 2>&1; then
  BRANCH=$(git branch --show-current 2>/dev/null)
  [[ -z "$BRANCH" ]] && BRANCH="detached"
  DIRTY=""
  git diff --quiet 2>/dev/null || DIRTY="*"
  git diff --cached --quiet 2>/dev/null || DIRTY="${DIRTY:+$DIRTY}+"
else
  BRANCH="no git"
  DIRTY=""
fi

# --- Sprint from progress.md ---
PROGRESS_FILE="$(project_path "docs/progress.md")"
SPRINT=""
if [[ -f "$PROGRESS_FILE" ]]; then
  SPRINT=$(grep -m1 'Sprint\*\*:' "$PROGRESS_FILE" 2>/dev/null | sed 's/.*: *//' | tr -d ' ')
fi

# --- Extract data via jq (graceful fallback) ---
CTX_PCT=""
MODEL=""
RATE_5H=""
if command -v jq >/dev/null 2>&1 && [[ -n "$INPUT" ]]; then
  CTX_PCT=$(echo "$INPUT" | jq -r '.context_window.used_percentage // empty' 2>/dev/null)
  MODEL=$(echo "$INPUT" | jq -r '.model.display_name // empty' 2>/dev/null)
  RATE_5H=$(echo "$INPUT" | jq -r '.rate_limits.five_hour.used_percentage // empty' 2>/dev/null)
fi

# --- ANSI colors ---
RST='\033[0m'
CYN='\033[36m'
GRN='\033[32m'
YLW='\033[33m'
RED='\033[31m'
DIM='\033[2m'
BLD='\033[1m'

# --- Branch color: red on main/master, yellow if dirty, green if clean ---
BC="$GRN"
case "$BRANCH" in
  main|master) BC="$RED" ;;
  "no git") BC="$DIM" ;;
esac
[[ -n "$DIRTY" ]] && BC="$YLW"

# --- Build output ---
OUT=""

# --- Active skill from failure state ---
FAILURE_STATE="docs/sessions/.failure-state.md"
ACTIVE_SKILL=""
if [[ -f "$FAILURE_STATE" ]]; then
  SKILL_NAME=$(grep -m1 '^skill:' "$FAILURE_STATE" 2>/dev/null | sed 's/skill: *//')
  SKILL_PHASE=$(grep -m1 '^phase_name:' "$FAILURE_STATE" 2>/dev/null | sed 's/phase_name: *"//;s/"//')
  if [[ -n "$SKILL_NAME" ]]; then
    ACTIVE_SKILL="${SKILL_NAME}"
    [[ -n "$SKILL_PHASE" ]] && ACTIVE_SKILL="${ACTIVE_SKILL}:${SKILL_PHASE}"
  fi
fi

# Sprint prefix (cyan)
if [[ -n "$SPRINT" && "$SPRINT" != "<!--"* ]]; then
  OUT="${CYN}S${SPRINT}${RST} "
fi

# Active skill (magenta)
MAG='\033[35m'
if [[ -n "$ACTIVE_SKILL" ]]; then
  OUT="${OUT}${MAG}[${ACTIVE_SKILL}]${RST} "
fi

# Branch with status indicator
OUT="${OUT}${BC}${BRANCH}${DIRTY}${RST}"

# Context usage bar (green <60%, yellow 60-80%, red >80%)
if [[ -n "$CTX_PCT" && "$CTX_PCT" != "null" ]]; then
  PCT=${CTX_PCT%.*}
  [[ -z "$PCT" ]] && PCT=0

  CC="$GRN"
  [[ $PCT -ge 60 ]] && CC="$YLW"
  [[ $PCT -ge 80 ]] && CC="$RED"

  F=$((PCT / 10))
  E=$((10 - F))
  BAR=""
  for ((i = 0; i < F; i++)); do BAR+="█"; done
  for ((i = 0; i < E; i++)); do BAR+="░"; done

  OUT="${OUT} ${CC}${BAR} ${PCT}%${RST}"
fi

# Model name (full, dim)
if [[ -n "$MODEL" && "$MODEL" != "null" ]]; then
  OUT="${OUT} ${DIM}${MODEL}${RST}"
fi

# Rate limit (color-coded: green <50%, yellow 50-75%, red >75%, 1 decimal)
if [[ -n "$RATE_5H" && "$RATE_5H" != "null" ]]; then
  RATE_INT=${RATE_5H%.*}
  [[ -z "$RATE_INT" ]] && RATE_INT=0
  RC="$GRN"
  [[ $RATE_INT -ge 50 ]] && RC="$YLW"
  [[ $RATE_INT -ge 75 ]] && RC="$RED"
  RATE_FMT=$(printf '%.1f' "$RATE_5H" 2>/dev/null || echo "$RATE_5H")
  OUT="${OUT} ${RC}5h:${RATE_FMT}%${RST}"
fi

echo -e "$OUT"
