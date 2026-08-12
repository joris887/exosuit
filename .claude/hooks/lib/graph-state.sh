#!/bin/sh
# graph-state.sh — flow cursor helper for flow contracts (see .claude/skills/FLOW_SPEC.md)
#
# Maintains the flow cursor — additive `flow:`/`node:`/`attempt:` keys in the
# YAML frontmatter of docs/sessions/.failure-state.md — so an interrupted
# skill run can resume at the exact node instead of being reconstructed from
# git archaeology. The cursor is branch-scoped: readers compare the file's
# `branch:` against `git branch --show-current` and ignore mismatches (a new
# worktree inherits a verbatim copy of the file by design).
#
# Usage: sh .claude/hooks/lib/graph-state.sh <verb> <flow> [<node>]
#   enter <flow> <node>   Set cursor to (flow, node), attempt 1. Creates a
#                         minimal failure-state file if none exists; otherwise
#                         updates/inserts only the cursor keys (and branch:),
#                         preserving every other line byte-for-byte.
#   attempt <flow> <node> Increment attempt for (flow, node); acts as enter
#                         if the stored cursor is a different flow/node.
#   clear <flow>          Remove the cursor keys. Never deletes the file —
#                         file lifecycle belongs to the owning skill.
#   show                  Print "flow node attempt branch" (empty if no cursor).
#
# Advisory only: ALWAYS exits 0. A cursor failure must never break a skill.
# POSIX-compliant — no bash required. Reserved keys never written or touched:
# skill:/phase_name:/goal: (parsed by stop.sh, pre-compact.sh, status-line.sh).

SESSIONS_DIR="docs/sessions"
STATE_FILE="$SESSIONS_DIR/.failure-state.md"

VERB="${1:-}"
FLOW="${2:-}"
NODE="${3:-}"

CUR_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

# Read a frontmatter value: first matching key line, prefix stripped, quotes trimmed
fs_get() {
    grep "^$1:" "$STATE_FILE" 2>/dev/null | head -1 | sed "s/^$1:[[:space:]]*//; s/^\"//; s/\"\$//"
}

# Rewrite the file, setting (or inserting before the closing ---) the given
# frontmatter keys. Args: key=value pairs, applied inside frontmatter only.
# Uses a tmpfile + mv (portable across GNU/BSD; no sed -i).
fs_set() {
    [ -f "$STATE_FILE" ] || return 0
    tmp="$STATE_FILE.tmp.$$"
    awk -v pairs="$*" '
        BEGIN {
            n = split(pairs, kv, "\037")
            for (i = 1; i <= n; i++) {
                eq = index(kv[i], "=")
                if (eq == 0) continue
                k = substr(kv[i], 1, eq - 1); v = substr(kv[i], eq + 1)
                val[k] = v; pending[k] = 1
            }
            fm = 0; done_fm = 0
        }
        /^---[[:space:]]*$/ {
            if (fm == 0) { fm = 1; print; next }
            if (fm == 1 && done_fm == 0) {
                for (k in pending) if (pending[k]) print k ": " val[k]
                done_fm = 1; print; next
            }
            print; next
        }
        {
            if (fm == 1 && done_fm == 0) {
                for (k in pending) {
                    if (pending[k] && index($0, k ":") == 1) {
                        print k ": " val[k]; pending[k] = 0; next
                    }
                }
            }
            print
        }
    ' "$STATE_FILE" > "$tmp" 2>/dev/null && mv "$tmp" "$STATE_FILE" 2>/dev/null
    rm -f "$tmp" 2>/dev/null
    return 0
}

# Remove the cursor keys from frontmatter (whole lines only)
fs_clear_cursor() {
    [ -f "$STATE_FILE" ] || return 0
    tmp="$STATE_FILE.tmp.$$"
    awk '
        BEGIN { fm = 0 }
        /^---[[:space:]]*$/ { fm++; print; next }
        {
            if (fm == 1 && ($0 ~ /^flow:/ || $0 ~ /^node:/ || $0 ~ /^attempt:/)) next
            print
        }
    ' "$STATE_FILE" > "$tmp" 2>/dev/null && mv "$tmp" "$STATE_FILE" 2>/dev/null
    rm -f "$tmp" 2>/dev/null
    return 0
}

# Create a minimal, schema-conformant failure-state file (cursor-owned)
fs_create() {
    mkdir -p "$SESSIONS_DIR" 2>/dev/null || return 0
    cat > "$STATE_FILE" 2>/dev/null <<EOF
---
status: active
skill: $FLOW
started_at: "$TS"
branch: "$CUR_BRANCH"
flow: $FLOW
node: $NODE
attempt: 1
---

## Context
Cursor-managed state (graph-state.sh). See the skill's flow.yaml for the
node map; resume guidance in FLOW_SPEC.md and /continue step 0.5.
EOF
    return 0
}

case "$VERB" in
    enter)
        [ -n "$FLOW" ] && [ -n "$NODE" ] || exit 0
        if [ -f "$STATE_FILE" ]; then
            fs_set "flow=$FLOW$(printf '\037')node=$NODE$(printf '\037')attempt=1$(printf '\037')branch=\"$CUR_BRANCH\""
        else
            fs_create
        fi
        ;;
    attempt)
        [ -n "$FLOW" ] && [ -n "$NODE" ] || exit 0
        if [ -f "$STATE_FILE" ] && [ "$(fs_get flow)" = "$FLOW" ] && [ "$(fs_get node)" = "$NODE" ]; then
            cur=$(fs_get attempt)
            case "$cur" in ''|*[!0-9]*) cur=0 ;; esac
            fs_set "attempt=$((cur + 1))"
        else
            # different (flow, node) — behave as enter
            if [ -f "$STATE_FILE" ]; then
                fs_set "flow=$FLOW$(printf '\037')node=$NODE$(printf '\037')attempt=1$(printf '\037')branch=\"$CUR_BRANCH\""
            else
                fs_create
            fi
        fi
        ;;
    clear)
        fs_clear_cursor
        ;;
    show)
        if [ -f "$STATE_FILE" ]; then
            printf '%s %s %s %s\n' "$(fs_get flow)" "$(fs_get node)" "$(fs_get attempt)" "$(fs_get branch)"
        fi
        ;;
esac

exit 0
