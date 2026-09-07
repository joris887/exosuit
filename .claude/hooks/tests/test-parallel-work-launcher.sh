#!/usr/bin/env bash
# Usage: bash test-parallel-work-launcher.sh
#        bash test-parallel-work-launcher.sh -h | --help
#
# Test suite for .claude/skills/parallel-work/scripts/open-worktree-terminals.sh
# (the launcher): groups launcher, terminal and windows of the parallel-work
# test plan. No real terminal is ever opened and no claude session is ever
# started: every launcher run gets a private PATH made only of stub
# executables (osascript, uname, defaults, wt.exe, wsl.exe, cygpath,
# gnome-terminal, konsole, claude) plus symlinks to the few real tools the
# launcher needs (git, sed, awk, tr, grep, cat), and EXOSUIT_WORKTREE_OSASCRIPT
# always names the stub osascript. A guard refuses the whole run when that
# variable is unset or points outside the stub directory, and the same guard
# runs again before every launcher invocation.
#
# Fixture: one git repository under "$(mktemp -d)/my repo #1/proj" (a space and
# a '#' in the path) with linked worktrees on branches so --name resolves,
# including an unsafe branch (a;b), a non-ASCII branch and a worktree whose
# directory carries an apostrophe, double quotes and a backslash. Every
# launcher run captures stdout and stderr to files, never through a pipe, and
# runs under LC_ALL=C unless a case says otherwise.
#
# stdout:
#   Testing parallel-work launcher
#   ==============================
#     -- <group> --
#     PASS: <case>
#     FAIL: <case> (expected '<expected>', got '<actual>')
#   Results: <N> passed, <M> failed
# stderr:
#   REFUSING TO RUN: <reason>            (safety guard; nothing was executed)
#   fixture error: <reason>
#
# Exit codes:
#   0  every check passed
#   1  a check failed, the safety guard refused, or the fixture could not be built
set -uo pipefail

case "${1:-}" in
  -h|--help)
    sed -n '/^# Usage:/,/^set -/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'
    exit 0
    ;;
esac

PASS=0
FAIL=0

test_case() {
    local desc="$1"
    local expected="$2"
    local actual="$3"

    if [ "$actual" = "$expected" ]; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected '$expected', got '$actual')"
        FAIL=$((FAIL + 1))
    fi
}

echo "Testing parallel-work launcher"
echo "=============================="

# --- Locations ----------------------------------------------------------------

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
LAUNCHER="$TESTS_DIR/../../skills/parallel-work/scripts/open-worktree-terminals.sh"
if [ ! -f "$LAUNCHER" ]; then
    echo "fixture error: launcher not found at $LAUNCHER" >&2
    exit 1
fi
LAUNCHER="$(cd "$(dirname "$LAUNCHER")" && pwd)/open-worktree-terminals.sh"

# An explicit template: macOS mktemp -d ignores TMPDIR without one.
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/exosuit-launcher-tests.XXXXXX") || { echo "fixture error: mktemp failed" >&2; exit 1; }
trap 'rm -rf "$TMP_ROOT"' EXIT

STUBDIR="$TMP_ROOT/stubs"
TOOLDIR="$TMP_ROOT/tools"
HIDE_ROOT="$TMP_ROOT/hide"
WORK="$TMP_ROOT/work"
FAKE_HOME="$TMP_ROOT/home"
mkdir -p "$STUBDIR" "$TOOLDIR" "$HIDE_ROOT" "$WORK" "$FAKE_HOME"

OSA_LOG="$WORK/osascript.log"
WT_LOG="$WORK/argv.log"
CLAUDE_LOG="$WORK/claude.log"
: > "$OSA_LOG"
: > "$WT_LOG"
: > "$CLAUDE_LOG"

# --- Stubs (POSIX sh; nothing here opens, activates or types anything) --------

cat > "$STUBDIR/osascript" <<'STUB'
#!/bin/sh
# exosuit test stub: osascript — records its stdin to $OSA_LOG and never talks to any app
script=$(cat)
printf '=== osascript call ===\n%s\n' "$script" >> "${OSA_LOG:-/dev/null}"
if [ -n "${OSA_SILENT_FAIL:-}" ]; then
  exit 1
fi
if [ -n "${OSA_FAIL_MATCH:-}" ]; then
  case "$script" in
    *"$OSA_FAIL_MATCH"*)
      printf '%s\n' "${OSA_FAIL_TEXT:-}" >&2
      exit 1
      ;;
  esac
fi
exit 0
STUB

cat > "$STUBDIR/uname" <<'STUB'
#!/bin/sh
# exosuit test stub: uname — prints $STUB_UNAME; the default Plan9 selects no opener
printf '%s\n' "${STUB_UNAME:-Plan9}"
STUB

cat > "$STUBDIR/defaults" <<'STUB'
#!/bin/sh
# exosuit test stub: defaults — domain-aware AppleWindowTabbingMode reader
v=""
if [ "${1:-}" = "read" ] && [ "${3:-}" = "AppleWindowTabbingMode" ]; then
  case "${2:-}" in
    com.apple.Terminal) v="${STUB_TABBING_APP:-}" ;;
    -g|NSGlobalDomain)  v="${STUB_TABBING_GLOBAL:-}" ;;
  esac
fi
if [ -n "$v" ]; then
  printf '%s\n' "$v"
  exit 0
