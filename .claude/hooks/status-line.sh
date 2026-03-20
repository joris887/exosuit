#!/usr/bin/env bash
# Rich status line: sprint, branch (color-coded), context bar, cost.
# Reads session data from stdin JSON + git/sprint state from CLI/files.
# Requirements: git (always available), jq (optional, for context/cost data)

source "$(dirname "$0")/lib/paths.sh"

# Read session data from stdin
INPUT=$(cat)

# --- Git state ---
BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
DIRTY=""
git diff --quiet 2>/dev/null || DIRTY="*"
git diff --cached --quiet 2>/dev/null || DIRTY="${DIRTY:+$DIRTY}+"

# --- Sprint from progress.md ---
PROGRESS_FILE="$(project_path "docs/progress.md")"
SPRINT=""
if [[ -f "$PROGRESS_FILE" ]]; then
  SPRINT=$(grep -m1 'Sprint\*\*:' "$PROGRESS_FILE" 2>/dev/null | sed 's/.*: *//' | tr -d ' ')
fi

# --- Context and cost via jq (graceful fallback to plain output) ---
CTX_PCT=""
COST=""
if command -v jq >/dev/null 2>&1 && [[ -n "$INPUT" ]]; then
  CTX_PCT=$(echo "$INPUT" | jq -r '.context_window.used_percentage // empty' 2>/dev/null)
  COST=$(echo "$INPUT" | jq -r '.cost.total_cost_usd // empty' 2>/dev/null)
fi

# --- ANSI colors ---
RST='\033[0m'
CYN='\033[36m'
GRN='\033[32m'
YLW='\033[33m'
RED='\033[31m'
DIM='\033[2m'

# --- Branch color: red on main/master, yellow if dirty, green if clean ---
BC="$GRN"
case "$BRANCH" in
  main|master) BC="$RED" ;;
esac
[[ -n "$DIRTY" ]] && BC="$YLW"

# --- Build output ---
OUT=""

# Sprint prefix (cyan)
if [[ -n "$SPRINT" && "$SPRINT" != "<!--"* ]]; then
  OUT="${CYN}S${SPRINT}${RST} "
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

  # Build 10-char progress bar
  F=$((PCT / 10))
  E=$((10 - F))
  BAR=""
  for ((i = 0; i < F; i++)); do BAR+="█"; done
  for ((i = 0; i < E; i++)); do BAR+="░"; done

  OUT="${OUT} ${CC}${BAR} ${PCT}%${RST}"
fi

# Cost (dim)
if [[ -n "$COST" && "$COST" != "0" && "$COST" != "null" ]]; then
  OUT="${OUT} ${DIM}\$${COST}${RST}"
fi

echo -e "$OUT"
