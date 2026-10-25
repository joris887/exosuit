#!/usr/bin/env bash
# Test suite for the wrap-up skill's check: wrap-up-check.sh.
# A throwaway repo with a local bare remote; no network, no gh.
set -euo pipefail

PASS=0
FAIL=0
CHECK="$(cd "$(dirname "$0")/../.." && pwd)/skills/wrap-up/scripts/wrap-up-check.sh"

test_case() {
    local desc="$1" expected="$2" actual="$3"
    if [ "$actual" = "$expected" ]; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected '$expected', got '$actual')"
        FAIL=$((FAIL + 1))
    fi
}

verdict() { bash "$CHECK" | tail -n 1; }
has() { bash "$CHECK" | grep -c "^$1" || true; }

echo "Testing wrap-up-check.sh"
echo "========================"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
export GIT_CONFIG_GLOBAL="$TMP/gitconfig"
git config --global user.name test
git config --global user.email test@example.com
git config --global init.defaultBranch main

git init -q "$TMP/solo"
cd "$TMP/solo"
echo one > a.txt && git add a.txt && git commit -qm init
test_case "a repo with no remote has work to save" "VERDICT to-save" "$(verdict)"
test_case "no remote is named" "1" "$(has NO-REMOTE)"

git init -q --bare "$TMP/remote.git"
git clone -q "$TMP/remote.git" "$TMP/repo" 2>/dev/null
cd "$TMP/repo"
echo one > a.txt && git add a.txt && git commit -qm init && git push -q -u origin main 2>/dev/null
test_case "clean and pushed is all set" "VERDICT all-set" "$(verdict)"

echo two >> a.txt
test_case "uncommitted change is work to save" "VERDICT to-save" "$(verdict)"
test_case "uncommitted change is named" "1" "$(has UNCOMMITTED)"

git commit -qam "two"
test_case "a commit not pushed is named" "UNPUSHED    main: 1 commits on no remote" "$(bash "$CHECK" | grep '^UNPUSHED' || true)"
git push -q 2>/dev/null
test_case "pushed again is all set" "VERDICT all-set" "$(verdict)"

git switch -qc feat/new && echo three > b.txt && git add b.txt && git commit -qm three && git switch -q main
test_case "a branch never pushed is work to save" "UNPUSHED    feat/new: 1 commits on no remote" "$(bash "$CHECK" | grep '^UNPUSHED' || true)"
git push -q -u origin feat/new 2>/dev/null
git push -q origin --delete feat/new 2>/dev/null
test_case "a branch whose remote branch is gone is a note" "GONE        feat/new: its remote branch was deleted" "$(bash "$CHECK" | grep '^GONE' || true)"
test_case "a gone branch is not work to save" "VERDICT all-set" "$(verdict)"

git switch -qc sprint-1 && git push -q -u origin sprint-1 2>/dev/null
git worktree add -q -b sprint-1-a "$TMP/lane-a" sprint-1
git config branch.sprint-1-a.exosuitParent sprint-1
(cd "$TMP/lane-a" && echo lane > c.txt && git add c.txt && git commit -qm lane && echo wip > d.txt)
test_case "lane commits are a note" "LANE        sprint-1-a: 1 commits, merges into sprint-1 locally" "$(bash "$CHECK" | grep '^LANE' || true)"
test_case "another worktree's changes are named" "1" "$(has ELSEWHERE)"
test_case "lanes and other worktrees are not work to save" "VERDICT all-set" "$(verdict)"
test_case "inside the lane, its own changes are work to save" "VERDICT to-save" "$(cd "$TMP/lane-a" && verdict)"
test_case "inside the lane, its own worktree is not listed as elsewhere" "0" "$(cd "$TMP/lane-a" && has ELSEWHERE)"

echo stash >> a.txt && git stash -q
test_case "a stash is a note" "1" "$(has STASH)"
test_case "a stash is not work to save" "VERDICT all-set" "$(verdict)"

git switch -q --detach && echo four > e.txt && git add e.txt && git commit -qm four
test_case "commits on a detached HEAD are work to save" "DETACHED    1 commits on no branch" "$(bash "$CHECK" | grep '^DETACHED' || true)"
git switch -q sprint-1 2>/dev/null

before="$(git status --porcelain; git stash list; git for-each-ref)"
bash "$CHECK" >/dev/null
test_case "the check changes nothing" "$before" "$(git status --porcelain; git stash list; git for-each-ref)"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