fi
printf 'stub defaults: the domain/default pair does not exist\n' >&2
exit 1
STUB

cat > "$STUBDIR/claude" <<'STUB'
#!/bin/sh
# exosuit test stub: claude — records every invocation; the launcher must never reach it
line="claude"
for a in "$@"; do line="$line [$a]"; done
printf '%s\n' "$line" >> "${CLAUDE_LOG:-/dev/null}"
exit 0
STUB

# Argv recorders: one line per call, "<name> [arg] [arg] ...", appended to $WT_LOG.
write_recorder() {
    local name="$1" extra="${2:-}"
    {
        printf '#!/bin/sh\n'
        printf '# exosuit test stub: %s — argv recorder\n' "$name"
        printf 'line=${0##*/}\n'
        printf 'for a in "$@"; do line="$line [$a]"; done\n'
        printf '%s\n' 'printf '"'"'%s\n'"'"' "$line" >> "${WT_LOG:-/dev/null}"'
        [ -n "$extra" ] && printf '%s\n' "$extra"
        printf 'exit 0\n'
    } > "$STUBDIR/$name"
}
write_recorder "wt.exe" 'if [ -n "${WT_FAIL:-}" ]; then exit 1; fi
if [ -n "${WT_FAIL_MATCH:-}" ]; then case "$line" in *"$WT_FAIL_MATCH"*) exit 1 ;; esac; fi'
write_recorder "wsl.exe"
write_recorder "cygpath" 'if [ "${1:-}" = "-w" ]; then printf "C:%s\\n" "$(printf "%s" "${2:-}" | tr "/" "\\\\")"; fi'
write_recorder "gnome-terminal"
write_recorder "konsole"

chmod +x "$STUBDIR"/*
STUB_OSA="$STUBDIR/osascript"

# Real tools the launcher needs, symlinked so the PATH given to it holds nothing else.
for tool in git sed awk tr grep cat; do
    real=$(type -P "$tool" 2>/dev/null) || real=""
    if [ -z "$real" ]; then
        echo "fixture error: required tool '$tool' not found" >&2
        exit 1
    fi
    ln -s "$real" "$TOOLDIR/$tool"
done

export EXOSUIT_WORKTREE_OSASCRIPT="$STUB_OSA"

# --- Safety guard: refuse to run unless osascript is the stub ------------------

guard_osascript() {
    local v="${EXOSUIT_WORKTREE_OSASCRIPT:-}"
    case "$v" in
        "$STUBDIR"/osascript)
            if [ -x "$v" ] && LC_ALL=C grep -q 'exosuit test stub: osascript' "$v" 2>/dev/null; then
                return 0
            fi
            ;;
    esac
    echo "REFUSING TO RUN: EXOSUIT_WORKTREE_OSASCRIPT must name the stub osascript inside $STUBDIR (got '${v:-unset}')" >&2
    exit 1
}
guard_osascript

# hidden_stub_dir <name,name>: a stub directory without the named openers
# (only wt.exe, gnome-terminal and konsole may be hidden; osascript never).
hidden_stub_dir() {
    local names="$1" dir f base skip n
    dir="$HIDE_ROOT/$(printf '%s' "$names" | LC_ALL=C tr -c 'A-Za-z0-9' '_')"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        for f in "$STUBDIR"/*; do
            base=${f##*/}
            skip=0
            for n in $(printf '%s' "$names" | LC_ALL=C tr ',' ' '); do
                case "$n" in
                    wt.exe|gnome-terminal|konsole) [ "$n" = "$base" ] && skip=1 ;;
                    *) echo "REFUSING TO RUN: '$n' may not be hidden from the stub PATH" >&2; exit 1 ;;
                esac
            done
            [ "$skip" = "1" ] || ln -s "$f" "$dir/$base"
        done
    fi
    printf '%s' "$dir"
}

# --- Runner: every launcher invocation goes through here -----------------------

RUN_N=0
OUT=""
ERR=""
RC=0
# run_launcher [KEY=VAL ...] -- <dir> ...
#   KEY=VAL pairs go into the launcher's (otherwise empty) environment;
#   STUB_HIDE=<names> swaps in a stub directory without those openers;
#   LC_ALL=<x> overrides the default C. Sets OUT, ERR, RC; truncates the logs.
run_launcher() {
    local stub="$STUBDIR" hide="" kv
    local envs
    envs=()
    while [ "$#" -gt 0 ]; do
        kv=$1
        if [ "$kv" = "--" ]; then
            shift
            break
        fi
        case "$kv" in
            STUB_HIDE=*) hide=${kv#STUB_HIDE=} ;;
            *) envs+=("$kv") ;;
        esac
        shift
    done
    [ -n "$hide" ] && stub=$(hidden_stub_dir "$hide")
    guard_osascript
    RUN_N=$((RUN_N + 1))
    OUT="$WORK/run-$RUN_N.out"
    ERR="$WORK/run-$RUN_N.err"
    : > "$OSA_LOG"
    : > "$WT_LOG"
    env -i HOME="$FAKE_HOME" PATH="$stub:$TOOLDIR" LC_ALL=C \
        EXOSUIT_WORKTREE_OSASCRIPT="$STUB_OSA" \
        OSA_LOG="$OSA_LOG" WT_LOG="$WT_LOG" CLAUDE_LOG="$CLAUDE_LOG" \
        ${envs[@]+"${envs[@]}"} \
        "$BASH" "$LAUNCHER" "$@" > "$OUT" 2> "$ERR"
    RC=$?
}

