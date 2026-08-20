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
# Ownership rules (a cursor is a rider, never a squatter):
#   - If the file exists and its `skill:` differs from <flow>, every verb is
#     a silent no-op — another skill's interrupted state is never touched.
#   - If no file exists, `enter` creates a minimal one marked
#     `cursor_owned: true`; `clear` DELETES a cursor-owned file (so a normal
#     completed run leaves no phantom "interrupted workflow" behind) but only
#     strips the cursor keys from skill-owned files.
#
# Usage: sh .claude/hooks/lib/graph-state.sh <verb> <flow> [<node>]
#   enter <flow> <node>   Set cursor to (flow, node), attempt 1.
#   attempt <flow> <node> Increment attempt at (flow, node); enter otherwise.
#   clear <flow>          Delete cursor-owned file / strip keys otherwise.
#   show                  Print "flow node attempt branch" (empty if none).
#
# Advisory only: ALWAYS exits 0. A cursor failure must never break a skill.
# Corrupt files (frontmatter not opening at line 1, or missing its closing
# `---`) are left byte-for-byte untouched. POSIX sh — no bash required.
# Reserved keys never written: skill:/phase_name:/goal: (parsed by stop.sh,
# pre-compact.sh, status-line.sh).

# Character ranges in shell globs are COLLATION-dependent: under en_US.UTF-8
# (the macOS CI default) '[!a-z0-9-]' does not match uppercase, so valid_id
# below would accept 'UPPER' and write ids the readers never expect. Force the
# C locale so every pattern match in this script is byte-ordered and portable.
LC_ALL=C
export LC_ALL

# Resolve the project root so the cursor always lands on the ONE state file
# every consumer reads, regardless of the CWD the skill invoked us from.
# A CWD-relative path silently creates a stray docs/sessions/ inside whatever
# subdirectory happened to be current (the T01-001 failure class).
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
[ -n "$PROJECT_ROOT" ] || PROJECT_ROOT="$(pwd)"
SESSIONS_DIR="$PROJECT_ROOT/docs/sessions"
STATE_FILE="$SESSIONS_DIR/.failure-state.md"

VERB="${1:-}"
FLOW="${2:-}"
NODE="${3:-}"

# Validate ids (kebab-case per FLOW_SPEC) — reject anything else silently.
valid_id() {
    case "$1" in
        ''|*[!a-z0-9-]*) return 1 ;;
        -*) return 1 ;;
    esac
    return 0
}

CUR_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

# Well-formedness gate: frontmatter opens at line 1, a closing --- exists,
# and the file has no CRLF endings (consistent with validate-flows.sh).
# Every verb no-ops on files that fail this — corrupt state is preserved
# byte-for-byte, never read, never written, never deleted.
fs_wellformed() {
    [ -f "$STATE_FILE" ] || return 1
    grep -q "$(printf '\r')" "$STATE_FILE" 2>/dev/null && return 1
    head -1 "$STATE_FILE" 2>/dev/null | grep -q '^---[[:space:]]*$' || return 1
    [ "$(grep -c '^---[[:space:]]*$' "$STATE_FILE" 2>/dev/null)" -ge 2 ] || return 1
    return 0
}

# Read a frontmatter value: only between the opening --- (line 1) and the
# closing --- ; first match wins; surrounding quotes stripped.
fs_get() {
    awk -v k="$1" '
        NR == 1 { if ($0 ~ /^---[[:space:]]*$/) { fm = 1; next } else exit }
        /^---[[:space:]]*$/ { exit }
        fm && index($0, k ":") == 1 {
            v = substr($0, length(k) + 2)
            sub(/^[[:space:]]+/, "", v); sub(/^"/, "", v); sub(/"$/, "", v)
            print v; exit
        }
    ' "$STATE_FILE" 2>/dev/null
}

