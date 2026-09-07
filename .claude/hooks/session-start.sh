#!/bin/sh
# SessionStart handler: advisory environment checks.
# Validates project tools, detects stale state, checks git health.
# Never blocks (advisory only, always exit 0).
# POSIX-compliant — no bash required.
#
# Output: warnings on stderr. The ONLY stdout is the one-line "Stream:" banner
# of the parallel-stream section below, printed inside a parallel stream
# (SessionStart stdout is added to the model's context).

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="$HOOKS_DIR/state"
WARNINGS=""

# --- Hook guard: profile + disable check ---
"$HOOKS_DIR/lib/hook-guard.sh" "session-start" "minimal" || exit 0

# --- Helper: append warning ---
warn() {
    if [ -z "$WARNINGS" ]; then
        WARNINGS="$1"
    else
        WARNINGS="$WARNINGS
  - $1"
    fi
}

# --- 1. Check project tool availability from CLAUDE.md ---
if [ -f "CLAUDE.md" ]; then
    for key in "test:" "lint:" "format:" "build:" "typecheck:"; do
        CMD=$(grep "$key" CLAUDE.md 2>/dev/null | sed "s/.*$key//" | awk '{print $1}' | head -1)
        if [ -n "$CMD" ]; then
            case "$CMD" in
                '<'*|'#'*|'') continue ;;
            esac
            if ! command -v "$CMD" >/dev/null 2>&1; then
                warn "Tool '$CMD' (from CLAUDE.md Commands) not found in PATH"
            fi
        fi
    done
fi

# --- 2. Stale session detection ---
AUTO_SAVE="docs/sessions/.auto-save.md"
if [ -f "$AUTO_SAVE" ]; then
    if command -v stat >/dev/null 2>&1; then
        # macOS stat vs GNU stat
        MTIME=$(stat -f %m "$AUTO_SAVE" 2>/dev/null || stat -c %Y "$AUTO_SAVE" 2>/dev/null || echo 0)
        NOW=$(date +%s 2>/dev/null || echo 0)
        if [ "$MTIME" -gt 0 ] && [ "$NOW" -gt 0 ]; then
            AGE=$((NOW - MTIME))
            if [ "$AGE" -gt 14400 ]; then
                # 14400s = 4 hours. Catch recent auto-saves more aggressively.
                HOURS=$((AGE / 3600))
                if [ "$HOURS" -ge 24 ]; then
                    DAYS=$((AGE / 86400))
                    warn "Stale auto-save detected ($AUTO_SAVE is ${DAYS}d old) -- run /continue to resume"
                else
                    warn "Recent auto-save detected ($AUTO_SAVE is ${HOURS}h old) -- run /continue to resume"
                fi
            fi
        fi
    fi
fi

# --- 3. Git state checks ---
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    BRANCH=$(git branch --show-current 2>/dev/null)
    if [ -n "$BRANCH" ]; then
        case "$BRANCH" in
            main|master) warn "On $BRANCH branch -- create a feature branch before making changes" ;;
        esac
    else
        warn "Detached HEAD state -- checkout a branch before making changes"
    fi

    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        warn "Uncommitted changes detected -- consider committing or stashing before starting"
    fi
fi

# --- 4. Prompt injection defense: Unicode anomaly scan in AI config files ---
# Rules File Backdoor attack uses zero-width chars and bidirectional overrides to hide
# malicious instructions in AI config files. Scan for these obfuscation markers.
if [ -d ".claude" ]; then
    # Check for zero-width joiners, bidirectional overrides, and other Unicode obfuscation
    # Uses multiple -e flags for BSD/GNU grep compatibility (BSD grep doesn't support \| alternation)
    UNICODE_HITS=$(find .claude -type f \( -name "*.md" -o -name "*.json" -o -name "*.yaml" -o -name "*.yml" \) 2>/dev/null | head -50 | xargs grep -rl \
        -e "$(printf '\xe2\x80\x8b')" \
        -e "$(printf '\xe2\x80\x8c')" \
        -e "$(printf '\xe2\x80\x8d')" \
        -e "$(printf '\xe2\x80\x8e')" \
        -e "$(printf '\xe2\x80\x8f')" \
        -e "$(printf '\xe2\x80\xaa')" \
        -e "$(printf '\xe2\x80\xab')" \
        -e "$(printf '\xe2\x80\xac')" \
        -e "$(printf '\xe2\x80\xad')" \
        -e "$(printf '\xe2\x80\xae')" \
        2>/dev/null)
    if [ -n "$UNICODE_HITS" ]; then
        warn "Hidden Unicode characters detected in AI config files — possible prompt injection: $UNICODE_HITS"
    fi
fi

# --- 5. First-run detection: suggest /quickstart if framework is unconfigured ---
if [ -f "CLAUDE.md" ]; then
    if grep -q '\[Project Name\]' CLAUDE.md 2>/dev/null && [ ! -f "docs/architecture/ARCHITECTURE.md" ]; then
        warn "Framework installed but not configured — run /quickstart to get started"
    fi
fi

