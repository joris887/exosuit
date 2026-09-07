#!/usr/bin/env bash
# Usage: bash test-parallel-work-scripts.sh
#
# Test suite for the parallel-work skill scripts (worktree-status.sh,
# new-worktree.sh, stream-cleanup.sh, merge-up-run.sh) and the drift checks
# between the SKILL.md files and the scripts' "# Usage:" headers.
#
# Every script under test runs in an isolated fixture repository created at
# "<mktemp -d>/my repo #<n>/proj" (a space and a '#' in the path) under
# LC_ALL=C, with stdout and stderr captured to files, never through a pipe.
# A private PATH is built for every run: stubbed claude / uname / osascript /
# defaults (and argv recorders for wt.exe, wsl.exe, cygpath, gnome-terminal,
# konsole), plus thin wrappers around the real tools, so the suite never calls
# a real claude and can hide jq / python3 (STUB_HIDE=jq,python3) or claude
# itself (STUB_NOCLAUDE=1). No terminal is ever opened; no network is used.
# LC_ALL=C is also what hid a locale defect, so the cases that need another
# locale use run_lc and are SKIPped, never faked, when has_locale says no.
#
# Stdout:
#   Testing parallel-work scripts
#   =============================
#     -- <group> --                 (create status me gate session overlap mergeup
#                                    mergedown cleanup drift ref meta)
#     PASS: <group>-<NN> <description>
#     FAIL: <group>-<NN> <description> (expected '<x>', got '<y>')
#     SKIP: <group>-<NN> <description> (<reason>)     (never counted; when running as
#                                    root, without python3, or without a locale a case needs)
#   Results: <N> passed, <M> failed
# Exit codes:
#   0  every check passed
#   1  at least one check failed
set -uo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$(cd "$HOOKS_DIR/../skills" && pwd)"
SCRIPTS="$SKILLS_DIR/parallel-work/scripts"
STATUS="$SCRIPTS/worktree-status.sh"
NEWWT="$SCRIPTS/new-worktree.sh"
CLEANUP="$SCRIPTS/stream-cleanup.sh"
MERGEUP="$SCRIPTS/merge-up-run.sh"

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

skip_case() {
    echo "  SKIP: $1 ($2)"
}

echo "Testing parallel-work scripts"
echo "============================="

# --- Scratch space, fixed commit dates, root detection -----------------------
TMP_ROOT="$(cd "$(mktemp -d)" && pwd -P)"
ORIG_PWD="$(pwd)"
cleanup_tmp() {
    cd "$ORIG_PWD" || true
    chmod -R u+rwx "$TMP_ROOT" 2>/dev/null || true
    rm -rf "$TMP_ROOT"
}
trap cleanup_tmp EXIT

# Every fixture commit is dated 2020 so "%cr" is stable within a run and two
# runs of a read-only mode are byte-identical.
export GIT_AUTHOR_DATE="2020-01-01T00:00:00Z"
export GIT_COMMITTER_DATE="2020-01-01T00:00:00Z"
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE
export EXOSUIT_DISABLED_HOOKS="" EXOSUIT_HOOK_PROFILE=""
IS_ROOT=0
[ "$(id -u 2>/dev/null)" = 0 ] && IS_ROOT=1

OUT="$TMP_ROOT/out"
ERR="$TMP_ROOT/err"
REAL_GIT="$(command -v git)"

# --- Private PATH: tool wrappers and stubs ------------------------------------
TOOLS_DIR="$TMP_ROOT/tools"; JQ_DIR="$TMP_ROOT/tool-jq"; PY_DIR="$TMP_ROOT/tool-py"
STUB_BASE="$TMP_ROOT/stub"; STUB_CLAUDE="$TMP_ROOT/stub-claude"
STUB_WIN_DIR="$TMP_ROOT/stub-win"; STUB_LINUX_DIR="$TMP_ROOT/stub-linux"
mkdir -p "$TOOLS_DIR" "$JQ_DIR" "$PY_DIR" "$STUB_BASE" "$STUB_CLAUDE" "$STUB_WIN_DIR" "$STUB_LINUX_DIR"

# write_exec <path> <content>
write_exec() {
    printf '%s\n' "$2" > "$1"
    chmod +x "$1"
}