# --- Assertion helpers ----------------------------------------------------------

has() {          # has <file> <fixed string> -> true|false
    if LC_ALL=C grep -qF -e "$2" -- "$1" 2>/dev/null; then echo true; else echo false; fi
}
count() {        # count <file> <fixed string> -> number of matching lines
    local n
    n=$(LC_ALL=C grep -cF -e "$2" -- "$1" 2>/dev/null) || n=0
    printf '%s' "$n"
}
nlines() {       # nlines <file>
    local n
    n=$(wc -l < "$1" | LC_ALL=C tr -d ' ')
    printf '%s' "$n"
}
line() {         # line <file> <n>
    sed -n "${2}p" "$1"
}
str_has() {      # str_has <string> <fixed substring> -> true|false (a case inside $() breaks bash 3.2)
    case "$1" in
        *"$2"*) echo true ;;
        *) echo false ;;
    esac
}
shq() {          # the test's own single-quoting, for expected strings
    printf '%s' "$1" | sed "s/'/'\\\\''/g"
}
cmd_named() {    # cmd_named <dir> <branch> -> the default per-directory command
    printf "cd '%s' && claude --name '%s' -- '/parallel-work hello'" "$(shq "$1")" "$2"
}
cmd_unnamed() {  # cmd_unnamed <dir>
    printf "cd '%s' && claude -- '/parallel-work hello'" "$(shq "$1")"
}
osa_calls() {    # number of recorded osascript invocations
    count "$OSA_LOG" "=== osascript call ==="
}
wt_line() {      # wt_line <tool> <n>: the n-th recorded call of that tool
    LC_ALL=C grep -e "^$1 " -- "$WT_LOG" | sed -n "${2}p"
}

# --- Fixture repository ---------------------------------------------------------

printf '[user]\n\tname = exosuit tests\n\temail = tests@example.invalid\n[init]\n\tdefaultBranch = main\n' > "$FAKE_HOME/.gitconfig"
fx_git() {
    HOME="$FAKE_HOME" GIT_CONFIG_NOSYSTEM=1 git "$@"
}

FIX="$TMP_ROOT/my repo #1"
mkdir -p "$FIX/proj"
REPO="$(cd "$FIX/proj" && pwd -P)"
FIX="$(cd "$FIX" && pwd -P)"
{
    fx_git -C "$REPO" init -q &&
    printf 'hello\n' > "$REPO/README.md" &&
    fx_git -C "$REPO" add README.md &&
    fx_git -C "$REPO" commit -q -m "init" &&
    fx_git -C "$REPO" checkout -q -b sprint-x &&
    fx_git -C "$REPO" worktree add -q -b sprint-x-a "$FIX/proj-a" sprint-x &&
    fx_git -C "$REPO" worktree add -q -b sprint-x-b "$FIX/proj-b" sprint-x &&
    fx_git -C "$REPO" worktree add -q -b 'a;b' "$FIX/proj-semi" sprint-x &&
    fx_git -C "$REPO" worktree add -q -b 'résumé' "$FIX/proj-utf" sprint-x &&
    fx_git -C "$REPO" worktree add -q -b feat/q2 "$FIX/it's \"q\" \\ #2" sprint-x
} > "$WORK/fixture.log" 2>&1 || {
    echo "fixture error: could not build the worktree fixture:" >&2
    cat "$WORK/fixture.log" >&2
    exit 1
}
DIR_A="$FIX/proj-a"
DIR_B="$FIX/proj-b"
DIR_SEMI="$FIX/proj-semi"
DIR_UTF="$FIX/proj-utf"
DIR_HOSTILE="$FIX/it's \"q\" \\ #2"
DIR_MISSING="$FIX/proj-missing"

PROC_WSL="$TMP_ROOT/proc-version-wsl"
PROC_LINUX="$TMP_ROOT/proc-version-linux"
printf 'Linux version 5.15.90.1-microsoft-standard-WSL2 (oe-user@oe-host) (gcc 9.3.0)\n' > "$PROC_WSL"
printf 'Linux version 6.5.0-14-generic (buildd@lcy02-amd64-028) (gcc 13.2.0)\n' > "$PROC_LINUX"

UTF8_LOCALE=""
for cand in en_US.UTF-8 C.UTF-8; do
    if [ -z "$UTF8_LOCALE" ] && locale -a 2>/dev/null | LC_ALL=C grep -qx "$cand"; then
        UTF8_LOCALE="$cand"
    fi
done
[ -n "$UTF8_LOCALE" ] || UTF8_LOCALE="en_US.UTF-8"

# ==============================================================================
echo ""
echo "  -- launcher --"

# launcher-01
run_launcher --
test_case "launcher-01 no args -> usage on stderr, exit 2" \
    "2:usage: open-worktree-terminals.sh <dir> [<dir> ...]:0" \
    "$RC:$(line "$ERR" 1):$(nlines "$OUT")"

# launcher-02
run_launcher EXOSUIT_WORKTREE_TABS=0 -- "$DIR_A" "$DIR_B"
test_case "launcher-02 EXOSUIT_WORKTREE_TABS=0 -> one cd && claude --name -- prompt line per dir, exit 0" \
    "0:Open a terminal per worktree and run::  $(cmd_named "$DIR_A" sprint-x-a):  $(cmd_named "$DIR_B" sprint-x-b):3" \
    "$RC:$(line "$OUT" 1):$(line "$OUT" 2):$(line "$OUT" 3):$(nlines "$OUT")"

