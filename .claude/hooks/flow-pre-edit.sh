#!/bin/sh
# PreToolUse (Edit|Write) handler: flow gate evidence check — advisory-first.
#
# When the flow cursor (see lib/graph-state.sh, FLOW_SPEC.md) sits on a
# gate.hard node that declares an `evidence:` marker, and that marker has not
# been observed this session (state/flow/<marker>, stamped by post-tool-use),
# an Edit/Write to a source file means the model is proceeding past the gate
# without the evidence the gate demands.
#
# Modes (EXOSUIT_FLOW_MODE: off | advisory | block; default derived from the
# project profile — lean: off, standard/strict: advisory; blocking is an
# explicit opt-in, never a default):
#   advisory — one-line warning on stderr, never blocks (exit 0)
#   block    — exit 2 with the reason (deterministic gate, opt-in)
#
# Exemptions (never warns/blocks): edits to test files (writing a test IS the
# evidence being asked for), docs/config (.md/.yml/.yaml/.json/.toml), and
# anything when no branch-matched cursor exists. Fail-open on every error.
# POSIX-compliant — no bash required.

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="$HOOKS_DIR/state"

# --- Hook guard: profile + disable check ---
"$HOOKS_DIR/lib/hook-guard.sh" "flow-pre-edit" "standard" || exit 0

# --- Resolve flow mode (blocking only by explicit opt-in) ---
FLOW_MODE="${EXOSUIT_FLOW_MODE:-}"
if [ -z "$FLOW_MODE" ]; then
    PROFILE=$(cat "$STATE_DIR/project-profile" 2>/dev/null || echo "standard")
    case "$PROFILE" in
        lean) FLOW_MODE="off" ;;
        *) FLOW_MODE="advisory" ;;
    esac
fi
case "$FLOW_MODE" in
    off) exit 0 ;;
    advisory|block) ;;
    *) FLOW_MODE="advisory" ;;
esac

# --- Cursor: exists, well-formed, branch-matched ---
CURSOR=$(sh "$HOOKS_DIR/lib/graph-state.sh" show 2>/dev/null)
[ -n "$CURSOR" ] || exit 0
# shellcheck disable=SC2086
set -- $CURSOR
CUR_FLOW="${1:-}"; CUR_NODE="${2:-}"; CUR_FS_BRANCH="${4:-}"
[ -n "$CUR_FLOW" ] && [ -n "$CUR_NODE" ] || exit 0
GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
[ "$CUR_FS_BRANCH" = "$GIT_BRANCH" ] || exit 0

# --- The cursor node must be a gate.hard with a declared evidence marker ---
FLOW_FILE=".claude/skills/$CUR_FLOW/flow.yaml"
[ -f "$FLOW_FILE" ] || exit 0
NODE_LINE=$(grep "^  $CUR_NODE: {" "$FLOW_FILE" 2>/dev/null | head -1)
[ -n "$NODE_LINE" ] || exit 0
printf '%s' "$NODE_LINE" | grep -q 'type: gate\.hard' || exit 0
EVIDENCE=$(printf '%s' "$NODE_LINE" | sed -n 's/.*evidence: \([a-z][a-z-]*\).*/\1/p')
[ -n "$EVIDENCE" ] || exit 0

# --- Evidence already observed this session? ---
[ -f "$STATE_DIR/flow/$EVIDENCE" ] && exit 0

# --- Exempt targets: tests, docs, config ---
extract_json() {
    _jq_path="$1"
    _sed_key="$2"
    if command -v jq >/dev/null 2>&1; then
        jq -r "$_jq_path // empty"
    else
        sed -n 's/.*"'"$_sed_key"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1
    fi
}
INPUT=$(cat)
FILE_PATH=$(printf '%s' "$INPUT" | extract_json ".tool_input.file_path" "file_path")
[ -n "$FILE_PATH" ] || exit 0
case "$FILE_PATH" in
    *test_*|*_test.*|*.test.*|*.spec.*|*tests/*|*test/*) exit 0 ;;
    *.md|*.yml|*.yaml|*.json|*.toml|*.txt) exit 0 ;;
esac

# --- Missing evidence for the gate the cursor sits on ---
EXPLAIN_MODE="${EXOSUIT_EXPLAIN_MODE:-brief}"
if [ "$FLOW_MODE" = "block" ]; then
    if [ "$EXPLAIN_MODE" = "verbose" ]; then
        printf 'Flow gate: /%s is at gate '\''%s'\'' which requires evidence '\''%s'\'' before source edits.\n  WHY: The gate declares mechanically checkable evidence (see flow.yaml and FLOW_SPEC.md). Produce it (e.g. write/run the tests) or clear the cursor. Set EXOSUIT_FLOW_MODE=advisory to warn instead of block.\n' "$CUR_FLOW" "$CUR_NODE" "$EVIDENCE" >&2
    else
        printf 'Flow gate: /%s at '\''%s'\'' requires evidence '\''%s'\'' before source edits (EXOSUIT_FLOW_MODE=block).\n' "$CUR_FLOW" "$CUR_NODE" "$EVIDENCE" >&2
    fi
    exit 2
fi
if [ "$EXPLAIN_MODE" != "off" ]; then
    printf 'Flow advisory: /%s is at gate '\''%s'\'' — evidence '\''%s'\'' not yet observed this session.\n' "$CUR_FLOW" "$CUR_NODE" "$EVIDENCE" >&2
fi
exit 0