# Rewrite the file, setting (or inserting before the closing ---) the given
# frontmatter keys. Aborts without touching the file unless the frontmatter
# opens at line 1 AND closes — corrupt files stay byte-identical.
# Args: one string of key=value pairs separated by \037.
fs_set() {
    [ -f "$STATE_FILE" ] || return 0
    tmp="$STATE_FILE.tmp.$$"
    if awk -v pairs="$*" '
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
        NR == 1 {
            if ($0 ~ /^---[[:space:]]*$/) { fm = 1; print; next }
            exit 1
        }
        /^---[[:space:]]*$/ {
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
        END { if (done_fm == 0) exit 1 }
    ' "$STATE_FILE" > "$tmp" 2>/dev/null; then
        mv "$tmp" "$STATE_FILE" 2>/dev/null
    fi
    rm -f "$tmp" 2>/dev/null
    return 0
}

# Remove the cursor keys from frontmatter (whole lines only)
fs_clear_cursor() {
    [ -f "$STATE_FILE" ] || return 0
    tmp="$STATE_FILE.tmp.$$"
    if awk '
        BEGIN { fm = 0 }
        NR == 1 { if ($0 ~ /^---[[:space:]]*$/) { fm = 1; print; next } else exit 1 }
        /^---[[:space:]]*$/ { if (fm == 1) fm = 2; print; next }
        {
            if (fm == 1 && ($0 ~ /^flow:/ || $0 ~ /^node:/ || $0 ~ /^attempt:/ || $0 ~ /^cursor_owned:/)) next
            print
        }
        END { if (fm < 2) exit 1 }
    ' "$STATE_FILE" > "$tmp" 2>/dev/null; then
        mv "$tmp" "$STATE_FILE" 2>/dev/null
    fi
    rm -f "$tmp" 2>/dev/null
    return 0
}

# Create a minimal, schema-conformant, cursor-owned failure-state file
fs_create() {
    mkdir -p "$SESSIONS_DIR" 2>/dev/null || return 0
    cat > "$STATE_FILE" 2>/dev/null <<EOF
---
status: active
skill: $FLOW
started_at: "$TS"
branch: "$CUR_BRANCH"
cursor_owned: true
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

# Ownership gate: returns 0 when the cursor may write to the existing file
may_write() {
    owner=$(fs_get skill)
    [ -z "$owner" ] || [ "$owner" = "$FLOW" ]
}

cursor_write() {
    if [ -f "$STATE_FILE" ]; then
        fs_wellformed || return 0
        may_write || return 0
        fs_set "flow=$FLOW$(printf '\037')node=$NODE$(printf '\037')attempt=$1$(printf '\037')branch=\"$CUR_BRANCH\""
    else
        fs_create
    fi
}

case "$VERB" in
    enter)
        valid_id "$FLOW" && valid_id "$NODE" || exit 0
        cursor_write 1
        ;;
    attempt)
        valid_id "$FLOW" && valid_id "$NODE" || exit 0
        if fs_wellformed && [ "$(fs_get flow)" = "$FLOW" ] && [ "$(fs_get node)" = "$NODE" ]; then
            may_write || exit 0
            cur=$(fs_get attempt)
            case "$cur" in ''|*[!0-9]*) cur=0 ;; esac
            fs_set "attempt=$((cur + 1))"
        else
            cursor_write 1
        fi
        ;;
    clear)
        valid_id "$FLOW" || exit 0
        if fs_wellformed; then
            if [ "$(fs_get cursor_owned)" = "true" ] && [ "$(fs_get skill)" = "$FLOW" ]; then
                rm -f "$STATE_FILE" 2>/dev/null
            elif may_write; then
                fs_clear_cursor
            fi
        fi
        ;;
    show)
        if fs_wellformed; then
            sf=$(fs_get flow); sn=$(fs_get node)
            # No cursor -> no output (empty positional fields are ambiguous)
            if [ -n "$sf" ] && [ -n "$sn" ]; then
                printf '%s %s %s %s\n' "$sf" "$sn" "$(fs_get attempt)" "$(fs_get branch)"
            fi
        fi
        ;;
esac

exit 0