# launcher-02b — a knob emptied by mistake must not open a window
run_launcher EXOSUIT_WORKTREE_TABS= STUB_UNAME=Darwin TERM_PROGRAM=Apple_Terminal -- "$DIR_A"
test_case "launcher-02b EXOSUIT_WORKTREE_TABS set but empty -> commands only, no opener called, exit 0" \
    "0:Open a terminal per worktree and run::0" \
    "$RC:$(line "$OUT" 1):$(osa_calls)"

# launcher-03
run_launcher EXOSUIT_WORKTREE_TABS=0 -- "$DIR_A" "$DIR_B"
CMD_LINE=$(line "$OUT" 2)
TAIL_AFTER_NAME=${CMD_LINE#*--name \'sprint-x-a\'}
test_case "launcher-03 -- precedes the first prompt" \
    " -- '/parallel-work hello'" \
    "$TAIL_AFTER_NAME"

# launcher-04
run_launcher EXOSUIT_WORKTREE_TABS=0 EXOSUIT_WORKTREE_FIRST_PROMPT= -- "$DIR_A"
test_case "launcher-04 empty EXOSUIT_WORKTREE_FIRST_PROMPT -> no prompt and no --" \
    "  cd '$DIR_A' && claude --name 'sprint-x-a':false" \
    "$(line "$OUT" 2):$(has "$OUT" ' -- ')"

# launcher-05
run_launcher EXOSUIT_WORKTREE_TABS=0 -- "$DIR_A"
test_case "launcher-05 unset prompt -> default /parallel-work hello" \
    "true" \
    "$(has "$OUT" " -- '/parallel-work hello'")"

# launcher-06
run_launcher EXOSUIT_WORKTREE_TABS=0 EXOSUIT_WORKTREE_NAME_SESSIONS=0 -- "$DIR_A"
test_case "launcher-06 EXOSUIT_WORKTREE_NAME_SESSIONS=0 -> no --name, -- still present" \
    "  $(cmd_unnamed "$DIR_A"):false" \
    "$(line "$OUT" 2):$(has "$OUT" '--name')"

# launcher-07
run_launcher EXOSUIT_WORKTREE_TABS=0 -- "$DIR_SEMI"
test_case "launcher-07 unnamed session (unsafe branch) still gets --" \
    "  $(cmd_unnamed "$DIR_SEMI")" \
    "$(line "$OUT" 2)"

# launcher-08
run_launcher EXOSUIT_WORKTREE_TABS=0 -- "$DIR_SEMI" "$DIR_UTF"
test_case "launcher-08 unsafe branches (a;b, résumé) -> one unsafe note each on stderr, launched unnamed" \
    "1:1:2:0:0" \
    "$(count "$ERR" "note: branch 'a;b' has characters unsafe for a session name — session left unnamed"):$(count "$ERR" "note: branch 'résumé' has characters unsafe for a session name — session left unnamed"):$(nlines "$ERR"):$(count "$OUT" '--name'):$(nlines "$OSA_LOG")"

# launcher-09
run_launcher EXOSUIT_WORKTREE_TABS=0 "LC_ALL=$UTF8_LOCALE" -- "$DIR_UTF"
test_case "launcher-09 LC_ALL=C allowlist rejects a non-ASCII branch under a UTF-8 locale ($UTF8_LOCALE)" \
    "1:  $(cmd_unnamed "$DIR_UTF")" \
    "$(count "$ERR" "unsafe for a session name"):$(line "$OUT" 2)"

# launcher-10
run_launcher EXOSUIT_WORKTREE_TABS=0 "EXOSUIT_WORKTREE_LAUNCH_CMD=claude --model x" -- "$DIR_A"
test_case "launcher-10 EXOSUIT_WORKTREE_LAUNCH_CMD='claude --model x' -> prefix kept, --name and prompt appended" \
    "  cd '$DIR_A' && claude --model x --name 'sprint-x-a' -- '/parallel-work hello'" \
    "$(line "$OUT" 2)"

# launcher-11
run_launcher EXOSUIT_WORKTREE_TABS=0 "CLAUDE_CONFIG_DIR=/Users/x/it's cap" -- "$DIR_A"
test_case "launcher-11 CLAUDE_CONFIG_DIR set -> CLAUDE_CONFIG_DIR='<v>' prefix in the command, quoted through q()" \
    "  cd '$DIR_A' && CLAUDE_CONFIG_DIR='/Users/x/it'\\''s cap' claude --name 'sprint-x-a' -- '/parallel-work hello'" \
    "$(line "$OUT" 2)"

# launcher-12
run_launcher EXOSUIT_WORKTREE_TABS=0 -- "$DIR_A"
test_case "launcher-12 CLAUDE_CONFIG_DIR unset -> no prefix" \
    "false" \
    "$(has "$OUT" 'CLAUDE_CONFIG_DIR')"

# launcher-13
BYPASS_L1="note: the launch command bypasses permissions; unless THIS session bypasses too, every HELLO/MERGED"
BYPASS_L2="      from the streams is held here for approval (and BYE is held there) — same class on both sides, or expect one dialog per message"
run_launcher EXOSUIT_WORKTREE_TABS=0 "EXOSUIT_WORKTREE_LAUNCH_CMD=claude --dangerously-skip-permissions" -- "$DIR_A" "$DIR_B"
test_case "launcher-13 bypass base command (--dangerously-skip-permissions) -> permission-class note once on stderr" \
    "1:1:2" \
    "$(count "$ERR" "$BYPASS_L1"):$(count "$ERR" "$BYPASS_L2"):$(nlines "$ERR")"

# launcher-14
run_launcher EXOSUIT_WORKTREE_TABS=0 "EXOSUIT_WORKTREE_LAUNCH_CMD=claude --permission-mode bypassPermissions" -- "$DIR_A"
R14A=$(count "$ERR" "$BYPASS_L1")
run_launcher EXOSUIT_WORKTREE_TABS=0 "EXOSUIT_WORKTREE_LAUNCH_CMD=claude --permission-mode=bypassPermissions" -- "$DIR_A"
R14B=$(count "$ERR" "$BYPASS_L1")
test_case "launcher-14 --permission-mode bypassPermissions and --permission-mode=bypassPermissions -> note" \
    "1:1" \
    "$R14A:$R14B"

# launcher-15
run_launcher EXOSUIT_WORKTREE_TABS=0 -- "$DIR_A"
test_case "launcher-15 plain claude -> no note" \
    "0:0" \
    "$(count "$ERR" "bypasses permissions"):$(nlines "$ERR")"

# launcher-16 (a permission flag fragment inside an --allowedTools value, without a bypass value)
run_launcher EXOSUIT_WORKTREE_TABS=0 "EXOSUIT_WORKTREE_LAUNCH_CMD=claude --allowedTools 'Bash(claude --permission-mode:*)'" -- "$DIR_A"
test_case "launcher-16 the flag inside an --allowedTools value -> no note" \
    "0:  cd '$DIR_A' && claude --allowedTools 'Bash(claude --permission-mode:*)' --name 'sprint-x-a' -- '/parallel-work hello'" \
    "$(count "$ERR" "bypasses permissions"):$(line "$OUT" 2)"

# launcher-17
run_launcher EXOSUIT_WORKTREE_TABS=0 -- "$DIR_HOSTILE"
test_case "launcher-17 apostrophe, double quote and backslash in the path survive q()" \
    "0:  $(cmd_named "$DIR_HOSTILE" feat/q2):true" \
    "$RC:$(line "$OUT" 2):$(has "$OUT" "it'\\''s \"q\" \\ #2' && claude")"

# launcher-18
run_launcher STUB_UNAME=Darwin -- "$DIR_SEMI"
test_case "launcher-18 command computed once per dir (unsafe note appears once on the live path; osascript got the same command)" \
    "0:1:1:  opened  $DIR_SEMI  ->  $(cmd_unnamed "$DIR_SEMI"):1" \
    "$RC:$(count "$ERR" "unsafe for a session name"):$(osa_calls):$(line "$OUT" 2):$(count "$OSA_LOG" "do script \"$(cmd_unnamed "$DIR_SEMI")\"")"

