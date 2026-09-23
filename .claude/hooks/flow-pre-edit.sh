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
#   advisory — PreToolUse JSON (additionalContext + systemMessage), never
#              blocks (exit 0), warns once per (flow, node, evidence)
#   block    — exit 2 ONLY on positive red evidence: a recognized test
#              runner demonstrably FAILED this session (state/flow/tests-red)
#              and no green run has been seen since. Missing evidence — an
#              unrecognized runner, or no run yet — is ignorance, not
#              failure, and never blocks (falls through to the advisory).
#
# Exemptions (never warns/blocks): edits to test files (writing a test IS the
# evidence being asked for; shared patterns in lib/test-paths.sh), docs/config
# (.md/.yml/.yaml/.json/.toml/.txt), and anything when no branch-matched
# cursor exists. Advisory warns ONCE per (flow, node, evidence), not on every
# edit. Fail-open on every error.
# POSIX-compliant — no bash required.

# --- Short-circuit: no cursor file => nothing to enforce (zero-cost path) ---
# The hook registration cd's to the git toplevel first (hooks.json /
# settings.json — see README, the hook depends on that wrapper), so this
# relative path is the same file graph-state.sh resolves via git rev-parse.
# [ -f ] is a builtin and a cursor always writes 'flow:' at column 0 of
# the frontmatter (graph-state.sh), so the common no-flow case costs zero
# external processes — instead of the ~15 the full path spawns per edit.
# A false positive (a 'flow:' body line) just falls through to the real
# frontmatter-scoped parse below. Fail-open as ever.
[ -f "docs/sessions/.failure-state.md" ] || exit 0
grep -q '^flow:' "docs/sessions/.failure-state.md" 2>/dev/null || exit 0

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
# Set by the block branch when its iteration valve releases; appended to
# the advisory so the release is explicitly announced, never silent.
VALVE_NOTE=""

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
# needs it to read tool output) — without jq the marker is unproducible.
# No jq also means no tests-red, so block mode could never fire anyway;
# exiting here just suppresses a perpetual, unfixable advisory.
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
# Block ONLY on positive red evidence: a recognized runner demonstrably
# FAILED this session (state/flow/tests-red, stamped by post-tool-use.sh)
# and no green run has been observed since. An unrecognized runner or a
# session with no observed run leaves NO red marker — that is ignorance,
# not failure, and ignorance never blocks (a runner whose output the
# patterns cannot read can never wall off edits). Evidence classes with
# no red analog (test-written) can never block.
if [ "$FLOW_MODE" = "block" ] && [ "$EVIDENCE" = "tests-green" ] && [ -f "$STATE_DIR/flow/tests-red" ]; then
    # Iteration valve (mirrors stop.sh's stop-iteration): after N blocked
    # edits on the SAME gate with no evidence progress, blocking has
    # stopped helping — release to advisory with an explicit note. '.'
    # separates the counter-file fields for the same collision reason as
    # the .advised- marks. Session-start's state/flow/* clear resets it;
    # a green run makes this branch unreachable, so no other reset needed.
    BLOCK_MAX="${EXOSUIT_FLOW_MAX_BLOCKS:-3}"
    case "$BLOCK_MAX" in ''|*[!0-9]*) BLOCK_MAX=3 ;; esac
    BLOCKED_MARK="$STATE_DIR/flow/.blocked-$CUR_FLOW.$CUR_NODE.$EVIDENCE"
    BLOCKED=$(cat "$BLOCKED_MARK" 2>/dev/null | tr -d '[:space:]')
    case "$BLOCKED" in ''|*[!0-9]*) BLOCKED=0 ;; esac
    if [ "$BLOCKED" -lt "$BLOCK_MAX" ]; then
        mkdir -p "$STATE_DIR/flow" 2>/dev/null
        echo $((BLOCKED + 1)) > "$BLOCKED_MARK" 2>/dev/null
        if [ "$EXPLAIN_MODE" = "verbose" ]; then
            printf 'Flow gate: /%s is at gate '\''%s'\'' which requires evidence '\''%s'\'' — the last observed test run FAILED.\n  WHY: state/flow/tests-red is stamped when a recognized test command demonstrably fails, and revoked by a green run (see FLOW_SPEC.md). Remedy: %s. (Block %s of %s, then advisory. Set EXOSUIT_FLOW_MODE=advisory to warn instead of block.)\n' "$CUR_FLOW" "$CUR_NODE" "$EVIDENCE" "$REMEDY" "$((BLOCKED + 1))" "$BLOCK_MAX" >&2
        else
            printf 'Flow gate: /%s at '\''%s'\'' requires evidence '\''%s'\'' and the last observed test run FAILED. Remedy: %s. (Block %s of %s, then advisory. EXOSUIT_FLOW_MODE=advisory to warn instead.)\n' "$CUR_FLOW" "$CUR_NODE" "$EVIDENCE" "$REMEDY" "$((BLOCKED + 1))" "$BLOCK_MAX" >&2
        fi
        exit 2
    fi
    VALVE_NOTE=" [block valve released after $BLOCKED blocked edits — advisory from here; evidence '$EVIDENCE' is still wanted]"
fi
# Everything else — block mode without red evidence included — falls
# through to the advisory below.
# Advisory: warn ONCE per (flow, node, evidence) — not on every edit.
# '.' separates the fields ('-' is legal inside kebab ids and would let
# distinct (flow, node) pairs collide on one marker). A valve release is
# its own announcement: it uses a distinct mark so the earlier plain
# advisory can never have deduplicated it away.
ADVISED_MARK="$STATE_DIR/flow/.advised-$CUR_FLOW.$CUR_NODE.$EVIDENCE${VALVE_NOTE:+.valve}"
[ -f "$ADVISED_MARK" ] && exit 0
if [ "$EXPLAIN_MODE" != "off" ]; then
    # PreToolUse stderr on exit 0 reaches the DEBUG LOG ONLY — not the model,
    # not the user. An advisory printed there is invisible, so emit the
    # supported JSON instead: hookSpecificOutput.additionalContext is injected
    # for the model, systemMessage surfaces to the user. NO permissionDecision:
    # 'allow' SKIPS the user's permission prompt — an advisory that
    # auto-approves the very edit it warns about. Omitting the field leaves
    # the normal permission flow untouched; additionalContext and
    # systemMessage are honored independently.
    ADV_MSG="Flow advisory: /$CUR_FLOW is at gate '$CUR_NODE' — evidence '$EVIDENCE' not yet observed this session. $REMEDY.$VALVE_NOTE"
    # Escape for JSON string context (backslash first, then quote; strip CR).
    ADV_JSON=$(printf '%s' "$ADV_MSG" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\r//g')
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"%s"},"systemMessage":"%s"}\n' "$ADV_JSON" "$ADV_JSON"
    mkdir -p "$STATE_DIR/flow" 2>/dev/null
    date -u +"%Y-%m-%dT%H:%M:%SZ" > "$ADVISED_MARK" 2>/dev/null
fi
exit 0