# wrap_tool <dir> <name> [<real path>]: a thin wrapper that execs the real tool
wrap_tool() {
    local real="${3:-}"
    [ -n "$real" ] || real="$(command -v "$2" 2>/dev/null)" || real=""
    case "$real" in /*) ;; *) return 0 ;; esac
    write_exec "$1/$2" "#!/bin/sh
exec '$real' \"\$@\""
}

for t in sh sed awk grep tr cut sort comm head tail cat mktemp rm mkdir rmdir dirname basename \
         wc env ls date cp chmod touch ln mv uniq find xargs diff cmp expr id sleep tee; do
    wrap_tool "$TOOLS_DIR" "$t"
done
wrap_tool "$TOOLS_DIR" bash "$BASH"
wrap_tool "$JQ_DIR" jq
wrap_tool "$PY_DIR" python3

# git: a recording wrapper. GIT_LOG appends every argv; GIT_TRAP_RUN names a
# shell snippet run once, just before the first git call whose argv contains
# GIT_TRAP_MATCH (a fixture hook for "something happened mid-run").
write_exec "$TOOLS_DIR/git" "#!/bin/sh
[ -n \"\${GIT_LOG:-}\" ] && printf '%s\\n' \"\$*\" >> \"\$GIT_LOG\"
if [ -n \"\${GIT_TRAP_RUN:-}\" ] && [ -f \"\$GIT_TRAP_RUN\" ]; then
  case \" \$* \" in *\"\${GIT_TRAP_MATCH:-@@never@@}\"*) t=\$GIT_TRAP_RUN; /bin/mv \"\$t\" \"\$t.done\" && /bin/sh \"\$t.done\" ;; esac
fi
exec '$REAL_GIT' \"\$@\""

# claude: the only claude the suite ever runs. STUB_AGENTS_CASE selects the
# answer to "agents --json"; CLAUDE_STUB_LOG records every invocation.
write_exec "$STUB_CLAUDE/claude" '#!/bin/sh
[ -n "${CLAUDE_STUB_LOG:-}" ] && printf '"'"'%s\n'"'"' "$*" >> "$CLAUDE_STUB_LOG"
case "${1:-} ${2:-}" in
  "agents --json") ;;
  *) echo "stub claude: unsupported arguments: $*" >&2; exit 2 ;;
esac
case "${STUB_AGENTS_CASE:-none}" in
  none)     printf '"'"'[]\n'"'"' ;;
  garbage)  printf '"'"'{"name":"x","cwd":\n'"'"' ;;
  nonarray) printf '"'"'{"name":"x","cwd":"/nowhere"}\n'"'"' ;;
  empty)    ;;
  spaces)   printf '"'"'   \n'"'"' ;;
  fail)     exit 1 ;;
  file)     /bin/cat "${STUB_AGENTS_JSON:?}" ;;
  *)        exit 1 ;;
esac
exit 0'

REAL_UNAME="$(command -v uname)"
write_exec "$STUB_BASE/uname" "#!/bin/sh
if [ -n \"\${STUB_UNAME:-}\" ]; then printf '%s\\n' \"\$STUB_UNAME\"; exit 0; fi
exec '$REAL_UNAME' \"\$@\""

write_exec "$STUB_BASE/osascript" '#!/bin/sh
in=$(/bin/cat)
if [ -n "${OSA_LOG:-}" ]; then { printf '"'"'%s\n'"'"' "$in"; printf '"'"'%s\n'"'"' "--- end of osascript call ---"; } >> "$OSA_LOG"; fi
[ "${OSA_SILENT_FAIL:-0}" = 1 ] && exit 1
if [ -n "${OSA_FAIL_MATCH:-}" ]; then
  case "$in" in *"$OSA_FAIL_MATCH"*) printf '"'"'%s\n'"'"' "${OSA_FAIL_TEXT:-}" >&2; exit 1 ;; esac
fi
exit 0'

write_exec "$STUB_BASE/defaults" '#!/bin/sh
case "$*" in
  "read com.apple.Terminal AppleWindowTabbingMode") v=${STUB_TABBING_APP:-} ;;
  "read -g AppleWindowTabbingMode") v=${STUB_TABBING_GLOBAL:-} ;;
  *) v="" ;;
esac
[ -n "$v" ] || exit 1
printf '"'"'%s\n'"'"' "$v"'

# argv recorders for the Windows / WSL / Linux launcher arms (used by the
# launcher, terminal and windows groups; added to PATH with STUB_WIN=1 /
# STUB_LINUX_TERMS=1)
for t in wt.exe wsl.exe; do
    write_exec "$STUB_WIN_DIR/$t" "#!/bin/sh
[ -n \"\${WT_LOG:-}\" ] && printf '%s: %s\\n' '$t' \"\$*\" >> \"\$WT_LOG\"
[ \"\${WT_FAIL:-0}\" = 1 ] && exit 1
exit 0"
done
write_exec "$STUB_WIN_DIR/cygpath" '#!/bin/sh
[ -n "${WT_LOG:-}" ] && printf '"'"'cygpath: %s\n'"'"' "$*" >> "$WT_LOG"
printf '"'"'W:%s\n'"'"' "${2:-}"'
for t in gnome-terminal konsole; do
    write_exec "$STUB_LINUX_DIR/$t" "#!/bin/sh
[ -n \"\${WT_LOG:-}\" ] && printf '%s: %s\\n' '$t' \"\$*\" >> \"\$WT_LOG\"
[ \"\${WT_FAIL:-0}\" = 1 ] && exit 1
exit 0"
done

export STUB_AGENTS_CASE=none
export STUB_AGENTS_JSON="$TMP_ROOT/agents.json"
export STUB_HIDE=""
export STUB_NOCLAUDE=0
export STUB_WIN=0
export STUB_LINUX_TERMS=0
printf '[]\n' > "$STUB_AGENTS_JSON"

run_path() {
    local p="$TOOLS_DIR"
    case ",$STUB_HIDE," in *,python3,*) ;; *) p="$PY_DIR:$p" ;; esac
    case ",$STUB_HIDE," in *,jq,*) ;; *) p="$JQ_DIR:$p" ;; esac
    [ "$STUB_LINUX_TERMS" = 1 ] && p="$STUB_LINUX_DIR:$p"
    [ "$STUB_WIN" = 1 ] && p="$STUB_WIN_DIR:$p"
    p="$STUB_BASE:$p"
    [ "$STUB_NOCLAUDE" = 1 ] || p="$STUB_CLAUDE:$p"
    printf '%s' "$p"
}

# run <dir> [VAR=value ...] <command ...>: run in <dir> on the private PATH under
# LC_ALL=C; stdout -> $OUT, stderr -> $ERR, exit code -> RC (never a pipe)
RC=0
run() {
    local dir="$1"; shift
    ( cd "$dir" 2>/dev/null && env PATH="$(run_path)" LC_ALL=C "$@" ) > "$OUT" 2> "$ERR" < /dev/null
    RC=$?
}
# run_lc <locale> <dir> <command ...>: the same under another LC_ALL
run_lc() {
    local lc="$1" dir="$2"; shift 2
    ( cd "$dir" 2>/dev/null && env PATH="$(run_path)" LC_ALL="$lc" "$@" ) > "$OUT" 2> "$ERR" < /dev/null
    RC=$?
}
# has_locale <name>: true when this machine can actually run under that LC_ALL.
# Every locale case below is skipped rather than faked when it answers false.
# No "grep -q": it would exit early, SIGPIPE "locale -a", and pipefail would
# then report the pipeline as a failure on the very locales that do exist.
has_locale() { LC_ALL=C locale -a 2>/dev/null | LC_ALL=C grep -x -F -- "$1" > /dev/null; }

# --- Assertion helpers ------------------------------------------------------------
out_has()   { if grep -F -q -- "$1" "$OUT" 2>/dev/null; then echo true; else echo false; fi; }
err_has()   { if grep -F -q -- "$1" "$ERR" 2>/dev/null; then echo true; else echo false; fi; }
out_line()  { if grep -F -x -q -- "$1" "$OUT" 2>/dev/null; then echo true; else echo false; fi; }
out_count() { grep -c -F -- "$1" "$OUT" 2>/dev/null || true; }
err_count() { grep -c -F -- "$1" "$ERR" 2>/dev/null || true; }
nlines()    { grep -c '' "$1" 2>/dev/null || true; }
out_empty() { if [ -s "$OUT" ]; then echo false; else echo true; fi; }
err_empty() { if [ -s "$ERR" ]; then echo false; else echo true; fi; }
last_line() { tail -n 1 "$1" 2>/dev/null; }
nth_line()  { sed -n "${1}p" "$OUT" 2>/dev/null; }
same()      { if cmp -s "$1" "$2"; then echo true; else echo false; fi; }
exists()    { if [ -e "$1" ]; then echo true; else echo false; fi; }
# has_sub <value> <needle> / has_pre <value> <prefix>: substring and prefix
# tests on a value already in hand. Functions, not inline "case" expressions:
# bash 3.2 cannot parse a "case" inside $( ), and every assertion below is one.
has_sub()   { case "$1" in *"$2"*) echo true; return ;; esac; echo false; }
has_pre()   { case "$1" in "$2"*) echo true; return ;; esac; echo false; }
# row_ok <prefix> [<middle>]: a stdout line starts with <prefix>, contains <middle>, ends " ago |"
row_ok() {
    local line
    while IFS= read -r line; do
        case "$line" in "$1"*"${2:-}"*" ago |") echo true; return ;; esac
    done < "$OUT"
    echo false
}
# porc_field <path> <n>: field n of the --porcelain row whose path is <path>
porc_field() { awk -F '\t' -v p="$1" -v n="$2" '$1 == p { print $n; exit }' "$OUT"; }
# cfg <dir> <key>
cfg() { git -C "$1" config "$2" 2>/dev/null || true; }
# tip <dir> <ref>
tip() { git -C "$1" rev-parse "$2" 2>/dev/null || true; }
# shq <s>: single-quote for /bin/sh
shq() { local s=$1 sq="'"; s=${s//$sq/$sq\\$sq$sq}; printf "'%s'" "$s"; }
# json_str <s>: a JSON string literal
json_str() { local s=$1; s=${s//\\/\\\\}; s=${s//\"/\\\"}; printf '"%s"' "$s"; }

# set_sessions [name cwd]...: claude agents --json answers this list (name first)
set_sessions() {
    local json="[" sep=""
    while [ $# -ge 2 ]; do
        json="$json$sep{\"name\":$(json_str "$1"),\"cwd\":$(json_str "$2")}"
        sep=","; shift 2
    done
    printf '%s]\n' "$json" > "$STUB_AGENTS_JSON"
    STUB_AGENTS_CASE=file
}
no_sessions() { STUB_AGENTS_CASE=none; }

# --- Fixture helpers -------------------------------------------------------------
FIX=""
WT=""
COMMIT_N=0

# write_mcp <root> <file>: an .mcp.json carrying the physical root, regex
# metacharacters and a sibling-shaped path
write_mcp() {
    printf '{"root":"%s","glob":"a.b*c[d]","data":"%s-data/x","again":"%s/sub"}\n' "$1" "$1" "$1" > "$2"
}

# make_fixture <n> [none|untracked|ignored|tracked]: sets FIX (physical path)
# main (one commit) -> sprint-x checked out; local files present and ignored
make_fixture() {
    local n="$1" mcp="${2:-none}" d root
    d="$TMP_ROOT/my repo #$n/proj"
    mkdir -p "$d"
    root="$(cd "$d" && pwd -P)"
    (
        cd "$root" || exit 1
        git init -q .
        git symbolic-ref HEAD refs/heads/main
        git config user.email "t@example.com"
        git config user.name "t"
        git config commit.gpgsign false
        printf '.env\n.claude/settings.local.json\nCLAUDE.local.md\ndocs/sessions/.activity-log.jsonl\n' > .gitignore
        [ "$mcp" = ignored ] && printf '.mcp.json\n' >> .gitignore
        mkdir -p docs/sessions .claude
        : > docs/sessions/.gitkeep
        echo seed > seed.txt
        git add -A
        git commit -qm init
        if [ "$mcp" != none ]; then
            write_mcp "$root" .mcp.json
            if [ "$mcp" = tracked ]; then git add -f .mcp.json; git commit -qm "mcp tracked"; fi
        fi
        echo 'A=1' > .env
        echo '{}' > .claude/settings.local.json
        echo local > CLAUDE.local.md
        git checkout -q -b sprint-x
    ) >/dev/null 2>&1
    FIX="$root"
}

# gitq <args>: a fixture mutation whose output is irrelevant
gitq() { git "$@" >/dev/null 2>&1 || true; }

# commit_in <dir> <file> <content> <msg>: one dated commit (distinct dates -> distinct shas)
commit_in() {
    local d
    COMMIT_N=$((COMMIT_N + 1))
    d="$(printf '2020-01-01T01:%02d:%02dZ' $((COMMIT_N / 60)) $((COMMIT_N % 60)))"
    printf '%s\n' "$3" > "$1/$2"
    git -C "$1" add -- "$2" >/dev/null 2>&1
    GIT_AUTHOR_DATE="$d" GIT_COMMITTER_DATE="$d" git -C "$1" commit -q -m "$4" >/dev/null 2>&1
}
# empty_commit_in <dir> <msg>
empty_commit_in() {
    local d
    COMMIT_N=$((COMMIT_N + 1))
    d="$(printf '2020-01-01T01:%02d:%02dZ' $((COMMIT_N / 60)) $((COMMIT_N % 60)))"
    GIT_AUTHOR_DATE="$d" GIT_COMMITTER_DATE="$d" git -C "$1" commit -q --allow-empty -m "$2" >/dev/null 2>&1
}

# mk_stream <from-dir> <branch> [args...]: new-worktree.sh under test; sets WT to
# the sibling path the script is expected to create
mk_stream() {
    local from="$1" b="$2"; shift 2
    run "$from" bash "$NEWWT" "$b" "$@"
    WT="$(dirname "$from")/proj-${b//\//-}"
}
sib() { printf '%s' "$(dirname "$FIX")/proj-$1"; }

##############################################################################
echo ""
echo "  -- create --"
##############################################################################
make_fixture 1 untracked
F1="$FIX"
mk_stream "$F1" s-a
WT_A="$WT"
test_case "create-01 Worktree ready: names the sibling dir under a space+# root" \
    "0:true:true" "$RC:$(out_has "Worktree ready: $WT_A"):$(exists "$WT_A")"
test_case "create-02 branch checked out in the new worktree" \
    "refs/heads/s-a" "$(git -C "$WT_A" symbolic-ref -q HEAD 2>/dev/null)"
test_case "create-03 recorded parent: line and key value" \
    "true:sprint-x" "$(out_has '   recorded parent: branch.s-a.exosuitParent = sprint-x'):$(cfg "$F1" branch.s-a.exosuitParent)"
test_case "create-05 .env, settings and CLAUDE.local.md copied" \
    "A=1:{}:local:3" "$(cat "$WT_A/.env" 2>/dev/null):$(cat "$WT_A/.claude/settings.local.json" 2>/dev/null):$(cat "$WT_A/CLAUDE.local.md" 2>/dev/null):$(out_count '   copied  ')"
test_case "create-12 .mcp.json untracked-not-ignored -> skip advisory, no file written" \
    "true:false" "$(out_has '   skip    .mcp.json (untracked and not gitignored in the main worktree — add it to .gitignore so streams get a rewritten copy, or copy it by hand)'):$(exists "$WT_A/.mcp.json")"

mk_stream "$F1" s-b --story E1-001
test_case "create-04 --story E1-001 recorded and echoed" \
    "true:E1-001" "$(out_has '   recorded story: branch.s-b.exosuitStory = E1-001'):$(cfg "$F1" branch.s-b.exosuitStory)"

# create-06 / 07: a tracked file also named in EXOSUIT_WORKTREE_COPY is never
# overwritten; an ignored extra is copied
make_fixture 2
F2="$FIX"
commit_in "$F2" notes.txt "tracked" "notes"
printf 'modified\n' > "$F2/notes.txt"
mkdir -p "$F2/extra"; printf 'one\n' > "$F2/extra/one.txt"
printf 'extra/\n' >> "$F2/.git/info/exclude"
run "$F2" EXOSUIT_WORKTREE_COPY="extra/one.txt:notes.txt" bash "$NEWWT" s-cp
WT_CP="$(sib s-cp)"
test_case "create-06 existing target file never overwritten" \
    "tracked:false" "$(cat "$WT_CP/notes.txt" 2>/dev/null):$(out_has 'copied  notes.txt')"
test_case "create-07 EXOSUIT_WORKTREE_COPY extras copied" \
    "one:true" "$(cat "$WT_CP/extra/one.txt" 2>/dev/null):$(out_has '   copied  extra/one.txt')"

make_fixture 3 tracked
F3="$FIX"
mk_stream "$F3" s-x
WT_X="$WT"
test_case "create-08 .mcp.json tracked on the branch -> skip line, no rewrite" \
    "true:true" "$(out_has '   skip    .mcp.json (tracked on s-x — left as-is)'):$(same "$F3/.mcp.json" "$WT_X/.mcp.json")"

make_fixture 4 ignored
F4="$FIX"
ln -s "$TMP_ROOT/my repo #4" "$TMP_ROOT/link4"
LOGICAL4="$TMP_ROOT/link4/proj"
printf '{"root":"%s","glob":"a.b*c[d]","data":"%s-data/x","again":"%s/sub","logical":"%s/y"}\n' \
    "$F4" "$F4" "$F4" "$LOGICAL4" > "$F4/.mcp.json"
run "$LOGICAL4" bash "$NEWWT" s-mc
WT_MC="$(sib s-mc)"
test_case "create-09 .mcp.json ignored -> wrote line, physical root rewritten literally with metachars intact" \
    "true:true:true" "$(out_has '   wrote   .mcp.json (absolute paths rewritten to worktree)'):$(grep -F -q -- "\"root\":\"$WT_MC\",\"glob\":\"a.b*c[d]\"" "$WT_MC/.mcp.json" 2>/dev/null && echo true || echo false):$(grep -F -q -- "\"again\":\"$WT_MC/sub\"" "$WT_MC/.mcp.json" 2>/dev/null && echo true || echo false)"
test_case "create-10 logical (symlinked) root spelling rewritten in the same pass, exactly once" \
    "true:0:1" "$(grep -F -q -- "\"logical\":\"$WT_MC/y\"" "$WT_MC/.mcp.json" 2>/dev/null && echo true || echo false):$(grep -c -F -- "$LOGICAL4" "$WT_MC/.mcp.json" 2>/dev/null || true):$(nlines "$WT_MC/.mcp.json")"
test_case "create-11 <root>-data/x untouched (boundary)" \
    "true" "$(grep -F -q -- "\"data\":\"$F4-data/x\"" "$WT_MC/.mcp.json" 2>/dev/null && echo true || echo false)"

# create-13..18 run in fixture 1, but sib() reads the global $FIX, which the
# .mcp.json cases above left pointing at fixture 4. Restore it or every
# "nothing was created" probe looks at a path that could never exist.
FIX="$F1"
gitq -C "$F1" checkout -q --detach
run "$F1" bash "$NEWWT" s-det
test_case "create-13 detached HEAD -> ERROR: HEAD is detached, exit 1, nothing created" \
    "1:true:false:false" "$RC:$(err_has 'ERROR: HEAD is detached — check out a branch first, or pass an explicit <base-ref>'):$(exists "$(sib s-det)"):$(git -C "$F1" show-ref --verify -q refs/heads/s-det 2>/dev/null && echo true || echo false)"
gitq -C "$F1" checkout -q sprint-x

run "$F1" bash "$NEWWT" s-m nope
test_case "create-14 missing base -> exit 1 before mutation" \
    "1:true:false:false" "$RC:$(err_has "ERROR: base branch 'nope' does not exist locally"):$(exists "$(sib s-m)"):$(git -C "$F1" show-ref --verify -q refs/heads/s-m 2>/dev/null && echo true || echo false)"

r15=""
for bad in '-x' 'a..b' 'a b'; do
    run "$F1" bash "$NEWWT" "$bad"
    r15="$r15$RC:$(err_has 'is not a valid branch name') "
done
test_case "create-15 invalid name (-x, a..b, a b) -> is not a valid branch name, exit 1" \
    "1:true 1:true 1:true " "$r15"

mkdir -p "$(sib s-dir)"
run "$F1" bash "$NEWWT" s-dir
test_case "create-16 existing dir -> exit 1" \
    "1:true" "$RC:$(err_has "ERROR: $(sib s-dir) already exists")"

gitq -C "$F1" branch s-br
run "$F1" bash "$NEWWT" s-br
test_case "create-17 existing branch -> exit 1" \
    "1:true" "$RC:$(err_has 'ERROR: branch s-br already exists')"

run "$WT_A" bash "$NEWWT" s-nested
C18_RC=$RC; C18_ERR=$(err_has 'ERROR: s-a is itself a stream of sprint-x — fan out from sprint-x, never from inside a stream')
run "$F1" bash "$NEWWT" s-nested2 s-a
test_case "create-18 base is itself a stream -> is itself a stream of, exit 1, nothing created" \
    "1:true:1:true:false:false" "$C18_RC:$C18_ERR:$RC:$(err_has 'is itself a stream of'):$(exists "$(sib s-nested)"):$(exists "$(sib s-nested2)")"

mk_stream "$F1" s-np1 s-a --no-parent
WT_NP1="$WT"
test_case "create-19 --no-parent off a stream base is allowed (no nested check)" \
    "0:true" "$RC:$(exists "$WT_NP1")"
test_case "create-20 --no-parent records nothing and prints no parent recorded" \
    "true::false" "$(out_has '   no parent recorded (--no-parent): a standalone worktree, not a stream'):$(cfg "$F1" branch.s-np1.exosuitParent):$(out_has 'recorded parent')"

mk_stream "$F1" s-np2 --no-parent --story E9-009
test_case "create-21 --story dropped under --no-parent" \
    "0:false:" "$RC:$(out_has 'recorded story'):$(cfg "$F1" branch.s-np2.exosuitStory)"

run "$F1" bash "$NEWWT" s-eq --story=x
test_case "create-22 --story=x -> unknown option, exit 2" \
    "2:true" "$RC:$(err_has 'ERROR: unknown option --story=x')"

run "$F1" bash "$NEWWT" s-nv --story
test_case "create-23 --story without value -> exit 2" \
    "2:true" "$RC:$(err_has 'ERROR: --story needs a value')"

run "$F1" bash "$NEWWT" s-cc --story "$(printf 'E1\t001')"
test_case "create-24 control chars in --story -> exit 2" \
    "2:true" "$RC:$(err_has 'ERROR: --story must not contain control characters')"

run "$F1" bash "$NEWWT"
test_case "create-25 missing <new-branch> -> usage, exit 2" \
    "2:true" "$RC:$(err_has 'usage: new-worktree.sh <new-branch> [<base-ref>] [<worktree-dir>] [--story <id>] [--no-parent]')"

# create-26: a tag named exactly like the base points elsewhere; the full ref wins
empty_commit_in "$F1" "sprint moves"
gitq -C "$F1" tag sprint-x refs/heads/main
mk_stream "$F1" s-tag
WT_TAG="$WT"
test_case "create-26 a tag named like the base does not confuse identity (full ref)" \
    "0:true:false:true" "$RC:$([ "$(tip "$WT_TAG" HEAD)" = "$(tip "$F1" refs/heads/sprint-x)" ] && echo true || echo false):$([ "$(tip "$WT_TAG" HEAD)" = "$(tip "$F1" refs/heads/main)" ] && echo true || echo false):$(out_has '   recorded parent: branch.s-tag.exosuitParent = sprint-x')"
gitq -C "$F1" tag -d sprint-x

run "$F1" bash "$NEWWT" -h
test_case "create-27 -h prints the usage block" \
    "0:true:true:true" "$RC:$(out_has 'Usage: new-worktree.sh <new-branch> [<base-ref>] [<worktree-dir>] [--story <id>] [--no-parent]'):$(out_has 'Worktree ready: <dir>'):$(out_has 'ERROR: <base> is itself a stream of <P>')"
cp "$OUT" "$TMP_ROOT/c28a"
run "$F1" bash "$NEWWT" -h
cp "$OUT" "$TMP_ROOT/c28b"
run "$F1" bash "$NEWWT" s-nb nope
cp "$OUT" "$TMP_ROOT/c28c"; cp "$ERR" "$TMP_ROOT/c28e"
run "$F1" bash "$NEWWT" s-nb nope
test_case "create-28 no-op byte identity (-h twice; a refusal twice)" \
    "true:true:true" "$(same "$TMP_ROOT/c28a" "$TMP_ROOT/c28b"):$(same "$TMP_ROOT/c28c" "$OUT"):$(same "$TMP_ROOT/c28e" "$ERR")"

# create-29..32: a symlink committed on the base branch must never redirect a
# copy out of the new worktree.
# link_branch <fixture> <branch> <rel> <target>: a branch off sprint-x whose
# tree carries a 120000 (symlink) entry at <rel>. Built through a private
# GIT_INDEX_FILE, so the fixture's own index and working tree are untouched.
link_branch() {
    local f="$1" br="$2" rel="$3" target="$4" blob tree c
    blob="$(printf '%s' "$target" | git -C "$f" hash-object -w --stdin 2>/dev/null)"
    (
        export GIT_INDEX_FILE="$TMP_ROOT/idx-$br"
        git -C "$f" read-tree refs/heads/sprint-x
        git -C "$f" update-index --add --cacheinfo "120000,$blob,$rel"
        tree="$(git -C "$f" write-tree)"
        c="$(git -C "$f" commit-tree "$tree" -p refs/heads/sprint-x -m "link $rel")"
        git -C "$f" update-ref "refs/heads/$br" "$c"
    ) >/dev/null 2>&1
    rm -f "$TMP_ROOT/idx-$br"
}

make_fixture 110
F110="$FIX"
VICT1="$TMP_ROOT/victim"
mkdir -p "$VICT1"
link_branch "$F110" evil1 .claude/settings.local.json "$VICT1/global-settings.json"
mk_stream "$F110" s-x evil1
test_case "create-29 dangling leaf symlink at the destination is never written through" \
    "0:false:false" "$RC:$(out_has 'copied  .claude/settings.local.json'):$(exists "$VICT1/global-settings.json")"

VICT2="$TMP_ROOT/victim2"
mkdir -p "$VICT2"
printf 'keep me\n' > "$VICT2/keepme.txt"
cp "$VICT2/keepme.txt" "$TMP_ROOT/keepme.orig"
link_branch "$F110" evil2 .claude "$VICT2"
mk_stream "$F110" s-y evil2
test_case "create-30 symlinked parent directory -> skip line, nothing outside the worktree" \
    "0:true:false:true" "$RC:$(out_has '   skip    .claude/settings.local.json (destination leaves the worktree via a symlink)'):$(exists "$VICT2/settings.local.json"):$(same "$TMP_ROOT/keepme.orig" "$VICT2/keepme.txt")"

VICT3="$TMP_ROOT/victim3"
mkdir -p "$VICT3"
mkdir -p "$F110/cfg/b"; printf 'mine\n' > "$F110/cfg/b/c"
printf 'cfg/\n' >> "$F110/.git/info/exclude"
link_branch "$F110" evil3 cfg "$VICT3"
run "$F110" EXOSUIT_WORKTREE_COPY="cfg/b/c" bash "$NEWWT" s-z evil3
test_case "create-31 EXOSUIT_WORKTREE_COPY through a symlinked grandparent is skipped" \
    "0:true:false" "$RC:$(out_has '   skip    cfg/b/c (destination leaves the worktree via a symlink)'):$(exists "$VICT3/b/c")"

# create-32: the same shape, but the link resolves back inside the worktree —
# the guard against over-refusing a benign symlink.
make_fixture 111
F111="$FIX"
mkdir -p "$F111/innercfg"; : > "$F111/innercfg/.keep"
gitq -C "$F111" add -f -- innercfg/.keep
gitq -C "$F111" commit -q -m innercfg
link_branch "$F111" inner cfg innercfg
mkdir -p "$F111/cfg"; printf 'local bytes\n' > "$F111/cfg/local"
printf 'cfg/\n' >> "$F111/.git/info/exclude"
run "$F111" EXOSUIT_WORKTREE_COPY="cfg/local" bash "$NEWWT" s-in inner
WT_IN="$(sib s-in)"
test_case "create-32 a symlink resolving inside the worktree still copies" \
    "0:true:true:local bytes" "$RC:$(out_has '   copied  cfg/local'):$(exists "$WT_IN/innercfg/local"):$(cat "$WT_IN/innercfg/local" 2>/dev/null)"

# create-33 / 34: a control character in <worktree-dir> forges "key: value"
# lines in every --me block that later names this worktree.
make_fixture 112
F112="$FIX"
PAR112="$(dirname "$F112")"
run "$F112" bash "$NEWWT" s-x main "$(printf '%s/wt-A\nparent: main\nparent_dir: %s' "$PAR112" "$F112")"
test_case "create-33 newline in <worktree-dir> -> exit 2, nothing touched" \
    "2:true:0:false:" "$RC:$(err_has 'ERROR: <worktree-dir> must not contain control characters'):$(find "$PAR112" -maxdepth 1 -name 'wt-A*' 2>/dev/null | grep -c '' || true):$(git -C "$F112" show-ref --verify -q refs/heads/s-x 2>/dev/null && echo true || echo false):$(cfg "$F112" branch.s-x.exosuitParent)"

run "$F112" bash "$NEWWT" s-x main "$(printf '%s/wt-A\tparent: main' "$PAR112")"
test_case "create-34 TAB in <worktree-dir> -> exit 2" \
    "2:true:0:false" "$RC:$(err_has 'ERROR: <worktree-dir> must not contain control characters'):$(find "$PAR112" -maxdepth 1 -name 'wt-A*' 2>/dev/null | grep -c '' || true):$(git -C "$F112" show-ref --verify -q refs/heads/s-x 2>/dev/null && echo true || echo false)"

##############################################################################
echo ""
echo "  -- status --"
##############################################################################
mkdir -p "$TMP_ROOT/notrepo"
run "$TMP_ROOT/notrepo" bash "$STATUS"
test_case "status-01 not a repo -> ERROR: not inside a git repository, exit 2, empty stdout" \
    "2:true:true" "$RC:$(err_has 'ERROR: not inside a git repository'):$(out_empty)"

make_fixture 10
F10="$FIX"
run "$F10" bash "$STATUS"
test_case "status-02 table header and (base) on the main worktree" \
    "## Worktree Status:| Path | Branch | Parent | Ahead/Behind parent | Story | Session | Tree | Last commit |:true:true" \
    "$(nth_line 1):$(nth_line 3):$(row_ok "| $F10 | sprint-x | - | (base) | - | - | clean | "):$(out_line "+ahead = not merged up yet · -behind = run /merge-down there · Session '-' = no claude session in that directory")"

gitq -C "$F10" checkout -q --detach
run "$F10" bash "$STATUS"
test_case "status-03 detached main worktree still (base)" \
    "true" "$(row_ok "| $F10 | (detached " ") | - | (base) | - | - | clean | ")"
gitq -C "$F10" checkout -q sprint-x

mk_stream "$F10" s-a
WT_A="$WT"
commit_in "$WT_A" a.txt "a" "stream a"
empty_commit_in "$F10" "parent moves"
run "$F10" bash "$STATUS"
test_case "status-04 +1/-1 against ITS parent" \
    "true" "$(row_ok "| $WT_A | s-a | sprint-x | +1/-1 | - | - | clean | ")"

mk_stream "$F10" s-np --no-parent
WT_NP="$WT"
run "$F10" bash "$STATUS"
test_case "status-05 parentless worktree row - / ? never +-/--" \
    "true:false:false" "$(row_ok "| $WT_NP | s-np | - | ? | - | - | clean | "):$(out_has '+-/--'):$(out_has '| +-')"

D_DET="$(sib det)"
gitq -C "$F10" worktree add --detach "$D_DET" sprint-x
run "$F10" bash "$STATUS"
test_case "status-06 detached linked worktree row" \
    "true" "$(row_ok "| $D_DET | (detached " ") | - | - | - | - | clean | ")"

printf 'u\n' > "$WT_A/untracked.txt"
run "$F10" bash "$STATUS"
test_case "status-07 DIRTY with an untracked file (table predicate)" \
    "true" "$(row_ok "| $WT_A | s-a | sprint-x | +1/-1 | - | - | DIRTY | ")"
rm -f "$WT_A/untracked.txt"

if [ "$IS_ROOT" = 1 ]; then
    skip_case "status-08 ? tree when git status fails in a worktree" "running as root: chmod 000 does not block reads"
else
    chmod 000 "$WT_NP"
    run "$F10" bash "$STATUS"
    test_case "status-08 ? tree when git status fails in a worktree (chmod 000 fixture)" \
        "0:true" "$RC:$(row_ok "| $WT_NP | s-np | - | ? | - | - | ? | ")"
    chmod 755 "$WT_NP"
fi

gitq -C "$F10" config branch.s-a.exosuitStory "$(printf 'E1\r\t-001')"
run "$F10" bash "$STATUS"
test_case "status-09 story with CR/TAB rendered on one line" \
    "true" "$(row_ok "| $WT_A | s-a | sprint-x | +1/-1 | E1-001 | - | clean | ")"
gitq -C "$F10" config --unset branch.s-a.exosuitStory

mk_stream "$F10" 's|p'
WT_SP="$WT"
run "$F10" bash "$STATUS"
S10_TABLE=$(row_ok "| $(dirname "$F10")/proj-s\\|p | s\\|p | sprint-x | +0/-0 | - | - | clean | ")
run "$F10" bash "$STATUS" --porcelain
test_case "status-10 | in a branch escaped in the table, intact in porcelain" \
    "true:true" "$S10_TABLE:$(out_has "$(printf '%s\ts|p\tsprint-x\t0\t0\t-\t-\tclean' "$WT_SP")")"

D_SEED="$(sib seed)"
gitq -C "$F10" branch seed.txt sprint-x
gitq -C "$F10" worktree add "$D_SEED" seed.txt
run "$F10" bash "$STATUS"
test_case "status-11 age_of with a branch named like a path in the cwd -> ... ago" \
    "true" "$(row_ok "| $D_SEED | seed.txt | - | ? | - | - | clean | ")"

run "$F10" bash "$STATUS" --porcelain
test_case "status-12 porcelain 8 TAB fields" \
    "0:0:$(git -C "$F10" worktree list --porcelain | grep -c '^worktree ')" \
    "$RC:$(awk -F '\t' 'NF != 8 { bad++ } END { print bad + 0 }' "$OUT"):$(nlines "$OUT")"
test_case "status-13 porcelain - for every empty field" \
    "true:true" "$(out_has "$(printf '%s\ts-np\t-\t-\t-\t-\t-\tclean' "$WT_NP")"):$(out_has "$(printf '%s\tsprint-x\t-\t-\t-\t-\t-\tclean' "$F10")")"
test_case "status-14 porcelain detached branch HEAD" \
    "HEAD:-" "$(porc_field "$D_DET" 2):$(porc_field "$D_DET" 3)"

run "$F10" bash "$STATUS" --bogus
test_case "status-15 unknown option -> exit 2" \
    "2:true:true" "$RC:$(err_has 'unknown option: --bogus'):$(out_empty)"
run "$F10" bash "$STATUS" --gate nope
test_case "status-16 bad gate name -> usage, exit 2" \
    "2:true:true" "$RC:$(err_has 'usage: --gate merge-up|merge-down|children|start'):$(out_empty)"

gitq -C "$F10" branch tmpbase sprint-x
mk_stream "$F10" s-orphan tmpbase
WT_OR="$WT"
gitq -C "$F10" branch -d tmpbase
run "$F10" bash "$STATUS"
test_case "status-17 deleted parent branch -> ? counts, no abort" \
    "0:true:true" "$RC:$(row_ok "| $WT_OR | s-orphan | tmpbase | ? | - | - | clean | "):$(out_has "+ahead = not merged up yet")"

cp "$OUT" "$TMP_ROOT/s18a"
run "$F10" bash "$STATUS"
test_case "status-18 no-op byte identity" "true" "$(same "$TMP_ROOT/s18a" "$OUT")"

##############################################################################
echo ""
echo "  -- me --"
##############################################################################
make_fixture 20
F20="$FIX"
mk_stream "$F20" s-a; WT_A="$WT"
mk_stream "$F20" s-b; WT_B="$WT"
mk_stream "$F20" s-d; WT_D="$WT"
gitq -C "$F20" branch tmpb sprint-x
mk_stream "$F20" s-c tmpb; WT_C="$WT"

run "$WT_A" bash "$STATUS" --me
test_case "me-01 13 keys in order inside a stream, exit 0" \
    "0:13:branch dir parent parent_dir ahead behind dirty parent_dirty parent_merge_in_progress remote coordinator peers story " \
    "$RC:$(nlines "$OUT"):$(sed 's/:.*//' "$OUT" | tr '\n' ' ')"
test_case "me-02 story: is the last line" "story: -" "$(last_line "$OUT")"
test_case "me-04 parent_dir: is the parent's worktree path" \
    "true:true:true" "$(out_line "parent_dir: $F20"):$(out_line "dir: $WT_A"):$(out_line 'parent: sprint-x')"

run "$F20" bash "$STATUS" --me
test_case "me-03 outside a stream -> 13 lines then not a stream: on stderr, exit 2" \
    "2:13:true:true" "$RC:$(nlines "$OUT"):$(err_has 'not a stream: branch sprint-x has no recorded parent (branch.sprint-x.exosuitParent)'):$(out_line 'parent: -')"

run "$WT_C" bash "$STATUS" --me
test_case "me-05 parent_dirty: - and parent_merge_in_progress: - when the parent is checked out nowhere" \
    "0:true:true:true" "$RC:$(out_line 'parent_dir: -'):$(out_line 'parent_dirty: -'):$(out_line 'parent_merge_in_progress: -')"

gitq -C "$F20" config branch.sprint-x.remote upstream
run "$WT_A" bash "$STATUS" --me
test_case "me-06 remote: from branch.<P>.remote" "true" "$(out_line 'remote: upstream')"
gitq -C "$F20" config --unset branch.sprint-x.remote
gitq -C "$F20" remote add zeta "$TMP_ROOT/nowhere-zeta"
gitq -C "$F20" remote add origin "$TMP_ROOT/nowhere-origin"
run "$WT_A" bash "$STATUS" --me
test_case "me-07 remote: falls back to origin" "true" "$(out_line 'remote: origin')"
gitq -C "$F20" remote remove origin
gitq -C "$F20" remote add alpha "$TMP_ROOT/nowhere-alpha"
run "$WT_A" bash "$STATUS" --me
test_case "me-08 remote: falls back to the first remote" "true" "$(out_line 'remote: alpha')"
gitq -C "$F20" remote remove alpha
gitq -C "$F20" remote remove zeta
run "$WT_A" bash "$STATUS" --me
test_case "me-09 remote: - without remotes" "true" "$(out_line 'remote: -')"

set_sessions co1 "$F20"
run "$WT_A" bash "$STATUS" --me
test_case "me-10 coordinator: from the parent worktree's session (stub)" \
    "true:true" "$(out_line 'coordinator: co1'):$(out_line 'peers: -')"
set_sessions a "$F20" b "$F20"
run "$WT_A" bash "$STATUS" --me
test_case "me-11 coordinator: a,b for two sessions in the parent dir" "true" "$(out_line 'coordinator: a,b')"
set_sessions co "$F20" me1 "$WT_A" pb "$WT_B" pd "$WT_D" pc "$WT_C"
run "$WT_A" bash "$STATUS" --me
test_case "me-12 peers: names sibling streams' sessions, space-separated" \
    "true:true" "$(out_line 'peers: pb pd'):$(out_line 'coordinator: co')"
set_sessions sub1 "$F20/docs/sessions"
run "$WT_A" bash "$STATUS" --me
test_case "me-13 subdirectory session belongs to its worktree (deepest root)" "true" "$(out_line 'coordinator: sub1')"

mk_stream "$F20" a; WT_PA="$WT"
mk_stream "$F20" ab; WT_PAB="$WT"
set_sessions x "$WT_PAB"
run "$F20" bash "$STATUS" --porcelain
test_case "me-14 prefix siblings (proj-a / proj-ab) never share a session" \
    "-:x" "$(porc_field "$WT_PA" 7):$(porc_field "$WT_PAB" 7)"

# me-15: the roster lists a worktree by a symlinked spelling; the session's cwd
# is physical; the join compares physical roots
ln -s "$TMP_ROOT/my repo #20" "$TMP_ROOT/link20"
mk_stream "$F20" s-sym; WT_SYM="$WT"
printf '%s\n' "$TMP_ROOT/link20/proj-s-sym/.git" > "$F20/.git/worktrees/proj-s-sym/gitdir"
set_sessions sym1 "$WT_SYM"
run "$F20" bash "$STATUS" --porcelain
M15_ROW=$(porc_field "$TMP_ROOT/link20/proj-s-sym" 7)
run "$WT_A" bash "$STATUS" --me
test_case "me-15 a session started via a symlinked base path still joins (physical roots)" \
    "sym1:true" "$M15_ROW:$(out_line 'peers: sym1')"
no_sessions

# me-16: a worktree whose directory name spells two extra key: lines. Built with
# git worktree add — new-worktree.sh refuses the path outright (create-33).
# CTRL_A is reused by gate-32 below.
make_fixture 21
F21="$FIX"
CTRL_A="$(printf '%s\nparent: main\nparent_dir: %s' "$(sib s-ctrl)" "$F21")"
gitq -C "$F21" worktree add -b s-ctrl "$CTRL_A" sprint-x
gitq -C "$F21" config branch.s-ctrl.exosuitParent sprint-x
run "$CTRL_A" bash "$STATUS" --me
test_case "me-16 a newline in the worktree path prints no block" \
    "2:true:1:true" "$RC:$(out_empty):$(nlines "$ERR"):$(err_has 'ERROR: worktree path contains a control character; unsupported')"

# me-17..me-20: free text out of config cannot forge a 14th line, and both cuts
# are byte cuts in every locale.
make_fixture 22
F22="$FIX"
mk_stream "$F22" s-a; WT_A="$WT"
gitq -C "$F22" config branch.s-a.exosuitParent "$(printf 'sprint-x\ncoordinator: attacker')"
run "$WT_A" bash "$STATUS" --me
test_case "me-17 a forged exosuitParent cannot inject a key line" \
    "13:1:true:false" "$(nlines "$OUT"):$(grep -c -E '^coordinator: ' "$OUT" || true):$(out_line 'parent: sprint-xcoordinator: attacker'):$(out_line 'coordinator: attacker')"
gitq -C "$F22" config branch.s-a.exosuitParent sprint-x

# remote_of is asked for the PARENT branch, so the forgery is recorded there
gitq -C "$F22" config branch.sprint-x.remote "$(printf 'origin\ncoordinator: attacker')"
run "$WT_A" bash "$STATUS" --me
test_case "me-18 a forged branch.<parent>.remote cannot inject a key line" \
    "13:1:true:false" "$(nlines "$OUT"):$(grep -c -E '^coordinator: ' "$OUT" || true):$(out_line 'remote: origincoordinator: attacker'):$(out_line 'coordinator: attacker')"
gitq -C "$F22" config --unset branch.sprint-x.remote

gitq -C "$F22" config branch.s-a.exosuitParent "$(LC_ALL=C awk 'BEGIN { while (i++ < 250) printf "x" }')"
run "$WT_A" bash "$STATUS" --me
M19="$(sed -n 's/^parent: //p' "$OUT" | head -1)"
test_case "me-19 the recorded parent is cut at 200 bytes" \
    "200" "$(printf '%s' "$M19" | LC_ALL=C wc -c | tr -d ' ')"
gitq -C "$F22" config branch.s-a.exosuitParent sprint-x

# 150 x U+00E9 is 150 characters and 300 bytes: "cut -c1-200" answered 200
# characters (300 bytes) in a UTF-8 locale and 200 bytes under the suite's
# LC_ALL=C, so the two runs disagreed. "cut -b1-200" answers 200 bytes in both.
gitq -C "$F22" config branch.s-a.exosuitStory "$(LC_ALL=C awk 'BEGIN { while (i++ < 150) printf "\303\251" }')"
run "$WT_A" bash "$STATUS" --me
M20C="$(printf '%s' "$(sed -n 's/^story: //p' "$OUT" | head -1)" | LC_ALL=C wc -c | tr -d ' ')"
if has_locale fr_FR.UTF-8; then
    run_lc fr_FR.UTF-8 "$WT_A" bash "$STATUS" --me
    test_case "me-20 the story is cut at 200 bytes, not 200 characters" \
        "200:200" "$M20C:$(printf '%s' "$(sed -n 's/^story: //p' "$OUT" | head -1)" | LC_ALL=C wc -c | tr -d ' ')"
else
    skip_case "me-20 the story is cut at 200 bytes, not 200 characters" "fr_FR.UTF-8 not installed"
fi
gitq -C "$F22" config --unset branch.s-a.exosuitStory

# me-21: exit 2 carries three states; parallel-work's Hello 1 routes on the
# output, not the code, so the two shapes it names must stay distinguishable.
run "$F20" bash "$STATUS" --me
M21A="$RC:$(nlines "$OUT"):$(grep -c -E '^[a-z_]+: ' "$OUT" || true):$(grep -c -E '^not a stream: ' "$ERR" || true)"
run "$TMP_ROOT/notrepo" bash "$STATUS" --me
M21B="$RC:$(nlines "$OUT"):$(err_has 'ERROR: not inside a git repository')"
PWSK="$SKILLS_DIR/parallel-work/SKILL.md"
test_case "me-21 --me distinguishes its three exit-2 shapes" \
    "2:13:13:1:2:0:true:true:true" \
    "$M21A:$M21B:$(grep -q -F -- '13 `key: value` lines' "$PWSK" && echo true || echo false):$(grep -q -F -- 'relay the stderr `ERROR:` line' "$PWSK" && echo true || echo false)"

##############################################################################
echo ""
echo "  -- gate --"
##############################################################################
make_fixture 30
F30="$FIX"
mk_stream "$F30" s-a; WT_A="$WT"

run "$WT_A" bash "$STATUS" --gate merge-up
test_case "gate-01 merge-up OK" "0:14:GATE merge-up: OK" "$RC:$(nlines "$OUT"):$(last_line "$OUT")"

gitq -C "$WT_A" checkout -q --detach
run "$WT_A" bash "$STATUS" --gate merge-up
test_case "gate-02 detached -> FAIL" \
    "1:true" "$RC:$(out_line 'GATE merge-up: FAIL — HEAD is detached — check out a branch')"
gitq -C "$WT_A" checkout -q s-a

run "$F30" bash "$STATUS" --gate merge-up
test_case "gate-03 no parent -> FAIL with the git config hint" \
    "1:true" "$RC:$(out_line 'GATE merge-up: FAIL — no recorded parent — this is not a stream (set one with: git config branch.sprint-x.exosuitParent <parent>)')"

gitq -C "$F30" branch tmpbase sprint-x
mk_stream "$F30" s-o tmpbase; WT_O="$WT"
gitq -C "$F30" branch -d tmpbase
run "$WT_O" bash "$STATUS" --gate merge-up
test_case "gate-04 parent missing locally -> FAIL" \
    "1:true" "$RC:$(out_line "GATE merge-up: FAIL — recorded parent 'tmpbase' does not exist locally")"

gitq -C "$F30" config branch.s-a.exosuitParent s-a
run "$WT_A" bash "$STATUS" --gate merge-up
test_case "gate-05 parent equals branch -> FAIL" \
    "1:true" "$RC:$(out_line 'GATE merge-up: FAIL — parent equals the current branch')"
gitq -C "$F30" config branch.s-a.exosuitParent sprint-x

printf 'changed\n' > "$WT_A/seed.txt"
run "$WT_A" bash "$STATUS" --gate merge-up
test_case "gate-06 dirty tracked stream -> FAIL" \
    "1:true" "$RC:$(out_line 'GATE merge-up: FAIL — current worktree has uncommitted tracked changes — commit or stash first (this merges committed work only)')"
gitq -C "$WT_A" restore seed.txt

printf 'u\n' > "$WT_A/u.txt"
run "$WT_A" bash "$STATUS" --gate merge-up
test_case "gate-07 untracked file in the stream does not FAIL (dirty_tracked_of)" \
    "0:GATE merge-up: OK" "$RC:$(last_line "$OUT")"
rm -f "$WT_A/u.txt"

if [ "$IS_ROOT" = 1 ]; then
    skip_case "gate-08 ? stream state -> FAIL cannot read this worktree's state" "running as root"
else
    IDX_A="$(git -C "$WT_A" rev-parse --git-path index)"
    chmod 000 "$IDX_A"
    run "$WT_A" bash "$STATUS" --gate merge-up
    test_case "gate-08 ? stream state -> FAIL cannot read this worktree's state" \
        "1:true:true" "$RC:$(out_line 'dirty: ?'):$(out_line "GATE merge-up: FAIL — cannot read this worktree's state (git status failed here)")"
    chmod 644 "$IDX_A"
fi

# gate-09: the default branch is derived through branch.<P>.remote -> refs/remotes/<r>/HEAD
gitq -C "$F30" branch trunk sprint-x
D_TRUNK="$(sib trunk)"
gitq -C "$F30" worktree add "$D_TRUNK" trunk
mk_stream "$F30" s-t trunk; WT_T="$WT"
gitq -C "$F30" remote add origin "$TMP_ROOT/nowhere-origin"
gitq -C "$F30" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
gitq -C "$F30" remote add upstream "$TMP_ROOT/nowhere-upstream"
gitq -C "$F30" symbolic-ref refs/remotes/upstream/HEAD refs/remotes/upstream/trunk
run "$WT_T" bash "$STATUS" --gate merge-up
G9_BEFORE="$RC:$(last_line "$OUT")"
gitq -C "$F30" config branch.trunk.remote upstream
run "$WT_T" bash "$STATUS" --gate merge-up
test_case "gate-09 default-branch parent -> FAIL is the default branch (derived through the remote rule)" \
    "0:GATE merge-up: OK:1:true" "$G9_BEFORE:$RC:$(out_line "GATE merge-up: FAIL — parent 'trunk' is the default branch — publish through a sprint branch and a pull request (/sprint-end), never by merging into it here")"
gitq -C "$F30" remote remove origin
gitq -C "$F30" remote remove upstream
gitq -C "$F30" config --unset branch.trunk.remote

gitq -C "$F30" branch tmpb sprint-x
mk_stream "$F30" s-c tmpb; WT_C="$WT"
run "$WT_C" bash "$STATUS" --gate merge-up
test_case "gate-10 parent not checked out -> FAIL" \
    "1:true" "$RC:$(out_line "GATE merge-up: FAIL — parent 'tmpb' is not checked out in any worktree — the merge needs a working tree to run in")"

printf 'changed\n' > "$F30/seed.txt"
run "$WT_A" bash "$STATUS" --gate merge-up
test_case "gate-11 dirty parent -> FAIL" \
    "1:true" "$RC:$(out_line "GATE merge-up: FAIL — parent worktree $F30 is dirty — someone is mid-edit there; do not merge under them")"
run "$WT_A" bash "$STATUS" --gate merge-down
test_case "gate-16 merge-down ignores a dirty parent" "0:GATE merge-down: OK" "$RC:$(last_line "$OUT")"
gitq -C "$F30" restore seed.txt

printf 'u\n' > "$F30/u.txt"
run "$WT_A" bash "$STATUS" --gate merge-up
test_case "gate-12 untracked file in the parent ignored" "0:GATE merge-up: OK" "$RC:$(last_line "$OUT")"
rm -f "$F30/u.txt"

if [ "$IS_ROOT" = 1 ]; then
    skip_case "gate-13 ? parent state -> FAIL cannot read the parent worktree's state" "running as root"
else
    chmod 000 "$F30/.git/index"
    run "$WT_A" bash "$STATUS" --gate merge-up
    test_case "gate-13 ? parent state -> FAIL cannot read the parent worktree's state" \
        "1:true:true" "$RC:$(out_line 'parent_dirty: ?'):$(out_line "GATE merge-up: FAIL — cannot read the parent worktree's state at $F30 (git status failed there)")"
    chmod 644 "$F30/.git/index"
fi

D_P2="$(sib p2)"
gitq -C "$F30" worktree add "$D_P2" -b p2 sprint-x
mk_stream "$F30" s-p2 p2; WT_P2="$WT"
MH_P2="$(git -C "$D_P2" rev-parse --git-path MERGE_HEAD)"
tip "$D_P2" HEAD > "$MH_P2"
run "$WT_P2" bash "$STATUS" --gate merge-up
test_case "gate-14 MERGE_HEAD in a LINKED parent -> FAIL (anchored file test)" \
    "1:true:true" "$RC:$(out_line 'parent_merge_in_progress: yes'):$(out_line "GATE merge-up: FAIL — parent worktree $D_P2 has a merge in progress (MERGE_HEAD) — a sibling's /merge-up is unfinished; retry later")"
rm -f "$MH_P2"

tip "$F30" HEAD > "$F30/.git/MERGE_HEAD"
run "$WT_A" bash "$STATUS" --gate merge-up
test_case "gate-15 MERGE_HEAD in the MAIN-worktree parent -> FAIL (relative --git-path anchored)" \
    "1:true:true" "$RC:$(out_line 'parent_merge_in_progress: yes'):$(out_line "GATE merge-up: FAIL — parent worktree $F30 has a merge in progress (MERGE_HEAD) — a sibling's /merge-up is unfinished; retry later")"
rm -f "$F30/.git/MERGE_HEAD"

printf 'changed\n' > "$WT_A/seed.txt"
run "$WT_A" bash "$STATUS" --gate merge-down
test_case "gate-17 merge-down dirty stream -> FAIL" \
    "1:true" "$RC:$(out_line 'GATE merge-down: FAIL — current worktree has uncommitted tracked changes — commit or stash first (this merges committed work only)')"
gitq -C "$WT_A" restore seed.txt

run "$F30" bash "$STATUS" --gate start
test_case "gate-18 start OK prints branch: first" \
    "0:branch: sprint-x:GATE start: OK:2" "$RC:$(nth_line 1):$(last_line "$OUT"):$(nlines "$OUT")"

gitq -C "$F30" checkout -q --detach
run "$F30" bash "$STATUS" --gate start
test_case "gate-19 start detached -> FAIL" \
    "1:branch: HEAD:true" "$RC:$(nth_line 1):$(out_line 'GATE start: FAIL — HEAD is detached; check out the branch to fan out from')"
gitq -C "$F30" checkout -q sprint-x

run "$WT_A" bash "$STATUS" --gate start
G31_GATE=$(out_has 'is itself a stream of')
test_case "gate-20 start on a stream -> FAIL is itself a stream of" \
    "1:true" "$RC:$(out_line 'GATE start: FAIL — s-a is itself a stream of sprint-x; fan out from the base (sprint-x), never from inside a stream')"

printf 'changed\n' > "$F30/seed.txt"
printf 'u\n' > "$F30/u.txt"
run "$F30" bash "$STATUS" --gate start
test_case "gate-21 start dirty base -> ADVISORY: <N> uncommitted change(s) (untracked counted), exit 0" \
    "0:true:GATE start: OK" "$RC:$(out_line 'ADVISORY: 2 uncommitted change(s) will NOT be in the streams (they fork from HEAD)'):$(last_line "$OUT")"
gitq -C "$F30" restore seed.txt
rm -f "$F30/u.txt"

if [ "$IS_ROOT" = 1 ]; then
    skip_case "gate-22 start git status failure -> ADVISORY: cannot count uncommitted changes" "running as root"
else
    chmod 000 "$F30/.git/index"
    run "$F30" bash "$STATUS" --gate start
    test_case "gate-22 start git status failure -> ADVISORY: cannot count uncommitted changes, exit 0" \
        "0:true:GATE start: OK" "$RC:$(out_line 'ADVISORY: cannot count uncommitted changes (git status failed here); streams fork from HEAD regardless'):$(last_line "$OUT")"
    chmod 644 "$F30/.git/index"
fi

gitq -C "$F30" checkout -q main
run "$F30" bash "$STATUS" --gate start
test_case "gate-23 start on the default branch -> ADVISORY, exit 0" \
    "0:true:GATE start: OK" "$RC:$(out_line 'ADVISORY: main is the default branch — streams off it cannot /merge-up into it; publish through a sprint branch and a pull request'):$(last_line "$OUT")"
gitq -C "$F30" checkout -q sprint-x

run "$F30" bash "$STATUS" --gate children
test_case "gate-24 children merged child worktree=<path>" \
    "0:true:GATE children: OK" "$RC:$(out_line "CHILD s-a: merged (0 unmerged) worktree=$WT_A"):$(last_line "$OUT")"

commit_in "$WT_A" a.txt "a" "stream a"
run "$F30" bash "$STATUS" --gate children
test_case "gate-25 children unmerged child -> FAIL count" \
    "1:true:GATE children: FAIL — 1 child stream(s) need attention" "$RC:$(out_line "CHILD s-a: 1 unmerged commit(s) worktree=$WT_A — run /merge-up inside it, or explicitly abandon it"):$(last_line "$OUT")"
gitq -C "$F30" merge -q --no-edit s-a

# gate-26 / 27 in their own fixture: a branch whose history has a missing object
# (rev-list fails, show-ref passes) and a config residue for a deleted branch
make_fixture 31
F31="$FIX"
gitq -C "$F31" checkout -q -b ghost
empty_commit_in "$F31" mid
MID="$(tip "$F31" HEAD)"
empty_commit_in "$F31" tip
gitq -C "$F31" checkout -q sprint-x
rm -f "$F31/.git/objects/${MID:0:2}/${MID:2}"
gitq -C "$F31" config branch.ghost.exosuitParent sprint-x
run "$F31" bash "$STATUS" --gate children
test_case "gate-26 children ? count fails closed" \
    "1:true:GATE children: FAIL — 1 child stream(s) need attention" "$RC:$(out_line 'CHILD ghost: ? unmerged commit(s) worktree=- — run /merge-up inside it, or explicitly abandon it'):$(last_line "$OUT")"
gitq -C "$F31" config --remove-section branch.ghost
gitq -C "$F31" update-ref -d refs/heads/ghost
gitq -C "$F31" config branch.gone.exosuitParent sprint-x
run "$F31" bash "$STATUS" --gate children
test_case "gate-27 children GONE residue -> FAIL with the --remove-section line" \
    "1:true:GATE children: FAIL — 1 child stream(s) need attention" "$RC:$(out_line 'CHILD gone: branch GONE, config residue — run: git config --remove-section branch.gone'):$(last_line "$OUT")"
gitq -C "$F31" config --remove-section branch.gone

printf 'u\n' > "$WT_A/u.txt"
run "$F30" bash "$STATUS" --gate children
test_case "gate-28 children dirty child -> ADVISORY: CHILD ... is dirty, exit unchanged" \
    "0:true:GATE children: OK" "$RC:$(out_line "ADVISORY: CHILD s-a: worktree $WT_A is dirty — uncommitted work there is not on sprint-x"):$(last_line "$OUT")"
rm -f "$WT_A/u.txt"

run "$WT_A" bash "$STATUS" --gate children
test_case "gate-29 children none -> CHILD: none (...) and OK" \
    "0:true:GATE children: OK" "$RC:$(out_line 'CHILD: none (no stream records s-a as its parent)'):$(last_line "$OUT")"

STUB_AGENTS_CASE=fail
run "$F30" CLAUDE_STUB_LOG="$TMP_ROOT/g30.log" bash "$STATUS" --gate children
G30="$(exists "$TMP_ROOT/g30.log"):$(err_has 'ADVISORY')"
run "$F30" CLAUDE_STUB_LOG="$TMP_ROOT/g30.log" bash "$STATUS" --gate start
test_case "gate-30 children and start never call the claude stub" \
    "false:false:false:false" "$G30:$(exists "$TMP_ROOT/g30.log"):$(err_has 'ADVISORY')"
no_sessions

run "$WT_A" bash "$NEWWT" s-nest
G31_CREATE=$(err_has 'is itself a stream of')
test_case "gate-31 the nested-stream ERROR: of new-worktree and the GATE start: FAIL line both contain is itself a stream of (drift-05)" \
    "true:true" "$G31_CREATE:$G31_GATE"

# gate-32: the same refusal as me-16, in the gate's own voice — one line, no
# block, exit 1 (CTRL_A is the newline-path worktree built in the me group).
run "$CTRL_A" bash "$STATUS" --gate merge-up
G32="$RC:$(nlines "$OUT"):$(out_line 'GATE merge-up: FAIL — worktree path contains a control character; unsupported'):$(grep -c -E '^[a-z_]+: ' "$OUT" || true)"
run "$CTRL_A" bash "$STATUS" --gate merge-down
test_case "gate-32 the merge gates refuse a control-character worktree path" \
    "1:1:true:0:1:1:true:0" "$G32:$RC:$(nlines "$OUT"):$(out_line 'GATE merge-down: FAIL — worktree path contains a control character; unsupported'):$(grep -c -E '^[a-z_]+: ' "$OUT" || true)"

# gate-33: this stream's own path is ordinary; the TAB is in the PARENT's
# worktree path, which the block hands to git -C just the same.
make_fixture 32
F32="$FIX"
gitq -C "$F32" branch sprint-2 sprint-x
CTRL_P="$(printf '%s\tp' "$(sib sprint-2)")"
gitq -C "$F32" worktree add "$CTRL_P" sprint-2
gitq -C "$F32" worktree add -b s-ord "$(sib s-ord)" sprint-2
gitq -C "$F32" config branch.s-ord.exosuitParent sprint-2
run "$(sib s-ord)" bash "$STATUS" --me
test_case "gate-33 a control character in the parent's worktree path is refused too" \
    "2:true:1:true" "$RC:$(out_empty):$(nlines "$ERR"):$(err_has 'ERROR: worktree path contains a control character; unsupported')"

# gate-34: a detached HEAD has no name a child can record, so "none" would be
# a fail-open answer the other three gates do not give.
make_fixture 33
F33="$FIX"
mk_stream "$F33" s-c; WT_CH="$WT"
gitq -C "$F33" branch s-cc s-c
gitq -C "$F33" config branch.s-cc.exosuitParent s-c
run "$WT_CH" bash "$STATUS" --gate children
G34_OK="$RC:$(last_line "$OUT"):$(grep -c -E '^CHILD ' "$OUT" || true)"
gitq -C "$WT_CH" checkout -q --detach
run "$WT_CH" bash "$STATUS" --gate children
G34_DET="$RC:$(nlines "$OUT"):$(out_line 'GATE children: FAIL — HEAD is detached — check out a branch'):$(grep -c -E '^CHILD ' "$OUT" || true):$(grep -c -E '^CHILD: none' "$OUT" || true)"
gitq -C "$WT_CH" checkout -q s-c
run "$WT_CH" bash "$STATUS" --gate children
test_case "gate-34 gate children refuses a detached HEAD" \
    "0:GATE children: OK:1:1:1:true:0:0:0:GATE children: OK" \
    "$G34_OK:$G34_DET:$RC:$(last_line "$OUT")"

##############################################################################
echo ""
echo "  -- session --"
##############################################################################
make_fixture 40
F40="$FIX"
mk_stream "$F40" s-a; WT_A="$WT"
mk_stream "$F40" s-b; WT_B="$WT"

set_sessions co "$F40" sa "$WT_A"
run "$F40" bash "$STATUS"
cp "$OUT" "$TMP_ROOT/s01.out"
test_case "session-01 Session column filled from compact JSON with name before cwd" \
    "true:true:true" "$(row_ok "| $F40 | sprint-x | - | (base) | - | co | clean | "):$(row_ok "| $WT_A | s-a | sprint-x | +0/-0 | - | sa | clean | "):$(err_empty)"

set_sessions co "$F40" zz "/nowhere/else/entirely"
run "$F40" bash "$STATUS"
S02_TABLE="$(out_has 'zz'):$(row_ok "| $F40 | sprint-x | - | (base) | - | co | clean | ")"
run "$F40" bash "$STATUS" --porcelain
test_case "session-02 unrelated session ignored" "false:true:false" "$S02_TABLE:$(out_has 'zz')"

STUB_AGENTS_CASE=garbage
run "$F40" bash "$STATUS"
S03_ADV="ADVISORY: session detection unavailable (claude agents --json is not valid JSON) — Session reads '-', no message will be addressed, and cleanup's live-session guard cannot fire"
test_case "session-03 garbage JSON -> - everywhere and one stderr ADVISORY (not valid JSON)" \
    "0:true:true:true:1" "$RC:$(row_ok "| $F40 | sprint-x | - | (base) | - | - | clean | "):$(row_ok "| $WT_A | s-a | sprint-x | +0/-0 | - | - | clean | "):$(err_has "$S03_ADV"):$(err_count 'ADVISORY: session detection unavailable')"
test_case "session-10 advisory printed exactly once per run" "1" "$(err_count 'ADVISORY: session detection unavailable')"
test_case "session-11 advisory is on stderr, not stdout" "false" "$(out_has 'ADVISORY: session detection')"

STUB_AGENTS_CASE=nonarray
run "$F40" bash "$STATUS"
test_case "session-04 non-array JSON -> same advisory" \
    "true:true" "$(err_has "$S03_ADV"):$(row_ok "| $WT_A | s-a | sprint-x | +0/-0 | - | - | clean | ")"

STUB_AGENTS_CASE=none
run "$F40" bash "$STATUS"
test_case "session-05 empty array -> -, no advisory" \
    "true:true" "$(row_ok "| $WT_A | s-a | sprint-x | +0/-0 | - | - | clean | "):$(err_empty)"

STUB_NOCLAUDE=1
run "$F40" bash "$STATUS"
test_case "session-06 claude absent -> advisory (claude is not on PATH)" \
    "true:true" "$(err_has "ADVISORY: session detection unavailable (claude is not on PATH) — Session reads '-', no message will be addressed, and cleanup's live-session guard cannot fire"):$(row_ok "| $WT_A | s-a | sprint-x | +0/-0 | - | - | clean | ")"
STUB_NOCLAUDE=0

STUB_AGENTS_CASE=fail
run "$F40" bash "$STATUS"
test_case "session-07 claude agents exit 1 -> advisory (claude agents --json failed)" \
    "true" "$(err_has "ADVISORY: session detection unavailable (claude agents --json failed) — Session reads '-', no message will be addressed, and cleanup's live-session guard cannot fire")"

set_sessions co "$F40" sa "$WT_A"
STUB_HIDE=jq
run "$F40" bash "$STATUS"
if [ -x "$PY_DIR/python3" ]; then
    test_case "session-08 jq hidden, python3 present -> same rows, no advisory" \
        "true:true" "$(same "$TMP_ROOT/s01.out" "$OUT"):$(err_empty)"
else
    skip_case "session-08 jq hidden, python3 present -> same rows, no advisory" "python3 not on PATH"
fi
STUB_HIDE=jq,python3
run "$F40" bash "$STATUS"
test_case "session-09 both hidden -> advisory (no JSON parser on PATH (install jq))" \
    "true:true" "$(err_has "ADVISORY: session detection unavailable (no JSON parser on PATH (install jq)) — Session reads '-', no message will be addressed, and cleanup's live-session guard cannot fire"):$(row_ok "| $WT_A | s-a | sprint-x | +0/-0 | - | - | clean | ")"
STUB_HIDE=""

STUB_AGENTS_CASE=garbage
run "$WT_A" bash "$MERGEUP"
test_case "session-12 the advisory passes through merge-up-run.sh (stderr of the gate capture reaches the caller)" \
    "0:true:true" "$RC:$(err_has "$S03_ADV"):$(out_line 'MERGE: nothing-to-merge')"

# session-13..15: an empty (or all-whitespace) answer is not "no sessions". jq
# exits 0 on it with no output, which read as an empty roster and silenced the
# advisory; session-05 below stays the counter-case for a real empty array.
STUB_AGENTS_CASE=empty
run "$F40" bash "$STATUS"
test_case "session-13 an empty agents answer is an advisory, not no sessions" \
    "0:true:true:true:1" "$RC:$(err_has "$S03_ADV"):$(row_ok "| $F40 | sprint-x | - | (base) | - | - | clean | "):$(row_ok "| $WT_A | s-a | sprint-x | +0/-0 | - | - | clean | "):$(err_count 'ADVISORY: session detection unavailable')"
STUB_AGENTS_CASE=spaces
run "$F40" bash "$STATUS"
test_case "session-14 an all-whitespace agents answer is the same advisory" \
    "0:true:true" "$RC:$(err_has "$S03_ADV"):$(row_ok "| $WT_A | s-a | sprint-x | +0/-0 | - | - | clean | ")"
STUB_AGENTS_CASE=empty
run "$F40" bash "$STATUS"
cp "$OUT" "$TMP_ROOT/s15jq"; cp "$ERR" "$TMP_ROOT/s15jqe"
STUB_HIDE=jq
run "$F40" bash "$STATUS"
if [ -x "$PY_DIR/python3" ]; then
    test_case "session-15 jq hidden, python3 present -> the two parsers agree on an empty answer" \
        "0:true:true:true" "$RC:$(err_has "$S03_ADV"):$(same "$TMP_ROOT/s15jq" "$OUT"):$(same "$TMP_ROOT/s15jqe" "$ERR")"
else
    skip_case "session-15 jq hidden, python3 present -> the two parsers agree on an empty answer" "python3 not on PATH"
fi
STUB_HIDE=""
no_sessions

##############################################################################
echo ""
echo "  -- overlap --"
##############################################################################
OV_HEADER="**Overlap (committed on both, not yet merged):**"
make_fixture 50
F50="$FIX"
mk_stream "$F50" s-a; WT_A="$WT"
mk_stream "$F50" s-b; WT_B="$WT"
mk_stream "$F50" s-c; WT_C="$WT"
commit_in "$WT_A" f5.txt "a5" "a f5"; commit_in "$WT_A" f6.txt "a6" "a f6"; commit_in "$WT_A" f1.txt "a1" "a f1"
commit_in "$WT_B" f5.txt "b5" "b f5"; commit_in "$WT_B" f6.txt "b6" "b f6"; commit_in "$WT_B" f2.txt "b2" "b f2"
commit_in "$WT_C" f7.txt "c7" "c f7"
run "$F50" bash "$STATUS"
test_case "overlap-01 two streams sharing two committed files -> one s-a and s-b line under the header" \
    "0:true:true:1" "$RC:$(out_line "$OV_HEADER"):$(out_line '- `s-a` and `s-b`: f5.txt f6.txt'):$(out_count '- `')"

make_fixture 51
F51="$FIX"
mk_stream "$F51" s-a; WT_A="$WT"
commit_in "$WT_A" f1.txt "a1" "a f1"
run "$F51" bash "$STATUS"
test_case "overlap-03 one stream -> nothing" "0:false:false" "$RC:$(out_has 'Overlap'):$(out_has '- `')"
mk_stream "$F51" s-b; WT_B="$WT"
commit_in "$WT_B" f2.txt "b2" "b f2"
run "$F51" bash "$STATUS"
test_case "overlap-02 disjoint streams -> no header" "0:false:false" "$RC:$(out_has 'Overlap'):$(out_has '- `')"

gitq -C "$F50" merge -q --no-edit s-a
run "$F50" bash "$STATUS"
test_case "overlap-04 a merged-up stream (ahead 0) is not paired" \
    "0:false:true" "$RC:$(out_has 'Overlap'):$(row_ok "| $(dirname "$F50")/proj-s-a | s-a | sprint-x | +0/-0 | - | - | clean | ")"

make_fixture 52
F52="$FIX"
mk_stream "$F52" s-a; WT_A="$WT"
mk_stream "$F52" s-b; WT_B="$WT"
for i in 01 02 03 04 05 06 07 08 09 10 11 12 13; do
    commit_in "$WT_A" "g$i.txt" "a$i" "a g$i"
    commit_in "$WT_B" "g$i.txt" "b$i" "b g$i"
done
run "$F52" bash "$STATUS"
test_case "overlap-05 13 shared paths -> +1 more" \
    "true" "$(out_line '- `s-a` and `s-b`: g01.txt g02.txt g03.txt g04.txt g05.txt g06.txt g07.txt g08.txt g09.txt g10.txt g11.txt g12.txt +1 more')"

make_fixture 53
F53="$FIX"
mk_stream "$F53" s-a; WT_A="$WT"
mk_stream "$F53" s-c; WT_C="$WT"
mk_stream "$F53" s-b; WT_B="$WT"
commit_in "$WT_A" shared.txt "a" "a shared"
commit_in "$WT_B" shared.txt "b" "b shared"
commit_in "$WT_C" shared.txt "c" "c shared"
run "$F53" bash "$STATUS"
L_AB=$(grep -n -F -x -- '- `s-a` and `s-b`: shared.txt' "$OUT" | cut -d: -f1 | head -n 1)
L_AC=$(grep -n -F -x -- '- `s-a` and `s-c`: shared.txt' "$OUT" | cut -d: -f1 | head -n 1)
L_BC=$(grep -n -F -x -- '- `s-b` and `s-c`: shared.txt' "$OUT" | cut -d: -f1 | head -n 1)
test_case "overlap-06 three streams -> three pairwise lines in sorted order" \
    "3:true" "$(out_count '- `'):$([ -n "$L_AB" ] && [ -n "$L_AC" ] && [ -n "$L_BC" ] && [ "$L_AB" -lt "$L_AC" ] && [ "$L_AC" -lt "$L_BC" ] && echo true || echo false)"
cp "$OUT" "$TMP_ROOT/ov08"

o7=""
run "$F53" bash "$STATUS" --porcelain;          o7="$o7$(out_has 'Overlap')"
run "$WT_A" bash "$STATUS" --me;                o7="$o7:$(out_has 'Overlap')"
run "$WT_A" bash "$STATUS" --gate merge-up;     o7="$o7:$(out_has 'Overlap')"
run "$WT_A" bash "$STATUS" --gate merge-down;   o7="$o7:$(out_has 'Overlap')"
run "$F53" bash "$STATUS" --gate start;         o7="$o7:$(out_has 'Overlap')"
run "$F53" bash "$STATUS" --gate children;      o7="$o7:$(out_has 'Overlap')"
test_case "overlap-07 not in --porcelain, --me or any gate" "false:false:false:false:false:false" "$o7"

run_lc en_US.UTF-8 "$F53" bash "$STATUS"
test_case "overlap-08 output identical under LC_ALL=C and en_US.UTF-8" "true:true" "$(same "$TMP_ROOT/ov08" "$OUT"):$(out_line "$OV_HEADER")"

##############################################################################
echo ""
echo "  -- mergeup --"
##############################################################################
# mu_fixture <n>: a fixture with one stream s-a; sets FIX and WT_A
mu_fixture() {
    make_fixture "$1"
    mk_stream "$FIX" s-a
    WT_A="$WT"
}
# hook <fixture-dir> <name> <body>: a git hook in the shared hooks directory
hook() {
    printf '#!/bin/sh\n%s\n' "$3" > "$1/.git/hooks/$2"
    chmod +x "$1/.git/hooks/$2"
}

mu_fixture 60
F60="$FIX"
run "$WT_A" bash "$MERGEUP"
test_case "mergeup-01 nothing-to-merge exit 0" \
    "0:MERGE: nothing-to-merge:15" "$RC:$(last_line "$OUT"):$(nlines "$OUT")"
cp "$OUT" "$TMP_ROOT/mu30"
run "$WT_A" bash "$MERGEUP"
test_case "mergeup-30 no-op byte identity (nothing-to-merge twice)" "true" "$(same "$TMP_ROOT/mu30" "$OUT")"

run "$WT_A" CLAUDE_STUB_LOG="$TMP_ROOT/mu24.log" bash "$MERGEUP" --allow_behind
test_case "mergeup-24 --allow_behind -> ERROR: unknown option, exit 2, gate not run" \
    "2:true:true:true:false" "$RC:$(err_has 'ERROR: unknown option --allow_behind'):$(err_has 'usage: merge-up-run.sh [--allow-behind]'):$(out_empty):$(exists "$TMP_ROOT/mu24.log")"

run "$WT_A" bash "$MERGEUP" -h
m28=""
for w in 'MERGE: nothing-to-merge' 'MERGE: behind' 'MERGE: refused' 'MERGE: locked' 'MERGE: blocked' 'MERGE: busy' 'MERGE: conflict' 'MERGE: merged' 'files:' 'SYNC: ok' 'SYNC: FAIL' 'GATE merge-up: OK' 'GATE merge-up: FAIL'; do
    m28="$m28$(out_has "$w")"
done
test_case "mergeup-28 -h lists every verdict word" "0:truetruetruetruetruetruetruetruetruetruetruetruetrue" "$RC:$m28"

printf 'changed\n' > "$WT_A/seed.txt"
B25="$(tip "$F60" HEAD)"
run "$WT_A" bash "$MERGEUP"
test_case "mergeup-25 gate FAIL -> exit 1, nothing touched" \
    "1:true:false:true" "$RC:$(out_has 'GATE merge-up: FAIL — current worktree has uncommitted tracked changes'):$(out_has 'MERGE:'):$([ "$(tip "$F60" HEAD)" = "$B25" ] && echo true || echo false)"
gitq -C "$WT_A" restore seed.txt

commit_in "$WT_A" sub.txt "s" "stream sub"
mkdir -p "$WT_A/sub"
run "$WT_A/sub" bash "$MERGEUP"
test_case "mergeup-29 run from a subdirectory of the stream" \
    "0:true:true:SYNC: ok" "$RC:$(out_has 'MERGE: merged '):$(out_line 'files: sub.txt'):$(last_line "$OUT")"

mu_fixture 61
F61="$FIX"
empty_commit_in "$F61" "parent p1"
commit_in "$WT_A" a.txt "a" "stream a"
B61="$(tip "$F61" HEAD)"
run "$WT_A" bash "$MERGEUP"
test_case "mergeup-02 behind -> exit 6, parent untouched" \
    "6:true:true" "$RC:$(out_line 'MERGE: behind — the parent has 1 commit(s) this stream lacks; run /merge-down first (or re-run with --allow-behind to merge anyway)'):$([ "$(tip "$F61" HEAD)" = "$B61" ] && echo true || echo false)"
run "$WT_A" bash "$MERGEUP" --allow-behind
test_case "mergeup-31 --allow-behind on a stream that is behind -> a true merge, SYNC: ok, exit 0" \
    "0:true:true:SYNC: ok:true" "$RC:$(out_has "MERGE: merged $(git -C "$F61" rev-parse --short=7 HEAD) 2 commit(s) 1 file(s)"):$(out_line 'files: a.txt'):$(last_line "$OUT"):$([ "$(tip "$WT_A" HEAD)" = "$(tip "$F61" HEAD)" ] && echo true || echo false)"

mu_fixture 62
F62="$FIX"
commit_in "$WT_A" a.txt "a" "stream a"
run "$WT_A" bash "$MERGEUP" --allow-behind
test_case "mergeup-03 --allow-behind -> MERGE: merged <sha7> 1 commit(s) 1 file(s), files: a.txt, SYNC: ok, exit 0" \
    "0:true:true:SYNC: ok" "$RC:$(out_line "MERGE: merged $(git -C "$F62" rev-parse --short=7 HEAD) 1 commit(s) 1 file(s)"):$(out_line 'files: a.txt'):$(last_line "$OUT")"
test_case "mergeup-04 parent contains the commit, stream fast-forwarded, parent clean" \
    "true:true:a" "$([ "$(tip "$F62" refs/heads/sprint-x)" = "$(tip "$WT_A" HEAD)" ] && echo true || echo false):$([ -z "$(git -C "$F62" status --porcelain)" ] && echo true || echo false):$(cat "$F62/a.txt" 2>/dev/null)"

mu_fixture 63
F63="$FIX"
commit_in "$F63" seed.txt "parent" "parent seed"
commit_in "$WT_A" seed.txt "stream" "stream seed"
B63="$(tip "$F63" HEAD)"
run "$WT_A" bash "$MERGEUP" --allow-behind
test_case "mergeup-05 conflict -> exit 4, (aborted, parent restored to <sha7>), no MERGE_HEAD left" \
    "4:true:false:true" "$RC:$(out_line "MERGE: conflict — seed.txt (aborted, parent restored to ${B63:0:7})"):$(exists "$F63/.git/MERGE_HEAD"):$([ "$(tip "$F63" HEAD)" = "$B63" ] && echo true || echo false)"

make_fixture 64
F64="$FIX"
D_P2="$(sib p2)"
gitq -C "$F64" worktree add "$D_P2" -b p2 sprint-x
mk_stream "$F64" s-a2 p2; WT_A2="$WT"
commit_in "$WT_A2" a.txt "a" "stream a"
B64="$(tip "$D_P2" HEAD)"
LOCK_P2="$(git -C "$D_P2" rev-parse --git-path index.lock)"
touch "$LOCK_P2"
run "$WT_A2" bash "$MERGEUP"
test_case "mergeup-06 index.lock in a LINKED parent -> MERGE: locked, exit 3, nothing changed" \
    "3:true:true" "$RC:$(out_line "MERGE: locked — another git process holds the parent's index (index.lock present); nothing changed, retry in a minute"):$([ "$(tip "$D_P2" HEAD)" = "$B64" ] && echo true || echo false)"
rm -f "$LOCK_P2"

mu_fixture 65
F65="$FIX"
commit_in "$WT_A" a.txt "a" "stream a"
B65="$(tip "$F65" HEAD)"
touch "$F65/.git/index.lock"
run "$WT_A" bash "$MERGEUP"
test_case "mergeup-07 index.lock in the MAIN-worktree parent -> MERGE: locked (anchored)" \
    "3:true:true" "$RC:$(out_line "MERGE: locked — another git process holds the parent's index (index.lock present); nothing changed, retry in a minute"):$([ "$(tip "$F65" HEAD)" = "$B65" ] && echo true || echo false)"
rm -f "$F65/.git/index.lock"
run "$WT_A" bash "$MERGEUP"
test_case "mergeup-08 succeeds after unlock" \
    "0:true:SYNC: ok" "$RC:$(out_has 'MERGE: merged '):$(last_line "$OUT")"

mu_fixture 66
F66="$FIX"
commit_in "$WT_A" clash.txt "c" "stream clash"
printf 'x\n' > "$F66/clash.txt"
B66="$(tip "$F66" HEAD)"
run "$WT_A" bash "$MERGEUP"
test_case "mergeup-09 untracked parent file that would be overwritten -> MERGE: blocked — ... clash.txt, exit 7" \
    "7:true:true" "$RC:$(out_line 'MERGE: blocked — untracked files in the parent worktree would be overwritten: clash.txt; nothing changed — move them aside there, then retry'):$([ "$(tip "$F66" HEAD)" = "$B66" ] && echo true || echo false)"

mu_fixture 67
F67="$FIX"
empty_commit_in "$F67" "parent p1"
commit_in "$WT_A" a.txt "a" "stream a"
gitq -C "$F67" config merge.ff only
B67="$(tip "$F67" HEAD)"
run "$WT_A" bash "$MERGEUP" --allow-behind
test_case "mergeup-10 merge.ff=only on the parent -> MERGE: refused — ... (nothing changed), exit 3, tip unchanged" \
    "3:true:true:false" "$RC:$(out_line 'MERGE: refused — fatal: Not possible to fast-forward, aborting. (nothing changed)'):$([ "$(tip "$F67" HEAD)" = "$B67" ] && echo true || echo false):$(out_has 'hint:')"

mu_fixture 68
F68="$FIX"
commit_in "$F68" p.txt "p" "parent p"
commit_in "$WT_A" a.txt "a" "stream a"
hook "$F68" pre-merge-commit 'exit 1'
B68="$(tip "$F68" HEAD)"
run "$WT_A" bash "$MERGEUP" --allow-behind
test_case "mergeup-11 failing pre-merge-commit hook -> MERGE: refused — ... (the commit step was refused — ...; aborted, parent restored to <sha7>), exit 3, no MERGE_HEAD" \
    "3:true:true:false:true" "$RC:$(out_has 'MERGE: refused — '):$(out_has "(the commit step was refused — a pre-merge-commit, prepare-commit-msg or commit-msg hook, or commit signing; aborted, parent restored to ${B68:0:7})"):$(exists "$F68/.git/MERGE_HEAD"):$([ "$(tip "$F68" HEAD)" = "$B68" ] && echo true || echo false)"

mu_fixture 69
F69="$FIX"
commit_in "$F69" p.txt "p" "parent p"
commit_in "$WT_A" a.txt "a" "stream a"
hook "$F69" commit-msg 'echo "commit-msg says no" >&2; exit 1'
B69="$(tip "$F69" HEAD)"
run "$WT_A" bash "$MERGEUP" --allow-behind
test_case "mergeup-12 failing commit-msg hook -> same class" \
    "3:true:false:true" "$RC:$(out_has "(the commit step was refused — a pre-merge-commit, prepare-commit-msg or commit-msg hook, or commit signing; aborted, parent restored to ${B69:0:7})"):$(exists "$F69/.git/MERGE_HEAD"):$([ "$(tip "$F69" HEAD)" = "$B69" ] && echo true || echo false)"

mu_fixture 70
F70="$FIX"
mk_stream "$F70" s-sib; WT_SIB="$WT"
commit_in "$WT_A" x.txt "x" "stream x"
commit_in "$WT_SIB" seed.txt "sibling" "sibling seed"
commit_in "$F70" seed.txt "parent" "parent seed"
gitq -C "$F70" merge --no-edit s-sib
MH70="$(cat "$F70/.git/MERGE_HEAD" 2>/dev/null)"
run "$WT_A" bash "$MERGEUP"
test_case "mergeup-13 sibling's conflicted MERGE_HEAD -> gate FAIL, MERGE_HEAD untouched" \
    "1:true:false:true" "$RC:$(out_line "GATE merge-up: FAIL — parent worktree $F70 has a merge in progress (MERGE_HEAD) — a sibling's /merge-up is unfinished; retry later"):$(out_has 'MERGE:'):$([ -n "$MH70" ] && [ "$(cat "$F70/.git/MERGE_HEAD" 2>/dev/null)" = "$MH70" ] && echo true || echo false)"

mu_fixture 71
F71="$FIX"
commit_in "$WT_A" a.txt "a" "stream a"
FOREIGN="$(tip "$F71" refs/heads/main)"
printf '%s\n' "printf '%s\\n' $(shq "$FOREIGN") > $(shq "$F71/.git/MERGE_HEAD")" > "$TMP_ROOT/trap71.sh"
B71="$(tip "$F71" HEAD)"
run "$WT_A" GIT_TRAP_RUN="$TMP_ROOT/trap71.sh" GIT_TRAP_MATCH="merge --no-edit refs/heads/s-a" bash "$MERGEUP"
test_case "mergeup-14 foreign MERGE_HEAD appearing after the gate (fixture) -> MERGE: busy, exit 3, never aborted" \
    "3:true:true:true:true" "$RC:$(out_line 'MERGE: busy — the parent worktree holds another merge in progress (not this stream'"'"'s); nothing changed, retry later'):$(out_has '  git: fatal: You have not concluded your merge (MERGE_HEAD exists).'):$([ "$(cat "$F71/.git/MERGE_HEAD" 2>/dev/null)" = "$FOREIGN" ] && echo true || echo false):$([ "$(tip "$F71" HEAD)" = "$B71" ] && echo true || echo false)"