# launcher-19
run_launcher -- "$DIR_A" "$DIR_B"
test_case "launcher-19 unknown platform -> Couldn't auto-open terminals on this terminal (Plan9 / unknown)., exit 1" \
    "1:Couldn't auto-open terminals on this terminal (Plan9 / unknown).:Open a terminal per worktree and run::  $(cmd_named "$DIR_A" sprint-x-a):  $(cmd_named "$DIR_B" sprint-x-b):4:0:0" \
    "$RC:$(line "$OUT" 1):$(line "$OUT" 2):$(line "$OUT" 3):$(line "$OUT" 4):$(nlines "$OUT"):$(osa_calls):$(nlines "$WT_LOG")"

# launcher-20
run_launcher STUB_UNAME=Darwin -- "$DIR_MISSING"
test_case "launcher-20 missing dir -> refused without calling any opener, exit 1" \
    "1:0:note: $DIR_MISSING is not a directory — nothing started:Couldn't open 1 of 1 terminal(s) on this terminal (Darwin).:  $(cmd_unnamed "$DIR_MISSING")" \
    "$RC:$(osa_calls):$(line "$ERR" 1):$(line "$OUT" 1):$(line "$OUT" 3)"

# launcher-21 (addition: safety evidence)
test_case "launcher-21 the launcher never invokes claude itself (stub log empty so far)" \
    "0" \
    "$(nlines "$CLAUDE_LOG")"

# launcher-22 (addition: no-op byte identity)
run_launcher EXOSUIT_WORKTREE_TABS=0 -- "$DIR_A" "$DIR_B"
OUT_FIRST="$OUT"
run_launcher EXOSUIT_WORKTREE_TABS=0 -- "$DIR_A" "$DIR_B"
test_case "launcher-22 no-op byte identity (EXOSUIT_WORKTREE_TABS=0 twice)" \
    "true" \
    "$(if cmp -s "$OUT_FIRST" "$OUT"; then echo true; else echo false; fi)"