# --- 5.5 Parallel-stream banner (stdout: the model sees it) ---
# Inside a parallel stream (a worktree whose branch records
# branch.<b>.exosuitParent, written by the parallel-work skill) print exactly
# one line on stdout. For SessionStart, plain stdout is added to the model's
# context, so this is the only stdout this hook writes; every warning above
# stays on stderr. Silent outside a stream, on detached HEAD, without git, when
# the parent key is unset, and when the recorded parent is not a name a git ref
# can have (that last one says why on stderr). Re-emitted on resume, /clear,
# compaction and fork (three to four git calls; advisory context, never a gate).
STREAM_LINE=""
if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    # Branch by full symbolic ref (never --short: a tag with the same name
    # would print heads/<b>); empty on detached HEAD.
    STREAM_REF=$(git symbolic-ref -q HEAD 2>/dev/null)
    STREAM_B="${STREAM_REF#refs/heads/}"
    STREAM_P=""
    if [ -n "$STREAM_B" ]; then
        # Reject the recorded parent, never rewrite it. A value with characters
        # filtered out of it names a different branch, or none at all, and
        # announcing that as this stream's parent is worse than saying nothing:
        # the behind count against it cannot resolve, so the "run /merge-down"
        # nudge disappears with no explanation (release/2.0+rc1 was announced as
        # release/2.0rc1 before this). Control characters, DEL and space can
        # never appear in a ref (git-check-ref-format rejects all three), and
        # they are also the bytes that could forge or pad a line of the model's
        # context, so a parent holding one is not announced at all — one stderr
        # warning instead. Everything a ref may hold ('+', non-ASCII) prints
        # verbatim, bounded to 120 characters as before.
        STREAM_P_RAW=$(git config "branch.$STREAM_B.exosuitParent" 2>/dev/null)
        if [ -n "$STREAM_P_RAW" ]; then
            if [ "$STREAM_P_RAW" = "$(printf '%s' "$STREAM_P_RAW" | LC_ALL=C tr -d '\000-\040\177')" ]; then
                STREAM_P=$(printf '%s' "$STREAM_P_RAW" | cut -c1-120)
            else
                warn "Parallel-stream banner suppressed: branch.$STREAM_B.exosuitParent holds a control character, DEL or space, which no git ref can — re-record it with: git config branch.$STREAM_B.exosuitParent '<parent>'"
            fi
        fi
    fi
    if [ -n "$STREAM_P" ]; then
        STREAM_S=$(git config "branch.$STREAM_B.exosuitStory" 2>/dev/null | LC_ALL=C tr -cd 'A-Za-z0-9._/ -' | cut -c1-60)
        # behind = LEFT of --left-right --count (commits on the parent that
        # this stream lacks); printed only when the count succeeds and is > 0.
        STREAM_N=0
        if STREAM_LR=$(git rev-list --left-right --count "refs/heads/$STREAM_P...HEAD" 2>/dev/null); then
            STREAM_N="${STREAM_LR%%[!0-9]*}"
        fi
        case "$STREAM_N" in
            ''|*[!0-9]*) STREAM_N=0 ;;
        esac
        # Default branch, same rule as worktree-status.sh: branch.<p>.remote,
        # else origin when listed, else the first remote; that remote's HEAD
        # symref with the remote prefix stripped; else local main, else
        # local master; else none (no variant).
        STREAM_R=$(git config "branch.$STREAM_P.remote" 2>/dev/null)
        if [ -z "$STREAM_R" ]; then
            STREAM_REMOTES=$(git remote 2>/dev/null)
            if printf '%s\n' "$STREAM_REMOTES" | grep -qx origin; then
                STREAM_R=origin
            else
                STREAM_R=$(printf '%s\n' "$STREAM_REMOTES" | head -1)
            fi
        fi
        STREAM_DEF=""
        if [ -n "$STREAM_R" ]; then
            STREAM_DEF_REF=$(git symbolic-ref -q "refs/remotes/$STREAM_R/HEAD" 2>/dev/null)
            STREAM_DEF="${STREAM_DEF_REF#"refs/remotes/$STREAM_R/"}"
        fi
        if [ -z "$STREAM_DEF" ]; then
            if git show-ref --verify --quiet refs/heads/main 2>/dev/null; then
                STREAM_DEF=main
            elif git show-ref --verify --quiet refs/heads/master 2>/dev/null; then
                STREAM_DEF=master
            fi
        fi
        STREAM_LINE="Stream: $STREAM_B <- parent $STREAM_P"
        if [ -n "$STREAM_S" ]; then
            STREAM_LINE="$STREAM_LINE · story $STREAM_S"
        fi
        if [ "$STREAM_N" -gt 0 ]; then
            STREAM_LINE="$STREAM_LINE · behind $STREAM_N — run /merge-down"
        fi
        if [ "$STREAM_P" = "$STREAM_DEF" ]; then
            STREAM_LINE="$STREAM_LINE. Publish through a sprint branch and a pull request (/merge-up refuses the default branch), roster with /parallel-work."
        else
            STREAM_LINE="$STREAM_LINE. Publish with /merge-up, pull with /merge-down, roster with /parallel-work."
        fi
    fi
fi
if [ -n "$STREAM_LINE" ]; then
    printf '%s\n' "$STREAM_LINE"
fi

# --- 6. Initialize session state ---
mkdir -p "$STATE_DIR" 2>/dev/null
date -u +"%Y-%m-%dT%H:%M:%SZ" > "$STATE_DIR/session-started" 2>/dev/null
# Reset stop iteration counter
echo "0" > "$STATE_DIR/stop-iteration" 2>/dev/null
# Clear skill suggestion dedup state
rm -f "$STATE_DIR/suggestions-shown" 2>/dev/null

# --- Output warnings ---
if [ -n "$WARNINGS" ]; then
    printf 'Session start checks:\n  - %s\n' "$WARNINGS" >&2
fi

exit 0