mu_fixture 72
F72="$FIX"
commit_in "$WT_A" a.txt "a" "stream a"
gitq -C "$F72" branch other sprint-x
printf '%s\n' "$(shq "$REAL_GIT") -C $(shq "$F72") checkout -q other" > "$TMP_ROOT/trap72.sh"
run "$WT_A" GIT_TRAP_RUN="$TMP_ROOT/trap72.sh" GIT_TRAP_MATCH="-C $F72 symbolic-ref -q HEAD" bash "$MERGEUP"
test_case "mergeup-15 parent worktree switched after the gate -> MERGE: refused — parent worktree ... no longer has <P> checked out, exit 3" \
    "3:true:false" "$RC:$(out_line "MERGE: refused — parent worktree $F72 no longer has sprint-x checked out; nothing changed"):$(out_has 'SYNC:')"

mu_fixture 73
F73="$FIX"
commit_in "$WT_A" a.txt "a" "stream a"
gitq -C "$F73" branch other sprint-x
hook "$F73" post-merge 'unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE; git checkout -q other'
run "$WT_A" bash "$MERGEUP"
test_case "mergeup-16 branch switched during the merge (post-merge hook fixture) -> refused naming the state, never where the merge landed, exit 3, no SYNC:" \
    "3:true:false:false" "$RC:$(out_line "MERGE: refused — parent worktree $F73 is on other and its HEAD is not the tip of sprint-x; the merge may sit on either — inspect $F73 by hand"):$(out_has 'SYNC:'):$(out_has 'landed on')"