# launcher-23 (addition: help)
run_launcher -- -h
test_case "launcher-23 -h prints the usage block naming every stdout/stderr prefix" \
    "0:Usage: open-worktree-terminals.sh <dir> [<dir> ...]:true:true:true:true:true:false" \
    "$RC:$(line "$OUT" 1):$(has "$OUT" 'Opened <n> of <N> terminal(s):'):$(has "$OUT" "Couldn't open <k> of <N>"):$(has "$OUT" 'Open a terminal per worktree and run:'):$(has "$OUT" 'note: Terminal.app did not open a window'):$(has "$OUT" 'usage: open-worktree-terminals.sh'):$(has "$OUT" 'set -uo')"

# ==============================================================================
echo ""
echo "  -- terminal --"

# terminal-01 / 02 / 03 / 04 / 06 / 07 / 18
run_launcher STUB_UNAME=Darwin -- "$DIR_A" "$DIR_B"
test_case "terminal-01 exactly one osascript call per dir" \
    "2" \
    "$(osa_calls)"

test_case "terminal-02 script text is tell application \"Terminal\" + untargeted do script + end tell" \
    "tell application \"Terminal\":  do script \"$(cmd_named "$DIR_A" sprint-x-a)\":end tell:8" \
    "$(line "$OSA_LOG" 2):$(line "$OSA_LOG" 3):$(line "$OSA_LOG" 4):$(nlines "$OSA_LOG")"

FORBIDDEN=0
for word in 'activate' 'keystroke' 'System Events' 'front window' 'selected tab' 'count of' 'busy of' 'delay' '" in '; do
    [ "$(has "$OSA_LOG" "$word")" = "false" ] || FORBIDDEN=$((FORBIDDEN + 1))
done
test_case "terminal-03 no activate, keystroke, System Events, front window, selected tab, count of, busy of, delay or targeted do script" \
    "0" \
    "$FORBIDDEN"

test_case "terminal-04 --name '<branch>' inside the AppleScript string" \
    "1:1" \
    "$(count "$OSA_LOG" "--name 'sprint-x-a'"):$(count "$OSA_LOG" "--name 'sprint-x-b'")"

test_case "terminal-06 Opened 2 of 2 terminal(s): and two opened lines" \
    "Opened 2 of 2 terminal(s)::  opened  $DIR_A  ->  $(cmd_named "$DIR_A" sprint-x-a):  opened  $DIR_B  ->  $(cmd_named "$DIR_B" sprint-x-b):3" \
    "$(line "$OUT" 1):$(line "$OUT" 2):$(line "$OUT" 3):$(nlines "$OUT")"

test_case "terminal-07 exit 0 when all opened" \
    "0" \
    "$RC"

test_case "terminal-18 TERM_PROGRAM unset -> focus note names (unknown terminal)" \
    "1:1" \
    "$(count "$ERR" "note: the stream windows opened in Terminal.app behind your current app (unknown terminal) — the launcher does not steal focus."):$(nlines "$ERR")"

# terminal-05: the literal AppleScript string for the hostile path, pinned by hand:
#   shell layer   cd '<...>/it'\''s "q" \ #2' && claude --name 'feat/q2' -- '/parallel-work hello'
#   AppleScript   do script "cd '<...>/it'\\''s \"q\" \\ #2' && claude --name 'feat/q2' -- '/parallel-work hello'"
PIN="it'\\\\''s \\\"q\\\" \\\\ #2' && claude --name 'feat/q2' -- '/parallel-work hello'\""
run_launcher STUB_UNAME=Darwin -- "$DIR_HOSTILE"
test_case "terminal-05 hostile path it's \"q\" \\ #2 survives both quoting layers (literal pinned)" \
    "0:1:1:  opened  $DIR_HOSTILE  ->  $(cmd_named "$DIR_HOSTILE" feat/q2)" \
    "$RC:$(osa_calls):$(count "$OSA_LOG" "$PIN"):$(line "$OUT" 2)"

# terminal-08 / 09
OSA_TEXT_RAW=$'\033[1mNot authorized\033[0m to send Apple events\r\n to Terminal.\007 (-1743)\205'
run_launcher STUB_UNAME=Darwin "OSA_FAIL_MATCH=proj-b'" "OSA_FAIL_TEXT=$OSA_TEXT_RAW" -- "$DIR_A" "$DIR_B"
test_case "terminal-08 refusal of dir 2 -> exit 1, dir 1 opened, dir 2 under Couldn't open 1 of 2 with its hint" \
    "1:Opened 1 of 2 terminal(s)::  opened  $DIR_A  ->  $(cmd_named "$DIR_A" sprint-x-a):Couldn't open 1 of 2 terminal(s) on this terminal (Darwin).:Open a terminal per worktree and run::  $(cmd_named "$DIR_B" sprint-x-b):5" \
    "$RC:$(line "$OUT" 1):$(line "$OUT" 2):$(line "$OUT" 3):$(line "$OUT" 4):$(line "$OUT" 5):$(nlines "$OUT")"

# The injected bytes are ESC (\033), CR, BEL and the C1 byte \205; the launcher's
# own em dash is UTF-8 (\342\200\224), so only the injected bytes are checked.
STRIPPED="$WORK/err-stripped"
LC_ALL=C tr -d '\000-\011\013-\037\177\205' < "$ERR" > "$STRIPPED"
test_case "terminal-09 refusal reason on stderr, one line, Not authorized ... (-1743) kept, ESC/CR/BEL/C1 bytes stripped" \
    "1:1:true" \
    "$(count "$ERR" "note: Terminal.app did not open a window for $DIR_B — nothing started (Not authorized to send Apple events to Terminal. (-1743))"):$(count "$ERR" "note: Terminal.app did not open"):$(if cmp -s "$ERR" "$STRIPPED"; then echo true; else echo false; fi)"

