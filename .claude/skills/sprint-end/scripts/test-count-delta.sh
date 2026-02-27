#!/usr/bin/env bash
# Compare test counts between current branch and the default branch.
# Usage: bash scripts/test-count-delta.sh [--base-branch <branch>] [-- test-command...]
#
# If no test-command given, attempts auto-detection.
# If no --base-branch given, detects from CLAUDE.md or git.
# Outputs structured result to stdout.

set -euo pipefail

show_help() {
  cat <<'HELP'
Usage: bash scripts/test-count-delta.sh [OPTIONS] [-- test-command...]

Compare test counts between current branch and the default branch.

Options:
  -h, --help                 Show this help message
  --base-branch <branch>     Base branch to compare against (default: auto-detect)

Arguments:
  test-command  Command to count tests (e.g., "npx jest --listTests")
                If omitted, auto-detects from project files.

Base branch detection order:
  1. --base-branch argument
  2. CLAUDE.md "Default branch:" field
  3. git symbolic-ref refs/remotes/origin/HEAD
  4. First existing branch: main, master, develop

Output:
  Prints structured comparison of test counts.

Examples:
  bash scripts/test-count-delta.sh
  bash scripts/test-count-delta.sh --base-branch master
  bash scripts/test-count-delta.sh -- pytest --collect-only -q
  bash scripts/test-count-delta.sh --base-branch master -- npx jest --listTests
HELP
  exit 0
}

[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && show_help

# Parse --base-branch option
BASE_BRANCH=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-branch)
      BASE_BRANCH="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    *)
      break
      ;;
  esac
done

# Detect base branch if not provided
if [[ -z "$BASE_BRANCH" ]]; then
  # Try CLAUDE.md
  BASE_BRANCH=$(grep -oP '^\- \*\*Default branch:\*\* \K\S+' CLAUDE.md 2>/dev/null || true)
fi
if [[ -z "$BASE_BRANCH" ]]; then
  # Try git remote HEAD
  BASE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || true)
fi
if [[ -z "$BASE_BRANCH" ]]; then
  # Try common branch names
  for branch in main master develop; do
    if git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null; then
      BASE_BRANCH="$branch"
      break
    fi
  done
fi
if [[ -z "$BASE_BRANCH" ]]; then
  echo "ERROR: Could not detect base branch. Pass --base-branch explicitly."
  exit 1
fi

# Auto-detect test count method
detect_test_counter() {
  if [[ -f "package.json" ]]; then
    if command -v npx &>/dev/null; then
      echo "npx jest --listTests 2>/dev/null | wc -l"
      return
    fi
  fi
  if [[ -f "pyproject.toml" || -f "setup.py" || -f "setup.cfg" ]]; then
    if command -v pytest &>/dev/null; then
      echo "pytest --collect-only -q 2>/dev/null | tail -1 | grep -oE '[0-9]+' | head -1"
      return
    fi
  fi
  if [[ -f "Cargo.toml" ]]; then
    echo "cargo test -- --list 2>/dev/null | grep -c ': test$'"
    return
  fi
  if [[ -f "go.mod" ]]; then
    echo "go test -list '.*' ./... 2>/dev/null | grep -cv '^ok\\|^$'"
    return
  fi
  echo ""
}

# Get test command (remaining args after option parsing)
TEST_CMD="${*:-$(detect_test_counter)}"

if [[ -z "$TEST_CMD" ]]; then
  echo "ERROR: Could not detect test framework. Pass test command explicitly."
  echo "Run with --help for usage."
  exit 1
fi

CURRENT_BRANCH=$(git branch --show-current)

# Count tests on current branch
BRANCH_COUNT=$(eval "$TEST_CMD" 2>/dev/null || echo "0")
BRANCH_COUNT=$(echo "$BRANCH_COUNT" | tr -d '[:space:]')

# Count tests on base branch (stash any changes)
STASH_NEEDED=false
if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
  STASH_NEEDED=true
  git stash push -q -m "test-count-delta temp stash"
fi

git checkout "$BASE_BRANCH" -q 2>/dev/null
BASE_COUNT=$(eval "$TEST_CMD" 2>/dev/null || echo "0")
BASE_COUNT=$(echo "$BASE_COUNT" | tr -d '[:space:]')
git checkout "$CURRENT_BRANCH" -q 2>/dev/null

if [[ "$STASH_NEEDED" == "true" ]]; then
  git stash pop -q 2>/dev/null || true
fi

# Calculate delta
DELTA=$((BRANCH_COUNT - BASE_COUNT))

# Output
echo "## Test Count Delta"
echo ""
echo "| Metric | Count |"
echo "|--------|-------|"
echo "| Branch ($CURRENT_BRANCH) | $BRANCH_COUNT |"
echo "| Base ($BASE_BRANCH) | $BASE_COUNT |"
echo "| Delta | $DELTA |"
echo ""

if [[ "$DELTA" -lt 0 ]]; then
  echo "**FAIL:** Test count decreased by ${DELTA#-}. Tests may have been deleted."
  exit 1
elif [[ "$DELTA" -eq 0 ]]; then
  echo "**WARN:** Test count unchanged."
  exit 0
else
  echo "**PASS:** Test count increased by $DELTA."
  exit 0
fi