mu_fixture 74
F74="$FIX"
empty_commit_in "$F74" "sprint moves"
gitq -C "$F74" tag sprint-x refs/heads/main
gitq -C "$WT_A" merge -q --no-edit refs/heads/sprint-x
commit_in "$WT_A" a.txt "a" "stream a"
run "$WT_A" bash "$MERGEUP"
test_case "mergeup-17 tag named like the parent does not produce a false refused (full-ref compare)" \
    "0:true:SYNC: ok:false" "$RC:$(out_has 'MERGE: merged '):$(last_line "$OUT"):$(out_has 'MERGE: refused')"

mu_fixture 75
F75="$FIX"
# The parent must hold a commit the stream lacks, or the parent-side merge is a
# fast-forward and the mid-run stream commit still has the parent as an ancestor
# (the sync-back would then be "Already up to date." and never FAIL).
empty_commit_in "$F75" "parent p1"
commit_in "$WT_A" a.txt "a" "stream a"
FIRST75="$(tip "$WT_A" HEAD)"
printf '%s\n' "$(shq "$REAL_GIT") -C $(shq "$WT_A") commit -q --allow-empty -m mid-run" > "$TMP_ROOT/trap75.sh"
run "$WT_A" GIT_TRAP_RUN="$TMP_ROOT/trap75.sh" GIT_TRAP_MATCH="merge --ff-only --no-edit refs/heads/sprint-x" bash "$MERGEUP" --allow-behind
test_case "mergeup-18 commit on the stream mid-run -> SYNC: FAIL ... no longer an ancestor, exit 5, parent merge stands" \
    "5:true:true:true" "$RC:$(out_line 'SYNC: FAIL — the stream is no longer an ancestor of sprint-x (something committed here during the run); fatal: Not possible to fast-forward, aborting.'):$(out_has 'MERGE: merged '):$(git -C "$F75" merge-base --is-ancestor "$FIRST75" HEAD 2>/dev/null && echo true || echo false)"