# terminal-10
run_launcher STUB_UNAME=Darwin OSA_SILENT_FAIL=1 -- "$DIR_A"
test_case "terminal-10 empty-stderr refusal -> (no detail from osascript)" \
    "1:1" \
    "$RC:$(count "$ERR" "note: Terminal.app did not open a window for $DIR_A — nothing started (no detail from osascript)")"

# terminal-11
run_launcher STUB_UNAME=Darwin "OSA_FAIL_MATCH=proj-a'" "OSA_FAIL_TEXT=refused" -- "$DIR_A" "$DIR_B"
test_case "terminal-11 refused first dir -> second dir still attempted" \
    "1:2:Opened 1 of 2 terminal(s)::  opened  $DIR_B  ->  $(cmd_named "$DIR_B" sprint-x-b)" \
    "$RC:$(osa_calls):$(line "$OUT" 1):$(line "$OUT" 2)"

# terminal-12 .. 15
TABS_L1="note: macOS 'Prefer tabs when opening documents' is set to Always, so the"
TABS_L2="      streams opened as TABS of the frontmost Terminal window, not as windows."
run_launcher STUB_UNAME=Darwin STUB_TABBING_GLOBAL=always -- "$DIR_A" "$DIR_B"
test_case "terminal-12 Prefer-tabs global always -> note once" \
    "0:1:1" \
    "$RC:$(count "$ERR" "$TABS_L1"):$(count "$ERR" "$TABS_L2")"

run_launcher STUB_UNAME=Darwin STUB_TABBING_APP=always -- "$DIR_A"
test_case "terminal-13 per-app always -> note" \
    "1" \
    "$(count "$ERR" "$TABS_L1")"

run_launcher STUB_UNAME=Darwin STUB_TABBING_APP=manual STUB_TABBING_GLOBAL=always -- "$DIR_A"
test_case "terminal-14 per-app manual outranks global always -> no note" \
    "0:0" \
    "$RC:$(count "$ERR" "Prefer tabs")"

run_launcher STUB_UNAME=Darwin STUB_TABBING_GLOBAL=always OSA_SILENT_FAIL=1 -- "$DIR_A"
test_case "terminal-15 always but nothing opened -> no note" \
    "1:0" \
    "$RC:$(count "$ERR" "Prefer tabs")"

# terminal-16 / 17 / 19
run_launcher STUB_UNAME=Darwin TERM_PROGRAM=vscode -- "$DIR_A"
test_case "terminal-16 TERM_PROGRAM=vscode -> behind your current app (vscode)" \
    "1:1" \
    "$(count "$ERR" "note: the stream windows opened in Terminal.app behind your current app (vscode) — the launcher does not steal focus."):$(nlines "$ERR")"

run_launcher STUB_UNAME=Darwin TERM_PROGRAM=vscode OSA_SILENT_FAIL=1 -- "$DIR_A"
test_case "terminal-17 vscode but nothing opened -> no focus note" \
    "0" \
    "$(count "$ERR" "behind your current app")"

run_launcher STUB_UNAME=Darwin TERM_PROGRAM=Apple_Terminal -- "$DIR_A"
test_case "terminal-19 TERM_PROGRAM=Apple_Terminal -> no focus note" \
    "0:0:0" \
    "$RC:$(count "$ERR" "behind your current app"):$(nlines "$ERR")"

# terminal-20
run_launcher STUB_UNAME=Darwin TERM_PROGRAM=iTerm.app -- "$DIR_A"
test_case "terminal-20 TERM_PROGRAM=iTerm.app -> create tab with default profile, no Terminal.app note" \
    "0:1:1:0:0:0" \
    "$RC:$(osa_calls):$(count "$OSA_LOG" "create tab with default profile"):$(count "$OSA_LOG" 'tell application "Terminal"'):$(count "$ERR" "Terminal.app"):$(nlines "$ERR")"

# terminal-21
OSA_LITERALS=$(count "$LAUNCHER" "/usr/bin/osascript")
OSA_LITERAL_LINE=$(LC_ALL=C grep -F -e "/usr/bin/osascript" -- "$LAUNCHER")
test_case "terminal-21 the only /usr/bin/osascript literal is the knob default" \
    "1:true" \
    "$OSA_LITERALS:$(str_has "$OSA_LITERAL_LINE" '${EXOSUIT_WORKTREE_OSASCRIPT:-/usr/bin/osascript}')"

# ==============================================================================
echo ""
echo "  -- windows --"

winpath() {      # winpath <posix path> -> what the cygpath stub answers for -w
    printf 'C:%s' "$(printf '%s' "$1" | LC_ALL=C tr '/' '\\')"
}
CMD_A=$(cmd_named "$DIR_A" sprint-x-a)
WBASH=$(winpath "$BASH")
WDIR_A=$(winpath "$DIR_A")

