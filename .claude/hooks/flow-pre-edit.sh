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
# evidence being asked for; shared patterns in lib/test-paths.sh), docs/config
# (.md/.yml/.yaml/.json/.toml/.txt), and anything when no branch-matched
# cursor exists. Advisory warns ONCE per (flow, node, evidence), not on every
# edit. Fail-open on every error.
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
# Strip quoted attrs (doc/profile prose) so 'type:'/'evidence:' inside
# documentation text can never spoof the structural attributes.
NODE_CLEAN=$(printf '%s' "$NODE_LINE" | sed -E 's/(doc|profile): "[^"]*"//g')
printf '%s' "$NODE_CLEAN" | grep -q 'type: gate\.hard' || exit 0
EVIDENCE=$(printf '%s' "$NODE_CLEAN" | sed -n 's/.*evidence: \([a-z][a-z-]*\).*/\1/p')
[ -n "$EVIDENCE" ] || exit 0

# tests-green can only ever be stamped when jq is available (post-tool-use
# needs it to read tool output) — without jq the marker is unproducible, so
# enforcement must fail open rather than block forever.
if [ "$EVIDENCE" = "tests-green" ] && ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

# --- Evidence already observed this session? ---
[ -f "$STATE_DIR/flow/$EVIDENCE" ] && exit 0

# --- Exempt targets: tests (single shared pattern source — an edit that
# would stamp evidence is never itself warned/blocked), docs, config ---
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
sh "$HOOKS_DIR/lib/test-paths.sh" "$FILE_PATH" 2>/dev/null && exit 0
case "$FILE_PATH" in
    *.md|*.yml|*.yaml|*.json|*.toml|*.txt) exit 0 ;;
esac

# --- Missing evidence for the gate the cursor sits on ---
# If the gate has already FAILED, the correct move is its fail edge — name it.
FAIL_TARGET=$(printf '%s' "$NODE_CLEAN" | sed -n 's/.*fail: \([a-zA-Z0-9-]*\).*/\1/p')
REMEDY="produce the evidence (e.g. write/run the tests)"
if [ -n "$FAIL_TARGET" ] && [ "$FAIL_TARGET" != "STOP" ]; then
    REMEDY="$REMEDY; if the gate FAILED, take its fail edge: sh .claude/hooks/lib/graph-state.sh enter $CUR_FLOW $FAIL_TARGET"
fi
EXPLAIN_MODE="${EXOSUIT_EXPLAIN_MODE:-brief}"
if [ "$FLOW_MODE" = "block" ]; then
    if [ "$EXPLAIN_MODE" = "verbose" ]; then
        printf 'Flow gate: /%s is at gate '\''%s'\'' which requires evidence '\''%s'\'' before source edits.\n  WHY: The gate declares mechanically checkable evidence (see flow.yaml and FLOW_SPEC.md). Remedy: %s. Set EXOSUIT_FLOW_MODE=advisory to warn instead of block.\n' "$CUR_FLOW" "$CUR_NODE" "$EVIDENCE" "$REMEDY" >&2
    else
        printf 'Flow gate: /%s at '\''%s'\'' requires evidence '\''%s'\''. Remedy: %s. (EXOSUIT_FLOW_MODE=advisory to warn instead.)\n' "$CUR_FLOW" "$CUR_NODE" "$EVIDENCE" "$REMEDY" >&2
    fi
    exit 2
fi
# Advisory: warn ONCE per (flow, node, evidence) — not on every edit.
# '.' separates the fields ('-' is legal inside kebab ids and would let
# distinct (flow, node) pairs collide on one marker).
ADVISED_MARK="$STATE_DIR/flow/.advised-$CUR_FLOW.$CUR_NODE.$EVIDENCE"
[ -f "$ADVISED_MARK" ] && exit 0
if [ "$EXPLAIN_MODE" != "off" ]; then
    printf 'Flow advisory: /%s is at gate '\''%s'\'' — evidence '\''%s'\'' not yet observed this session. %s.\n' "$CUR_FLOW" "$CUR_NODE" "$EVIDENCE" "$REMEDY" >&2
    mkdir -p "$STATE_DIR/flow" 2>/dev/null
    date -u +"%Y-%m-%dT%H:%M:%SZ" > "$ADVISED_MARK" 2>/dev/null
fi
exit 0