mu_fixture 76
F76="$FIX"
commit_in "$F76" new.txt "parent new" "parent new"
commit_in "$WT_A" a.txt "a" "stream a"
printf 'mine\n' > "$WT_A/new.txt"
run "$WT_A" bash "$MERGEUP" --allow-behind
test_case "mergeup-19 untracked stream file blocks the fast-forward -> SYNC: FAIL — untracked files ..., exit 5" \
    "5:true:true" "$RC:$(out_line 'SYNC: FAIL — untracked files in this stream would be overwritten by the fast-forward; move them aside, then: git merge --ff-only sprint-x'):$(out_has 'MERGE: merged ')"

mu_fixture 77
F77="$FIX"
empty_commit_in "$F77" "parent p1"
commit_in "$WT_A" a.txt "a" "stream a"
LOCK_A="$(git -C "$WT_A" rev-parse --git-path index.lock)"
touch "$LOCK_A"
run "$WT_A" bash "$MERGEUP" --allow-behind
test_case "mergeup-20 stream index.lock -> SYNC: FAIL — this stream's index is locked, exit 5" \
    "5:true:true" "$RC:$(out_line "SYNC: FAIL — this stream's index is locked (index.lock present); retry: git merge --ff-only sprint-x"):$(out_has 'MERGE: merged ')"