# windows-01
run_launcher STUB_UNAME=MINGW64_NT -- "$DIR_A"
test_case "windows-01 STUB_UNAME=MINGW64_NT -> wt.exe -w 0 nt -d <cygpath -w dir> <cygpath -w bash> -lc \"<cmd>\\; exec bash\"" \
    "0:wt.exe [-w] [0] [nt] [-d] [$WDIR_A] [$WBASH] [-lc] [$CMD_A\\; exec bash]:1:cygpath [-w] [$DIR_A]:cygpath [-w] [$BASH]" \
    "$RC:$(wt_line wt.exe 1):$(count "$WT_LOG" "wt.exe "):$(wt_line cygpath 1):$(wt_line cygpath 2)"

# windows-02
run_launcher STUB_UNAME=MINGW64_NT "EXOSUIT_WORKTREE_FIRST_PROMPT=/parallel-work hello; echo hi" -- "$DIR_A"
W02=$(wt_line wt.exe 1)
W02_BODY=${W02##*\[-lc\] \[}
W02_SEMI=$(printf '%s' "$W02_BODY" | LC_ALL=C tr -cd ';' | wc -c | LC_ALL=C tr -d ' ')
W02_ESC=$(printf '%s' "$W02_BODY" | LC_ALL=C grep -o '\\;' | wc -l | LC_ALL=C tr -d ' ')
test_case "windows-02 ; in the command is escaped \\;" \
    "2:2:true" \
    "$W02_SEMI:$W02_ESC:$(str_has "$W02_BODY" "hello\\; echo hi'\\; exec bash]")"

# windows-03
run_launcher STUB_UNAME=MINGW64_NT "WT_FAIL_MATCH=[-w] [0]" -- "$DIR_A"
test_case "windows-03 -w 0 failure -> plain nt fallback recorded" \
    "0:2:wt.exe [nt] [-d] [$WDIR_A] [$WBASH] [-lc] [$CMD_A\\; exec bash]:Opened 1 of 1 terminal(s):" \
    "$RC:$(count "$WT_LOG" "wt.exe "):$(wt_line wt.exe 2):$(line "$OUT" 1)"

# windows-04
run_launcher STUB_UNAME=Linux "EXOSUIT_WORKTREE_PROC_VERSION=$PROC_WSL" -- "$DIR_A"
test_case "windows-04 Linux + proc-version with microsoft -> wt.exe -w 0 nt wsl.exe --cd <dir> -- bash -lc \"<cmd>\\; exec bash\"" \
    "0:wt.exe [-w] [0] [nt] [wsl.exe] [--cd] [$DIR_A] [--] [bash] [-lc] [$CMD_A\\; exec bash]:1:0" \
    "$RC:$(wt_line wt.exe 1):$(count "$WT_LOG" "wt.exe "):$(count "$WT_LOG" "cygpath ")"

# windows-05
run_launcher STUB_UNAME=Linux "EXOSUIT_WORKTREE_PROC_VERSION=$PROC_LINUX" -- "$DIR_A"
test_case "windows-05 Linux without microsoft + gnome-terminal -> --tab --working-directory=<dir> -- bash -lc \"<cmd>; exec bash\"" \
    "0:gnome-terminal [--tab] [--working-directory=$DIR_A] [--] [bash] [-lc] [$CMD_A; exec bash]:0" \
    "$RC:$(wt_line gnome-terminal 1):$(count "$WT_LOG" "wt.exe ")"

# windows-06
run_launcher STUB_UNAME=Linux "EXOSUIT_WORKTREE_PROC_VERSION=$PROC_LINUX" STUB_HIDE=gnome-terminal -- "$DIR_A"
test_case "windows-06 konsole arm argv" \
    "0:konsole [--new-tab] [--workdir] [$DIR_A] [-e] [bash] [-lc] [$CMD_A; exec bash]:0" \
    "$RC:$(wt_line konsole 1):$(count "$WT_LOG" "gnome-terminal ")"

# windows-07
run_launcher STUB_UNAME=Linux "EXOSUIT_WORKTREE_PROC_VERSION=$PROC_LINUX" STUB_HIDE=gnome-terminal,konsole -- "$DIR_A"
test_case "windows-07 Linux with neither -> no opener, exit 1, hints" \
    "1:Couldn't auto-open terminals on this terminal (Linux / unknown).:Open a terminal per worktree and run::  $CMD_A:0" \
    "$RC:$(line "$OUT" 1):$(line "$OUT" 2):$(line "$OUT" 3):$(nlines "$WT_LOG")"

# windows-08
run_launcher STUB_UNAME=MINGW64_NT WT_FAIL=1 -- "$DIR_A"
test_case "windows-08 WT_FAIL=1 -> exit 1 with hints" \
    "1:2:Couldn't open 1 of 1 terminal(s) on this terminal (MINGW64_NT).:Open a terminal per worktree and run::  $CMD_A" \
    "$RC:$(count "$WT_LOG" "wt.exe "):$(line "$OUT" 1):$(line "$OUT" 2):$(line "$OUT" 3)"

# windows-09
run_launcher STUB_UNAME=MINGW64_NT STUB_HIDE=wt.exe -- "$DIR_A"
test_case "windows-09 wt.exe absent on MINGW -> no opener, exit 1" \
    "1:Couldn't auto-open terminals on this terminal (MINGW64_NT / unknown).:0" \
    "$RC:$(line "$OUT" 1):$(nlines "$WT_LOG")"

# windows-10 (addition: safety evidence across the whole suite)
test_case "windows-10 the claude stub was never invoked by any run of this suite" \
    "0" \
    "$(nlines "$CLAUDE_LOG")"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