rm -f "$LOCK_A"

mu_fixture 78
F78="$FIX"
for i in 01 02 03 04 05 06 07 08 09 10 11 12 13 14; do printf '%s\n' "$i" > "$WT_A/b$i.txt"; done
gitq -C "$WT_A" add -A
empty_commit_in "$WT_A" "fourteen files"
run "$WT_A" bash "$MERGEUP"
test_case "mergeup-21 files: trimmed, single spaces, 12 cap +K more" \
    "0:true:true" "$RC:$(out_line 'files: b01.txt b02.txt b03.txt b04.txt b05.txt b06.txt b07.txt b08.txt b09.txt b10.txt b11.txt b12.txt +2 more'):$(out_line "MERGE: merged $(git -C "$F78" rev-parse --short=7 HEAD) 1 commit(s) 14 file(s)")"

mu_fixture 79
commit_in "$WT_A" "ü.txt" "u" "stream umlaut"
run "$WT_A" bash "$MERGEUP"
test_case "mergeup-22 non-ASCII path unquoted (quotePath=off)" \
    "0:true:false" "$RC:$(out_line 'files: ü.txt'):$(out_has '\303\274')"

mu_fixture 80
F80="$FIX"
commit_in "$F80" seed.txt "parent" "parent seed"
commit_in "$WT_A" seed.txt "stream" "stream seed"
BTIP80="$(tip "$WT_A" HEAD)"
printf '%s\n' "$(shq "$REAL_GIT") -C $(shq "$WT_A") commit -q --allow-empty -m mid-run" > "$TMP_ROOT/trap80.sh"
run "$WT_A" GIT_TRAP_RUN="$TMP_ROOT/trap80.sh" GIT_TRAP_MATCH="merge --no-edit refs/heads/s-a" bash "$MERGEUP" --allow-behind
MH80="$(cat "$F80/.git/MERGE_HEAD" 2>/dev/null)"
test_case "mergeup-23 ownership uses BTIP captured before the merge" \
    "3:true:true:false" "$RC:$(out_line "MERGE: busy — this stream's branch moved during the run; the merge of its new tip ${MH80:0:7} is unfinished in $F80 and was left as it stands — finish or abort it there, then retry"):$([ -n "$MH80" ] && [ "$MH80" = "$(tip "$WT_A" HEAD)" ] && [ "$MH80" != "$BTIP80" ] && echo true || echo false):$(out_has 'MERGE: conflict')"

make_fixture 81
F81="$FIX"
gitq -C "$F81" checkout -q main
mk_stream "$F81" s-m main; WT_M="$WT"
commit_in "$WT_M" a.txt "a" "stream a"
run "$WT_M" bash "$MERGEUP"
test_case "mergeup-26 default-branch parent -> exit 1" \
    "1:true:false" "$RC:$(out_line "GATE merge-up: FAIL — parent 'main' is the default branch — publish through a sprint branch and a pull request (/sprint-end), never by merging into it here"):$(out_has 'MERGE:')"

mu_fixture 82
F82="$FIX"
gitq init -q --bare "$TMP_ROOT/remote82.git"
gitq -C "$F82" remote add origin "$TMP_ROOT/remote82.git"
commit_in "$WT_A" a.txt "a" "stream a"
run "$WT_A" GIT_LOG="$TMP_ROOT/mu27.log" bash "$MERGEUP"
test_case "mergeup-27 the script never pushes (no push in a recording git wrapper's log)" \
    "0:SYNC: ok:0:true" "$RC:$(last_line "$OUT"):$(grep -c -w push "$TMP_ROOT/mu27.log" 2>/dev/null || true):$([ -s "$TMP_ROOT/mu27.log" ] && echo true || echo false)"

TAB="$(printf '\t')"
STUB_MERGEUP=""
# stub_gate <dir>: a copy of merge-up-run.sh beside a worktree-status.sh stub
# that prints $STUB_BLOCK and exits 0. It reproduces the residual gate -> merge
# window: states the real gate refuses (a dirty parent, a dirty stream) but
# cannot keep refused for the merge that runs a moment later.
stub_gate() {
    mkdir -p "$1"
    cp "$MERGEUP" "$1/merge-up-run.sh"
    write_exec "$1/worktree-status.sh" '#!/bin/sh
printf '"'"'%s\n'"'"' "${STUB_BLOCK:-}"
exit 0'
    STUB_MERGEUP="$1/merge-up-run.sh"
}

mu_fixture 83
F83="$FIX"
commit_in "$WT_A" a.txt "a" "stream a"
run "$WT_A" bash "$STATUS" --gate merge-up
GB83="$(cat "$OUT")"
stub_gate "$TMP_ROOT/sg83"
B83="$(tip "$F83" HEAD)"
m32=""
for k in branch parent parent_dir; do
    run "$WT_A" STUB_BLOCK="$(printf '%s\n' "$GB83" | sed "s/^$k: .*/&$TAB/")" bash "$STUB_MERGEUP"
    m32="$m32$RC:$(err_has "ERROR: the gate block's branch, parent or parent_dir contains a control character; nothing touched"):$(grep -c -E '^MERGE: ' "$OUT" || true):$([ "$(tip "$F83" HEAD)" = "$B83" ] && echo true || echo false) "
done
run "$WT_A" STUB_BLOCK="$GB83" bash "$STUB_MERGEUP"
test_case "mergeup-32 a forged gate block is rejected before any git runs" \
    "1:true:0:true 1:true:0:true 1:true:0:true :0:true" \
    "$m32:$RC:$(out_has 'MERGE: merged ')"

# mergeup-33: the verdicts are chosen by reading git's own prose, so the two
# mutating calls pin LC_ALL=C. Without the pin this degraded to a bare
# MERGE: refused (exit 3) that named clash.txt nowhere.
mu_fixture 84
F84="$FIX"
commit_in "$WT_A" clash.txt "c" "stream clash"
printf 'x\n' > "$F84/clash.txt"
B84="$(tip "$F84" HEAD)"
if has_locale de_DE.UTF-8; then
    run_lc de_DE.UTF-8 "$WT_A" bash "$MERGEUP"
    test_case "mergeup-33 MERGE: blocked keeps its filename in a non-English locale" \
        "7:true:true" "$RC:$(out_line 'MERGE: blocked — untracked files in the parent worktree would be overwritten: clash.txt; nothing changed — move them aside there, then retry'):$([ "$(tip "$F84" HEAD)" = "$B84" ] && echo true || echo false)"
else
    skip_case "mergeup-33 MERGE: blocked keeps its filename in a non-English locale" "de_DE.UTF-8 not installed"
fi

# mergeup-34: the other half of "would be overwritten by merge" — moving a
# tracked edit aside is not the remedy; its owner commits or stashes it.
mu_fixture 85
F85="$FIX"
commit_in "$F85" shared.txt "base" "shared base"
gitq -C "$WT_A" merge -q --ff-only refs/heads/sprint-x
commit_in "$WT_A" shared.txt "stream edit" "stream shared"
run "$WT_A" bash "$STATUS" --gate merge-up
GB85="$(cat "$OUT")"
stub_gate "$TMP_ROOT/sg85"
printf 'coordinator edit\n' > "$F85/shared.txt"
B85="$(tip "$F85" HEAD)"
M34="MERGE: blocked — uncommitted changes to tracked files in the parent worktree would be overwritten: shared.txt; nothing changed — their owner commits or stashes them there, then retry"
run "$WT_A" STUB_BLOCK="$GB85" bash "$STUB_MERGEUP"
m34="$RC:$(out_line "$M34"):$([ "$(tip "$F85" HEAD)" = "$B85" ] && echo true || echo false):$(cat "$F85/shared.txt" 2>/dev/null)"
if has_locale de_DE.UTF-8; then
    run_lc de_DE.UTF-8 "$WT_A" STUB_BLOCK="$GB85" bash "$STUB_MERGEUP"
    m34="$m34:$RC:$(out_line "$M34")"
    E34="7:true:true:coordinator edit:7:true"
else
    E34="7:true:true:coordinator edit"
fi
test_case "mergeup-34 a tracked-change clash gets the commit-or-stash remedy" "$E34" "$m34"

# mergeup-35: the same two clashes, this time on the stream's fast-forward back
mu_fixture 86
F86="$FIX"
commit_in "$F86" only-parent.txt "parent" "parent only"
commit_in "$WT_A" a.txt "a" "stream a"
printf 'mine\n' > "$WT_A/only-parent.txt"
run "$WT_A" bash "$MERGEUP" --allow-behind
m35a="$RC:$(out_has 'MERGE: merged '):$(out_line 'SYNC: FAIL — untracked files in this stream would be overwritten by the fast-forward; move them aside, then: git merge --ff-only sprint-x')"

mu_fixture 87
F87="$FIX"
commit_in "$F87" shared.txt "base" "shared base"
gitq -C "$WT_A" merge -q --ff-only refs/heads/sprint-x
commit_in "$WT_A" b.txt "b" "stream b"
run "$WT_A" bash "$STATUS" --gate merge-up
GB87="$(cat "$OUT")"
stub_gate "$TMP_ROOT/sg87"
commit_in "$F87" shared.txt "parent edit" "parent shared"
printf 'staged stream edit\n' > "$WT_A/shared.txt"
gitq -C "$WT_A" add -- shared.txt
S35B="SYNC: FAIL — uncommitted changes to tracked files in this stream would be overwritten by the fast-forward; commit or stash them, then: git merge --ff-only sprint-x"
run "$WT_A" STUB_BLOCK="$GB87" bash "$STUB_MERGEUP" --allow-behind
m35b="$RC:$(out_has 'MERGE: merged '):$(out_line "$S35B")"
if has_locale de_DE.UTF-8; then
    run_lc de_DE.UTF-8 "$WT_A" STUB_BLOCK="$GB87" bash "$STUB_MERGEUP" --allow-behind
    m35b="$m35b:$RC:$(out_line "$S35B")"
    E35="5:true:true:5:true:true:5:true"
else
    E35="5:true:true:5:true:true"
fi
test_case "mergeup-35 the SYNC arm splits the same two clashes" "$E35" "$m35a:$m35b"

# mergeup-36: "git merge --abort" deliberately keeps an unstaged change it did
# not make, so a dirty bystander is not evidence of a failed abort. The first
# run is the byte-identical clean-conflict text, for contrast.
mu_fixture 88
F88="$FIX"
commit_in "$F88" bystander.txt "base" "bystander"
commit_in "$F88" shared.txt "parent" "parent shared"
commit_in "$WT_A" shared.txt "stream" "stream shared"
run "$WT_A" bash "$STATUS" --gate merge-up
GB88="$(cat "$OUT")"
stub_gate "$TMP_ROOT/sg88"
B88="$(tip "$F88" HEAD)"
run "$WT_A" STUB_BLOCK="$GB88" bash "$STUB_MERGEUP" --allow-behind
m36clean="$RC:$(out_line "MERGE: conflict — shared.txt (aborted, parent restored to ${B88:0:7})")"
printf 'coordinator edit\n' > "$F88/bystander.txt"
run "$WT_A" STUB_BLOCK="$GB88" bash "$STUB_MERGEUP" --allow-behind
test_case "mergeup-36 an unrelated dirty file is not a failed abort" \
    "4:true:4:true:true:false:coordinator edit" \
    "$m36clean:$RC:$(out_line "MERGE: conflict — shared.txt (aborted, parent restored to ${B88:0:7}; uncommitted tracked changes remain in $F88 — they are not this merge's)"):$([ "$(tip "$F88" HEAD)" = "$B88" ] && echo true || echo false):$(exists "$F88/.git/MERGE_HEAD"):$(cat "$F88/bystander.txt" 2>/dev/null)"

# mergeup-37: the never-abort rule has to survive the new live-ref comparison —
# a genuinely foreign MERGE_HEAD still reads as a foreigner and is left alone.
mu_fixture 89
F89="$FIX"
commit_in "$F89" shared.txt "base" "shared base"
gitq -C "$WT_A" merge -q --ff-only refs/heads/sprint-x
commit_in "$WT_A" a.txt "a" "stream a"
run "$WT_A" bash "$STATUS" --gate merge-up
GB89="$(cat "$OUT")"
stub_gate "$TMP_ROOT/sg89"
gitq -C "$F89" branch foreign sprint-x
D_FGN="$(sib foreign)"
gitq -C "$F89" worktree add "$D_FGN" foreign
commit_in "$D_FGN" shared.txt "foreign" "foreign shared"
commit_in "$F89" shared.txt "parent" "parent shared"
FGN89="$(tip "$F89" refs/heads/foreign)"
gitq -C "$F89" merge --no-edit refs/heads/foreign
run "$WT_A" STUB_BLOCK="$GB89" bash "$STUB_MERGEUP" --allow-behind
test_case "mergeup-37 a real sibling merge still reads as a foreigner" \
    "3:true:true" "$RC:$(out_line 'MERGE: busy — the parent worktree holds another merge in progress (not this stream'"'"'s); nothing changed, retry later'):$([ "$(cat "$F89/.git/MERGE_HEAD" 2>/dev/null)" = "$FGN89" ] && echo true || echo false)"

# mergeup-38: commit signing fails in the same place a commit hook does, which
# is why the sibling verdict (mergeup-11 / 12) names it too.
mu_fixture 94
F94="$FIX"
commit_in "$F94" p.txt "p" "parent p"
commit_in "$WT_A" a.txt "a" "stream a"
write_exec "$TMP_ROOT/gpg-fail" '#!/bin/sh
exit 1'
gitq -C "$F94" config commit.gpgsign true
gitq -C "$F94" config gpg.program "$TMP_ROOT/gpg-fail"
B94="$(tip "$F94" HEAD)"
run "$WT_A" bash "$MERGEUP" --allow-behind
test_case "mergeup-38 a signing failure is named beside the hooks" \
    "3:true:false:true" "$RC:$(out_has "(the commit step was refused — a pre-merge-commit, prepare-commit-msg or commit-msg hook, or commit signing; aborted, parent restored to ${B94:0:7})"):$(exists "$F94/.git/MERGE_HEAD"):$([ "$(tip "$F94" HEAD)" = "$B94" ] && echo true || echo false)"
gitq -C "$F94" config --unset commit.gpgsign
gitq -C "$F94" config --unset gpg.program

##############################################################################
echo ""
echo "  -- mergedown --"
##############################################################################
# merge-down has no script: its Step 2 line IS the contract. These cases run
# that exact line, lifted out of SKILL.md, against a repository where a tag
# shares the parent's name.
MD="$SKILLS_DIR/merge-down/SKILL.md"
MU="$SKILLS_DIR/merge-up/SKILL.md"
# md_block <n>: the body of "### Step <n> " up to the next "### Step "
md_block() { LC_ALL=C sed -n "/^### Step $1 /,/^### Step $(($1 + 1)) /p" "$MD"; }
# md_step2_line: the one mutating line inside Step 2's ```bash fence
md_step2_line() { md_block 2 | LC_ALL=C grep -F -- 'git merge --no-edit' | head -1; }

MDL="$(md_step2_line | LC_ALL=C sed 's/<parent>/sprint-x/g')"
TABC="$(printf '0\t2')"

make_fixture 130
F130="$FIX"
gitq -C "$F130" checkout -q -b stream sprint-x
gitq -C "$F130" checkout -q sprint-x
commit_in "$F130" parent.txt "p" "c1"
gitq -C "$F130" checkout -q stream
commit_in "$F130" s.txt "s" "s1"
gitq -C "$F130" tag sprint-x refs/heads/main
run "$F130" bash -c "$MDL"
test_case "mergedown-01 the Step 2 line from SKILL.md merges the branch, not a tag of the same name" \
    "0:true:false:false:false:true:Merge branch 'refs/heads/sprint-x' into stream:$TABC" \
    "$RC:$(out_has 'Merge made by the'):$(out_has 'Already up to date.'):$(out_has 'is ambiguous'):$(err_has 'is ambiguous'):$(out_line "$TABC"):$(git -C "$F130" log -1 --pretty=%s 2>/dev/null):$(git -C "$F130" rev-list --left-right --count refs/heads/sprint-x...HEAD 2>/dev/null)"

make_fixture 131
F131="$FIX"
gitq -C "$F131" checkout -q -b stream sprint-x
gitq -C "$F131" checkout -q sprint-x
commit_in "$F131" parent.txt "p" "c1"
gitq -C "$F131" checkout -q -b divergent main
commit_in "$F131" foreign.txt "f" "foreign"
gitq -C "$F131" checkout -q stream
commit_in "$F131" s.txt "s" "s1"
gitq -C "$F131" tag sprint-x refs/heads/divergent
gitq -C "$F131" update-ref -d refs/heads/divergent
run "$F131" bash -c "$MDL"
test_case "mergedown-02 a same-named tag on divergent history is not merged into the stream" \
    "true:false:true:$TABC" \
    "$(exists "$F131/parent.txt"):$(exists "$F131/foreign.txt"):$(has_pre "$(git -C "$F131" log -1 --pretty=%s 2>/dev/null)" "Merge branch 'refs/heads/"):$(git -C "$F131" rev-list --left-right --count refs/heads/sprint-x...HEAD 2>/dev/null)"

# mergedown-03: on a conflict the recount is the unmerged one (never 0 behind)
# and the printed sha is the pre-merge HEAD, not a merge commit.
make_fixture 132
F132="$FIX"
gitq -C "$F132" checkout -q -b stream sprint-x
gitq -C "$F132" checkout -q sprint-x
commit_in "$F132" parent.txt "p" "c1"
commit_in "$F132" clash.txt "parent side" "parent clash"
gitq -C "$F132" checkout -q stream
commit_in "$F132" s.txt "s" "s1"
commit_in "$F132" clash.txt "stream side" "stream clash"
gitq -C "$F132" tag sprint-x refs/heads/main
PRE132="$(git -C "$F132" rev-parse --short HEAD 2>/dev/null)"
run "$F132" bash -c "$MDL"
test_case "mergedown-03 a conflict still prints the recount and the sha, and the sha is the pre-merge HEAD" \
    "true:false:true:true:exit-1" \
    "$(out_line "$(printf '2\t2')"):$(out_line "$TABC"):$(out_line "$PRE132"):$(exists "$F132/.git/MERGE_HEAD"):$(LC_ALL=C sed -n 's/.*"outcome":"\([^"]*\)".*/\1/p' "$F132/docs/sessions/.activity-log.jsonl" 2>/dev/null | tail -1)"

##############################################################################
echo ""
echo "  -- cleanup --"
##############################################################################
make_fixture 90
F90="$FIX"
mk_stream "$F90" s-a; WT_A="$WT"
mk_stream "$F90" s-np --no-parent; WT_NP="$WT"
mk_stream "$F90" s-un; WT_UN="$WT"
commit_in "$WT_UN" u.txt "u" "unmerged"
mk_stream "$F90" s-dirty; WT_D="$WT"
printf 'd\n' > "$WT_D/untracked.txt"
mk_stream "$F90" s-q; WT_Q="$WT"
rm -rf "$WT_Q"
gitq -C "$F90" branch tmpbase sprint-x
mk_stream "$F90" s-og tmpbase; WT_OG="$WT"
gitq -C "$F90" branch -d tmpbase
gitq -C "$F90" branch tmpb sprint-x
mk_stream "$F90" s-nc tmpb; WT_NC="$WT"
mk_stream "$F90" s-a-0010; WT_A10="$WT"

snapshot() {
    { git -C "$F90" worktree list --porcelain; git -C "$F90" branch --list; git -C "$F90" config --get-regexp 'exosuit' ; } > "$1" 2>/dev/null
}
snapshot "$TMP_ROOT/c01a"
run "$F90" bash "$CLEANUP"
snapshot "$TMP_ROOT/c01b"
cp "$OUT" "$TMP_ROOT/c28"
test_case "cleanup-01 dry run mutates nothing (worktree list, branches, config identical)" \
    "true:true" "$(same "$TMP_ROOT/c01a" "$TMP_ROOT/c01b"):$(exists "$WT_A")"
test_case "cleanup-02 merged clean stream -> CLEANUP: remove" "true" "$(out_line "CLEANUP: remove s-a $WT_A")"
test_case "cleanup-03 keep no-parent" "true" "$(out_line "CLEANUP: keep s-np $WT_NP — no recorded parent (not a stream; not ours to remove)")"
test_case "cleanup-04 keep +N unmerged" "true" "$(out_line "CLEANUP: keep s-un $WT_UN — +1 unmerged commit(s): run /merge-up inside it first")"
test_case "cleanup-05 keep dirty (untracked counts)" "true" "$(out_line "CLEANUP: keep s-dirty $WT_D — tree is dirty: commit or stash there first")"
test_case "cleanup-06 keep ? tree state with the prune sentence" "true" "$(out_line "CLEANUP: keep s-q $WT_Q — worktree state unreadable (git status failed there); if the directory is gone, --apply's prune will drop the entry")"
test_case "cleanup-07 keep parent-gone with the reflog remedy, before any delete" \
    "true:true" "$(out_line "CLEANUP: keep s-og $WT_OG — recorded parent 'tmpbase' does not exist locally: restore it (git branch tmpbase <sha> from git reflog or the pull request) and re-run, or, once you are certain its work landed elsewhere, remove the worktree and delete the branch by hand (safe delete refuses unreachable commits; the skill never forces)"):$(exists "$WT_OG")"
test_case "cleanup-08 keep parent not checked out anywhere" "true" "$(out_line "CLEANUP: keep s-nc $WT_NC — parent 'tmpb' is not checked out in any worktree; the branch is deleted from the parent's worktree, so check tmpb out (git worktree add ../proj-tmpb tmpb) and re-run")"
test_case "cleanup-21 dry run exits 0 even with keeps" "0:true" "$RC:$(out_has 'CLEANUP: keep ')"
test_case "cleanup-22 main worktree never a candidate" \
    "0:0" "$(grep -c -E '^CLEANUP: (keep|remove) sprint-x ' "$OUT" || true):$(grep -c -F -- " $F90 —" "$OUT" || true)"

run "$F90" bash "$CLEANUP"
test_case "cleanup-28 no-op byte identity" "true" "$(same "$TMP_ROOT/c28" "$OUT")"

run "$WT_A" bash "$CLEANUP"
test_case "cleanup-10 cwd guard fires in the dry run too" \
    "0:true:false" "$RC:$(out_line "CLEANUP: keep s-a $WT_A — this is the current worktree; run cleanup from the base (sprint-x) instead"):$(out_has "CLEANUP: remove s-a ")"
mkdir -p "$WT_A/sub"
run "$WT_A/sub" bash "$CLEANUP"
test_case "cleanup-11 cwd in a subdirectory of the stream is guarded" \
    "true" "$(out_line "CLEANUP: keep s-a $WT_A — this is the current worktree; run cleanup from the base (sprint-x) instead")"
run "$WT_A10" bash "$CLEANUP"
test_case "cleanup-12 sibling -0010 prefix is not guarded (slash-terminated compare)" \
    "true:true" "$(out_line "CLEANUP: remove s-a $WT_A"):$(out_line "CLEANUP: keep s-a-0010 $WT_A10 — this is the current worktree; run cleanup from the base (sprint-x) instead")"

set_sessions live1 "$WT_A"
run "$F90" bash "$CLEANUP"
test_case "cleanup-24 dry run prints live-session=<name> for a live stream" \
    "true" "$(out_line "CLEANUP: remove s-a $WT_A live-session=live1")"
run "$F90" GIT_LOG="$TMP_ROOT/c23.log" bash "$CLEANUP" --apply
test_case "cleanup-25 --apply keeps a live stream with the live-guard line, exit 0" \
    "0:true:true" "$RC:$(out_line "CLEANUP: keep s-a $WT_A — a Claude session (live1) is live there; removing it now would delete that session's working directory. Close that terminal, then re-run --apply"):$(exists "$WT_A")"
test_case "cleanup-17 pruned <n> printed" "CLEANUP: pruned 1:true" "$(last_line "$OUT"):$(out_line 'CLEANUP: removed s-a-0010')"
test_case "cleanup-23 branch deleted from \$PDIR (recording git wrapper sees -C <parent-dir> branch -d)" \
    "true" "$(grep -F -x -q -- "-C $F90 branch -d s-a-0010" "$TMP_ROOT/c23.log" 2>/dev/null && echo true || echo false)"
no_sessions

# cleanup-09 is destructive (--apply with the live-session guard blind), so it
# runs after every case that needs fixture 90 intact.
STUB_NOCLAUDE=1
run "$WT_A" bash "$CLEANUP" --apply
test_case "cleanup-09 --apply from inside the candidate stream with claude hidden -> this is the current worktree, directory still exists" \
    "true:true:true" "$(out_line "CLEANUP: keep s-a $WT_A — this is the current worktree; run cleanup from the base (sprint-x) instead"):$(exists "$WT_A"):$(err_has 'ADVISORY: session detection unavailable (claude is not on PATH)')"
STUB_NOCLAUDE=0

gitq init -q --bare "$TMP_ROOT/remote90.git"
gitq -C "$F90" remote add origin "$TMP_ROOT/remote90.git"
gitq -C "$WT_A" push -q -u origin s-a
commit_in "$WT_A" more.txt "m" "more"
gitq -C "$F90" merge -q --no-edit s-a
run "$F90" bash "$CLEANUP"
C13_DRY=$(out_line "CLEANUP: keep s-a $WT_A — its upstream origin/s-a is behind it, so git's safe delete would refuse the branch: push it (git push origin s-a) or drop the upstream (git branch --unset-upstream s-a), then re-run")
run "$F90" bash "$CLEANUP" --apply
test_case "cleanup-13 stale upstream (pushed -u, committed again, merged) -> its upstream ... is behind it, nothing removed" \
    "true:true:true:false" "$C13_DRY:$(out_has "its upstream origin/s-a is behind it"):$(exists "$WT_A"):$(out_has 'CLEANUP: removed s-a')"
# cleanup-14: an upstream ref that no longer resolves is the ordinary end of a
# stream (pushed -u, pull request merged, remote branch deleted, fetch --prune).
# Git falls back to HEAD and deletes normally, so there is nothing to keep for.
gitq -C "$F90" update-ref -d refs/remotes/origin/s-a
run "$F90" bash "$CLEANUP" --apply
test_case "cleanup-14 upstream ref deleted -> removed" \
    "0:true:false:false:" "$RC:$(out_line 'CLEANUP: removed s-a'):$(exists "$WT_A"):$(git -C "$F90" show-ref --verify -q refs/heads/s-a 2>/dev/null && echo true || echo false):$(git -C "$F90" config --get-regexp '^branch\.s-a\.' 2>/dev/null || true)"

# cleanup-14 now consumes s-a, so cleanup-15/26/27 get a stream of their own.
mk_stream "$F90" s-b; WT_B90="$WT"
gitq -C "$WT_B90" push -q -u origin s-b
printf '{"type":"test","stream":"s-b"}\n' > "$WT_B90/docs/sessions/.activity-log.jsonl"
run "$F90" bash "$CLEANUP" --apply
test_case "cleanup-15 upstream up to date -> removed" \
    "0:true:false" "$RC:$(out_line 'CLEANUP: removed s-b'):$(exists "$WT_B90")"
test_case "cleanup-26 session gone -> removed" "true" "$(out_line 'CLEANUP: removed s-b')"
test_case "cleanup-27 stream log appended to the base log before removal, base tree stays clean" \
    "true:true" "$(grep -F -x -q -- '{"type":"test","stream":"s-b"}' "$F90/docs/sessions/.activity-log.jsonl" 2>/dev/null && echo true || echo false):$([ -z "$(git -C "$F90" status --porcelain)" ] && echo true || echo false)"

make_fixture 91
F91="$FIX"
mk_stream "$F91" s-a; WT_A="$WT"
mk_stream "$F91" obs --no-parent; WT_OBS="$WT"
run "$WT_OBS" bash "$CLEANUP" --apply
test_case "cleanup-16 --apply from a third worktree -> removed, branch gone, exosuit* keys gone, observer kept" \
    "0:true:false:false::true:true" "$RC:$(out_line 'CLEANUP: removed s-a'):$(exists "$WT_A"):$(git -C "$F91" show-ref --verify -q refs/heads/s-a 2>/dev/null && echo true || echo false):$(git -C "$F91" config --get-regexp '^branch\.s-a\.' 2>/dev/null || true):$(exists "$WT_OBS"):$(out_line "CLEANUP: keep obs $WT_OBS — this is the current worktree; run cleanup from the base instead")"

make_fixture 92
F92="$FIX"
mk_stream "$F92" s-l; WT_L="$WT"
gitq -C "$F92" worktree lock "$WT_L"
run "$F92" bash "$CLEANUP" --apply
test_case "cleanup-18 --apply FAILED on git worktree remove refusal -> exit 1, worktree left" \
    "1:true:true:true" "$RC:$(out_has 'CLEANUP: FAILED s-l — git worktree remove refused: fatal: cannot remove a locked working tree'):$(out_has '; left in place'):$(exists "$WT_L")"
gitq -C "$F92" worktree unlock "$WT_L"

make_fixture 93
F93="$FIX"
mk_stream "$F93" s-r; WT_R="$WT"
printf '%s\n' "G=$(shq "$REAL_GIT"); F=$(shq "$F93")" \
    'NEW=$("$G" -C "$F" commit-tree -p refs/heads/s-r -m late "$("$G" -C "$F" rev-parse "refs/heads/s-r^{tree}")")' \
    '"$G" -C "$F" update-ref refs/heads/s-r "$NEW"' > "$TMP_ROOT/trap93.sh"
run "$F93" GIT_TRAP_RUN="$TMP_ROOT/trap93.sh" GIT_TRAP_MATCH="branch -d s-r" bash "$CLEANUP" --apply
test_case "cleanup-19 FAILED lines quote git's first line only, never a hint line" \
    "1:true:true:0" "$RC:$(out_has 'CLEANUP: FAILED s-r — worktree removed but branch kept: '):$(out_has 'not fully merged'):$(out_count 'hint')"

run "$F93" bash "$CLEANUP" --aply
test_case "cleanup-20 --aply -> unknown option, exit 2" \
    "2:true:true:true" "$RC:$(err_has 'unknown option: --aply'):$(err_has 'usage: stream-cleanup.sh [--apply]'):$(out_empty)"

# cleanup-29..33: git worktree remove fires no WorktreeRemove hook, so the
# stream's gitignored docs/sessions/ goes with the directory unless it is
# rescued first — append-only files only, symlinks never followed.
# ignore_session_files <fixture>: the session files make_fixture's .gitignore
# does not name, so a stream carrying them still reads clean.
ignore_session_files() {
    printf 'docs/sessions/.failure-log.jsonl\ndocs/sessions/.story-outcomes.tsv\ndocs/sessions/.audit-log.jsonl\ndocs/sessions/.refine-log.tsv\ndocs/sessions/.optimization-log.tsv\ndocs/sessions/.auto-save.md\ndocs/sessions/.failure-state.md\n' >> "$1/.git/info/exclude"
}
SESSION_LOGS=".activity-log.jsonl .failure-log.jsonl .story-outcomes.tsv .audit-log.jsonl .refine-log.tsv .optimization-log.tsv"

make_fixture 120
F120="$FIX"
ignore_session_files "$F120"
mk_stream "$F120" s-a; WT_L1="$WT"
for f in $SESSION_LOGS; do printf 'stream-line-%s\n' "$f" > "$WT_L1/docs/sessions/$f"; done
printf 'base auto-save\n' > "$F120/docs/sessions/.auto-save.md"
cp "$F120/docs/sessions/.auto-save.md" "$TMP_ROOT/auto-save.orig"
printf 'stream auto-save\n' > "$WT_L1/docs/sessions/.auto-save.md"
printf 'stream failure state\n' > "$WT_L1/docs/sessions/.failure-state.md"
run "$F120" bash "$CLEANUP" --apply
c29=""
for f in $SESSION_LOGS; do
    c29="$c29$(grep -F -x -q -- "stream-line-$f" "$F120/docs/sessions/$f" 2>/dev/null && echo true || echo false)"
done
test_case "cleanup-29 every declared append-only session log is rescued" \
    "0:true:truetruetruetruetruetrue:true" "$RC:$(out_line 'CLEANUP: removed s-a'):$c29:$([ -z "$(git -C "$F120" status --porcelain)" ] && echo true || echo false)"
test_case "cleanup-30 snapshot session files are not concatenated" \
    "true:false" "$(same "$TMP_ROOT/auto-save.orig" "$F120/docs/sessions/.auto-save.md"):$(exists "$F120/docs/sessions/.failure-state.md")"

# cleanup-31: the rescue empties the stream file only once its lines land, so a
# refused removal cannot append them again on the next --apply.
make_fixture 121
F121="$FIX"
mk_stream "$F121" s-a; WT_L2="$WT"
printf 'base 1\n' > "$F121/docs/sessions/.activity-log.jsonl"
printf 'stream 1\nstream 2\n' > "$WT_L2/docs/sessions/.activity-log.jsonl"
gitq -C "$F121" worktree lock "$WT_L2"
c31=""
for i in 1 2 3; do
    run "$F121" bash "$CLEANUP" --apply
    c31="$c31$RC:$(nlines "$F121/docs/sessions/.activity-log.jsonl"):$(out_has 'CLEANUP: FAILED s-a — git worktree remove refused: '):$(out_has '; left in place'):$(out_has 'tree is dirty') "
done
test_case "cleanup-31 refused removal does not duplicate the log on re-runs" \
    "1:3:true:true:false 1:3:true:true:false 1:3:true:true:false " "$c31"
gitq -C "$F121" worktree unlock "$WT_L2"

make_fixture 122
F122="$FIX"
mk_stream "$F122" s-a; WT_L3="$WT"
printf 'SECRET-BYTES\n' > "$TMP_ROOT/secret.txt"
rm -f "$WT_L3/docs/sessions/.activity-log.jsonl"
ln -s "$TMP_ROOT/secret.txt" "$WT_L3/docs/sessions/.activity-log.jsonl"
run "$F122" bash "$CLEANUP" --apply
test_case "cleanup-32 a symlinked stream log is not followed" \
    "0:true:false" "$RC:$(out_line 'CLEANUP: removed s-a'):$(grep -F -q -- 'SECRET-BYTES' "$F122/docs/sessions/.activity-log.jsonl" 2>/dev/null && echo true || echo false)"

make_fixture 123
F123="$FIX"
mk_stream "$F123" s-a; WT_L4="$WT"
printf 'target bytes\n' > "$TMP_ROOT/target.txt"
cp "$TMP_ROOT/target.txt" "$TMP_ROOT/target.orig"
ln -s "$TMP_ROOT/target.txt" "$F123/docs/sessions/.activity-log.jsonl"
printf 'stream 1\nstream 2\n' > "$WT_L4/docs/sessions/.activity-log.jsonl"
run "$F123" bash "$CLEANUP" --apply
test_case "cleanup-33 a symlinked base log is not written through" \
    "0:true:true" "$RC:$(out_line 'CLEANUP: removed s-a'):$(same "$TMP_ROOT/target.orig" "$TMP_ROOT/target.txt")"

# cleanup-34 / 35: a process substitution's exit status is unreachable, so a
# dead fact source used to look exactly like a repository with no streams.
make_fixture 124
F124="$FIX"
mk_stream "$F124" s-a; WT_L5="$WT"
DEAD="$TMP_ROOT/dead-source"
mkdir -p "$DEAD"
cp "$CLEANUP" "$DEAD/stream-cleanup.sh"
write_exec "$DEAD/worktree-status.sh" '#!/bin/sh
echo "ERROR: cannot create a temporary directory" >&2
exit 2'
run "$F124" bash "$DEAD/stream-cleanup.sh"
test_case "cleanup-34 dead fact source -> ERROR, exit 2, dry run" \
    "2:true:true" "$RC:$(err_has 'ERROR: the worktree-status.sh fact source produced no rows; nothing was examined'):$(out_empty)"
run "$F124" bash "$DEAD/stream-cleanup.sh" --apply
test_case "cleanup-35 dead fact source under --apply prints no pruned line" \
    "2:false:true" "$RC:$(out_has 'CLEANUP: pruned'):$(exists "$WT_L5")"

# cleanup-36: the row guard must not misfire on a legitimately stream-free repo
make_fixture 125
F125="$FIX"
run "$F125" bash "$CLEANUP"
test_case "cleanup-36 healthy repo with no streams still exits 0" \
    "0:false:false:true" "$RC:$(out_has 'CLEANUP: keep '):$(out_has 'CLEANUP: remove '):$(err_empty)"

##############################################################################
echo ""
echo "  -- drift --"
##############################################################################
usage_block() { sed -n '/^# Usage:/,/^set -/p' "$1"; }

LC_ALL=C grep -o 'MERGE: [a-z-]*' "$SKILLS_DIR/merge-up/SKILL.md" 2>/dev/null | sed 's/<[^>]*>//g' | LC_ALL=C sort -u > "$TMP_ROOT/d1a"
usage_block "$MERGEUP" | LC_ALL=C grep -o 'MERGE: [a-z-]*' | LC_ALL=C sort -u > "$TMP_ROOT/d1b"
test_case "drift-01 every MERGE: <word> in merge-up SKILL.md's router table appears in merge-up-run.sh's # Usage: block and vice versa" \
    "0:true:true" "$(LC_ALL=C comm -3 "$TMP_ROOT/d1a" "$TMP_ROOT/d1b" | grep -c '' || true):$([ -s "$TMP_ROOT/d1a" ] && echo true || echo false):$(grep -q -x 'MERGE: merged' "$TMP_ROOT/d1b" && echo true || echo false)"

LC_ALL=C grep -h -o 'CLEANUP: [a-z][a-z]*' "$SKILLS_DIR/parallel-work/SKILL.md" "$SKILLS_DIR/sprint-end/SKILL.md" 2>/dev/null | LC_ALL=C sort -u > "$TMP_ROOT/d2a"
usage_block "$CLEANUP" | LC_ALL=C grep -o 'CLEANUP: [a-z][a-z]*' | LC_ALL=C sort -u > "$TMP_ROOT/d2b"
test_case "drift-02 every CLEANUP: <verb> in parallel-work SKILL.md is in stream-cleanup.sh's block" \
    "0:true:true" "$(LC_ALL=C comm -23 "$TMP_ROOT/d2a" "$TMP_ROOT/d2b" | grep -c '' || true):$(grep -q -x 'CLEANUP: remove' "$TMP_ROOT/d2a" && echo true || echo false):$(grep -q -x 'CLEANUP: keep' "$TMP_ROOT/d2a" && echo true || echo false)"

LC_ALL=C grep -h -o -E 'GATE [a-z-]+:' "$SKILLS_DIR/parallel-work/SKILL.md" "$SKILLS_DIR/merge-up/SKILL.md" "$SKILLS_DIR/merge-down/SKILL.md" "$SKILLS_DIR/sprint-end/SKILL.md" "$SKILLS_DIR/sprint-start/SKILL.md" 2>/dev/null | LC_ALL=C sort -u > "$TMP_ROOT/d3a"
usage_block "$STATUS" | LC_ALL=C grep -o -E 'GATE [a-z-]+:' | LC_ALL=C sort -u > "$TMP_ROOT/d3b"
test_case "drift-03 every GATE <name> in the three SKILL.md files is in worktree-status.sh's block" \
    "0:4" "$(LC_ALL=C comm -23 "$TMP_ROOT/d3a" "$TMP_ROOT/d3b" | grep -c '' || true):$(grep -c -E '^GATE (merge-up|merge-down|start|children):$' "$TMP_ROOT/d3a" || true)"

MSG="$SKILLS_DIR/parallel-work/references/messaging.md"
MERGED_L3='siblings: run /merge-down when your tree is clean, never into uncommitted work · coordinator: your checkout advanced, re-read files you have open'
MERGED_L1='MERGED <branch> → <parent> @ <sha7> — <N> commit(s), <M> file(s)'
test_case "drift-04 message types = {HELLO, MERGED, BYE, NOTE} from messaging.md's ### headings and the three-line MERGED body appears in exactly one file under .claude/skills/" \
    "HELLO MERGED BYE NOTE :1:1:true" \
    "$(sed -n 's/^### \([A-Z][A-Z]*\).*/\1/p' "$MSG" 2>/dev/null | tr '\n' ' '):$(grep -r -l -F -- "$MERGED_L3" "$SKILLS_DIR" 2>/dev/null | grep -c '' || true):$(grep -r -l -F -- "$MERGED_L1" "$SKILLS_DIR" 2>/dev/null | grep -c '' || true):$(grep -q -F -- "$MERGED_L3" "$MSG" 2>/dev/null && echo true || echo false)"

test_case "drift-05 (= gate-31) the nested-stream ERROR: and the GATE start: FAIL line share is itself a stream of" \
    "true:true" "$G31_CREATE:$G31_GATE"

# drift-06: every "   skip    " and "ERROR: " message new-worktree.sh prints has
# to appear in its own # Usage: block. Both sides are normalised the same way —
# a shell expansion in the body and a <...> placeholder in the header both
# become "<>" — so only the prose is compared.
norm_msgs() {
    LC_ALL=C sed 's/\$([^)]*)/<>/g; s/\${[A-Za-z_][A-Za-z0-9_]*}/<>/g; s/\$[A-Za-z_][A-Za-z0-9_]*/<>/g; s/\$[0-9]/<>/g; s/<[^>]*>/<>/g' \
        | LC_ALL=C sort -u
}
sed '/^# Usage:/,/^set -/d' "$NEWWT" | LC_ALL=C grep -o -E '(ERROR: |skip    )[^"]*' | norm_msgs > "$TMP_ROOT/d6a"
usage_block "$NEWWT" | LC_ALL=C grep -o -E '(ERROR: |skip    ).*' | norm_msgs > "$TMP_ROOT/d6b"
test_case "drift-06 every skip and ERROR: string new-worktree.sh prints is in its own # Usage: block" \
    "0:true:true" "$(LC_ALL=C comm -23 "$TMP_ROOT/d6a" "$TMP_ROOT/d6b" | grep -c '' || true):$([ -s "$TMP_ROOT/d6a" ] && echo true || echo false):$([ -s "$TMP_ROOT/d6b" ] && echo true || echo false)"

# drift-07..10: merge-down has no script, so SKILL.md is the artefact under test
# (MD, MU, md_block and md_step2_line come from the mergedown group).
D7L="$(md_step2_line)"
test_case "drift-07 merge-down Step 2 spells both revisions as refs/heads/<parent>" \
    "true:true:0:0" \
    "$(has_sub "$D7L" 'git merge --no-edit "refs/heads/<parent>"'):$(has_sub "$D7L" '--count "refs/heads/<parent>...HEAD"'):$(LC_ALL=C grep -c -F -- 'merge --no-edit "<parent>"' "$MD" || true):$(LC_ALL=C grep -c -F -- '--count "<parent>...HEAD"' "$MD" || true)"

test_case "drift-08 merge-down logs no activity event before its mutating call" \
    "0:1:1:1" \
    "$(md_block 1 | LC_ALL=C grep -c -F -- '.activity-log.jsonl' || true):$(md_block 2 | LC_ALL=C grep -c -F -- '\"event\":\"start\"' || true):$(md_block 2 | LC_ALL=C grep -c -F -- '\"event\":\"end\"' || true):$(LC_ALL=C grep -c -F -- '.activity-log.jsonl' "$MD" || true)"

test_case "drift-09 merge-down's report template has no hardcoded behind count and its sha has a source" \
    "1:0:1" \
    "$(LC_ALL=C grep -c -F -x -- '**Now:** +<ahead> ahead, <behind> behind' "$MD" || true):$(LC_ALL=C grep -c -F -- '0 behind' "$MD" || true):$(md_block 2 | LC_ALL=C grep -c -F -- 'git rev-parse --short HEAD' || true)"

D10="$(LC_ALL=C sed -n '/^- Read-only on the parent:/p' "$MD")"
test_case "drift-10 merge-down does not claim that no command runs in the parent directory" \
    "0:true:true" \
    "$(LC_ALL=C grep -c -F -- 'no `git -C <parent_dir>` command, ever' "$MD" || true):$(has_sub "$D10" 'never written'):$(has_sub "$D10" "the gate's own reads")"

D11ROW="$(LC_ALL=C sed -n '/^| `MERGE: refused` |/p' "$MU")"
D11REC="$(LC_ALL=C sed -n '/^| `refused` |/p' "$MU")"
test_case "drift-11 merge-up's refused router and Recovery rows relay the verdict and add no claim" \
    "true:true:0:true:0" \
    "$(has_sub "$D11ROW" verbatim):$(has_sub "$D11ROW" 'add no claim'):$(LC_ALL=C grep -c -F -- 'nothing of yours is on the parent' "$MU" || true):$(has_sub "$D11REC" 'git -C <parent_dir> status'):$(LC_ALL=C grep -c -F -- 'The script refuses before any mutation' "$MU" || true)"

D12ROW="$(LC_ALL=C sed -n '/^\*\*Stream:\*\*/p' "$MU")"
D12PAR="$(LC_ALL=C sed -n '/^Every value comes from this run/p' "$MU")"
test_case "drift-12 merge-up's Stream report line offers a non-zero-behind alternative" \
    "true:true:true" \
    "$(has_sub "$D12ROW" 'synced (0 behind)'):$(has_sub "$D12ROW" 'run /merge-down'):$(has_sub "$D12PAR" 'pasted `behind:` line')"

D13ROW="$(LC_ALL=C sed -n '/^| no verdict line and no /p' "$MU")"
D13PRE="$(LC_ALL=C sed -n '/^Merges this stream/p' "$MU")"
test_case "drift-13 merge-up has a router row for output with no verdict line, and does not call the default path a true merge" \
    "true:true:0:true:0" \
    "$(has_sub "$D13ROW" 'not mistyped'):$(has_sub "$D13PRE" 'fast-forward when the parent has not moved'):$(LC_ALL=C grep -c -E '^A true merge' "$MU" || true):$([ -n "$D13ROW" ] && echo true || echo false):$(LC_ALL=C comm -3 "$TMP_ROOT/d1a" "$TMP_ROOT/d1b" | grep -c '' || true)"

# drift-14: the four verdict texts this commit added share their MERGE: / SYNC:
# word with an older one, so drift-01 — which compares words — cannot see them.
# Each needs a routing or troubleshooting row of its own, or the router says
# something the verdict contradicts.
usage_block "$MERGEUP" > "$TMP_ROOT/d14u"
D14=""
# route <text from the script's # Usage: block> <phrase that must route it in SKILL.md>
route() {
    LC_ALL=C grep -q -F -- "$1" "$TMP_ROOT/d14u" || D14="$D14{not in the script: $1}"
    LC_ALL=C grep -q -F -- "$2" "$MU" || D14="$D14{unrouted in SKILL.md: $2}"
}
route 'MERGE: blocked — uncommitted changes to tracked files in the parent worktree' 'uncommitted changes to tracked'
route "MERGE: busy — this stream's branch moved during the run" 'branch moved during the run'
route "uncommitted tracked changes remain in <PDIR> — they are not this merge's" "they are not this merge's"
route 'SYNC: FAIL — uncommitted changes to tracked files in this stream' 'after the named fix'
test_case "drift-14 every verdict text this commit added is routed in merge-up SKILL.md" "" "$D14"

##############################################################################
echo ""
echo "  -- ref --"
##############################################################################
REFS_DIR="$SKILLS_DIR/parallel-work/references"
test_case "ref-01 grep -L CLAUDE_SKILL_DIR lists every reference file" \
    "$(ls "$REFS_DIR"/*.md 2>/dev/null | LC_ALL=C sort | tr '\n' ' '):true" \
    "$(LC_ALL=C grep -L 'CLAUDE_SKILL_DIR' "$REFS_DIR"/*.md 2>/dev/null | LC_ALL=C sort | tr '\n' ' '):$([ -n "$(ls "$REFS_DIR"/*.md 2>/dev/null)" ] && echo true || echo false)"

R2_FILES="$SKILLS_DIR/parallel-work/SKILL.md $SKILLS_DIR/merge-up/SKILL.md $SKILLS_DIR/merge-down/SKILL.md $SKILLS_DIR/sprint-end/SKILL.md $SKILLS_DIR/sprint-start/SKILL.md"
r2a=0; r2b=0; r2n=0
for f in $R2_FILES; do
    [ -f "$f" ] || continue
    r2n=$((r2n + 1))
    grep -q -F -- '${CLAUDE_PLUGIN_ROOT' "$f" 2>/dev/null && r2a=$((r2a + 1))
    grep -q -F -- 'bash .claude/skills/' "$f" 2>/dev/null && r2b=$((r2b + 1))
done
test_case "ref-02 no \${CLAUDE_PLUGIN_ROOT and no relative bash .claude/skills/ in the three SKILL.md files, sprint-end or sprint-start" \
    "0:0:5" "$r2a:$r2b:$r2n"

##############################################################################
echo ""
echo "  -- meta --"
##############################################################################
# meta-01: a skill that instructs a message has to declare the tools that send
# it (sprint-end declared neither and told the model to send BYE), and a skill
# may only point at messaging.md's "## Addressing" when it also produces the
# --me block that section reads recipients from. The three family files also
# have line budgets: they are loaded into a live session's context.
m1a=0; m1b=0; m1n=0
for f in "$SKILLS_DIR"/*/SKILL.md; do
    [ -f "$f" ] || continue
    m1n=$((m1n + 1))
    at="$(LC_ALL=C sed -n '/^allowed-tools:/{p;q;}' "$f")"
    body_sm="$(LC_ALL=C grep -v '^allowed-tools:' "$f" | LC_ALL=C grep -c -F -- 'SendMessage' || true)"
    if [ "$body_sm" -gt 0 ]; then
        case "$at" in *SendMessage*) ;; *) m1a=$((m1a + 1)) ;; esac
        case "$at" in *ListAgents*) ;; *) m1a=$((m1a + 1)) ;; esac
    fi
    if LC_ALL=C grep -q -F -- '## Addressing' "$f"; then
        LC_ALL=C grep -q -F -- '--me' "$f" || m1b=$((m1b + 1))
    fi
done
test_case "meta-01 a skill that instructs a message declares the messaging tools, and the three SKILL.md files stay inside their line budgets" \
    "0:0:true:true:true:true" \
    "$m1a:$m1b:$([ "$m1n" -gt 3 ] && echo true || echo false):$([ "$(nlines "$MU")" -le 110 ] && echo true || echo false):$([ "$(nlines "$MD")" -le 90 ] && echo true || echo false):$([ "$(nlines "$SKILLS_DIR/parallel-work/SKILL.md")" -le 180 ] && echo true || echo false)"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
