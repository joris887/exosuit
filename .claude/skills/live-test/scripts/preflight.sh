#!/usr/bin/env bash
# live-test preflight — verify the local stack is ready for a live test run.
# Reads checks from the project app map's ```preflight-checks fenced block
# (format per line: type|label|target|required|remedy; types: http, compose, cmd).
# Fields must not contain '|' — for piped assertions use `&&` with a temp file.
# TRUST BOUNDARY: the app map is project-owned executable config (like a Makefile) —
# `cmd` checks run as shell; only maintainers edit it, and the first-run interview
# shows every cmd line for human approval. Non-destructive; bash + curl only (docker
# only for compose checks; cmd/compose bounded at 30s where GNU timeout exists).
# Exit: 0 = all required checks pass · 1 = a required check failed, a line is
#       malformed/unfilled, a non-local target was seen, the data_environment
#       declaration is missing/invalid, or a declared block could not be
#       extracted · 2 = app map missing/unreadable (run the interview) · 3 = cmd
#       lines require per-clone user approval (or a stale --approve-cmds hash)
#       — nothing was executed.
set -uo pipefail

MAP="docs/testing/APP_MAP.md"
APPROVE_CMDS=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --approve-cmds)
      shift
      [ "$#" -gt 0 ] || { echo "REFUSED: --approve-cmds needs the hash printed by the previous run."; exit 3; }
      APPROVE_CMDS="$1" ;;
    *) MAP="$1" ;;
  esac
  shift
done

PASS=0
FAIL=0
WARN=0
UNFILLED=0

ok()   { printf "  PASS  %s\n" "$1"; PASS=$((PASS+1)); }
bad()  { printf "  FAIL  %s\n        remedy: %s\n" "$1" "$2"; FAIL=$((FAIL+1)); }
warn() { printf "  WARN  %s\n        remedy: %s\n" "$1" "$2"; WARN=$((WARN+1)); }

echo "== live-test preflight (map: $MAP) =="

if [ ! -f "$MAP" ] || [ ! -r "$MAP" ]; then
  echo "REFUSED: app map '$MAP' not found or not a readable file. Run the /live-test first-run interview to create it."
  exit 2
fi

# --- Data-environment gate: what is this stack CONNECTED to? --------------------
# "localhost" is not "safe": a dev server on localhost:8000 can hold a shared
# DATABASE_URL or live payment keys. The map MUST declare the blast radius.
DATA_ENV=$(awk '
  NR == 1 { if ($0 !~ /^---[[:space:]]*$/) exit; next }
  /^---[[:space:]]*$/ { exit }
  /^data_environment[[:space:]]*:/ {
    sub(/^data_environment[[:space:]]*:[[:space:]]*/, ""); sub(/[[:space:]]+$/, ""); print; exit
  }
' "$MAP" | tr -d '\r' | sed -e "s/^[\"']//" -e "s/[\"']\$//")
case "$DATA_ENV" in
  disposable)
    echo "  data_environment: disposable — mutating scenarios permitted" ;;
  shared)
    echo "== MUTATION LOCK: data_environment=shared — read-only run =="
    echo "  The plan MUST exclude mutating scenarios: create/update/delete,"
    echo "  double-submit/idempotency probes, form submits, destructive CLI." ;;
  *)
    echo "REFUSED: app map frontmatter must declare 'data_environment: disposable|shared' (found: '${DATA_ENV:-<missing>}')."
    echo "        localhost does not mean safe — the stack may be connected to shared data."
    echo "        Set 'disposable' ONLY if every datastore this stack writes can be freely mutated and reset;"
    echo "        otherwise set 'shared' (mutating scenarios are then excluded). Update $MAP and re-run."
    exit 1 ;;
esac

HAVE_TIMEOUT=""
command -v timeout >/dev/null 2>&1 && HAVE_TIMEOUT=1
bounded() {  # bound external commands at 30s when GNU timeout is available
  if [ -n "$HAVE_TIMEOUT" ]; then timeout 30 "$@"; else "$@"; fi
}

# --- Safety gate: live tests only ever target the local machine -----------------
# Anchored host check. Fails closed on userinfo ('user@host' tricks) and
# non-local hosts; case-insensitive; accepts localhost (incl. 'localhost.'),
# [::1], 0.0.0.0, and the whole 127/8 loopback range with strict octet checks
# (so '127.0.0.1.evil.com' stays refused).
is_local_url() {
  rest="${1#*://}"        # strip scheme
  auth="${rest%%/*}"      # authority (host[:port], maybe userinfo)
  auth="${auth%%\?*}"
  case "$auth" in *@*) return 1 ;; esac   # userinfo — curl would contact the host after '@'
  case "$auth" in \[::1\]*) return 0 ;; esac
  host="${auth%%:*}"      # strip port
  host=$(printf '%s' "$host" | tr '[:upper:]' '[:lower:]')
  host="${host%.}"        # root-dot form ('localhost.')
  case "$host" in
    localhost|0.0.0.0) return 0 ;;
    127.*)
      rest2="${host#127.}"
      case "$rest2" in *[!0-9.]*|*..*|.*|*.) return 1 ;; esac
      b="${rest2%%.*}"; tmp="${rest2#*.}"
      case "$tmp" in *.*) ;; *) return 1 ;; esac
      c="${tmp%%.*}"; d="${tmp#*.}"
      case "$d" in *.*) return 1 ;; esac
      [ -n "$b" ] && [ -n "$c" ] && [ -n "$d" ] || return 1
      [ "$b" -le 255 ] && [ "$c" -le 255 ] && [ "$d" -le 255 ] || return 1
      return 0 ;;
    *) return 1 ;;
  esac
}

# Verify one URL-position word from a curl/wget invocation ($1 = original word,
# $2 = lowercased). Scheme-less words get http:// prepended — curl/wget default
# to it — so dotless hosts, decimal/hex IPs, and bracketed IPv6 are all tested.
# A word this gate cannot verify lexically ($, backticks, quotes …) is refused:
# inside a network-fetch command, an unverifiable word IS the risk.
scan_url_word() {
  cand="${2#--url=}"
  endsemi=""
  case "$cand" in *\;) endsemi=1; cand="${cand%\;}" ;; esac
  case "$cand" in
    '') ;;
    *[!]a-z0-9.:@_/[-]*)
      remote=1; why="— cannot verify dynamic URL '$1' in a $netcmd command; use a literal localhost URL" ;;
    http://*|https://*) is_local_url "$cand" || remote=1 ;;
    *) is_local_url "http://$cand" || remote=1 ;;
  esac
  [ -n "$endsemi" ] && netcmd=""
  return 0
}

# --- Extract the checks block ------------------------------------------------------
# Fence-aware (CommonMark): opener needs >=3 backticks or tildes at <=3 spaces
# indent; the closer needs the same fence char with at least as many. Blocks
# nested inside OTHER fences (backtick or tilde, e.g. documentation examples)
# are never extracted. HTML comments are stripped pairwise OUTSIDE fences (so a
# commented-out block is cleanly disabled — see the NOTE below — while comment
# markers INSIDE the checks block are left untouched). CRLF-normalized.
CHECKS=$(awk '
  function lead(s, ch,   t, n) { t = s; sub(/^ {0,3}/, "", t); n = 0; while (substr(t, n+1, 1) == ch) n++; return n }
  # CommonMark closer: 0-3 spaces, then ONLY the opening fence char repeated at
  # least the opening count, then whitespace — mixed backtick/tilde runs are NOT
  # closers (they would leave the outer block open in a renderer)
  function isclose(s, ch, n,   t, m, rest) {
    t = s; sub(/^ {0,3}/, "", t)
    m = 0; while (substr(t, m+1, 1) == ch) m++
    if (m < n) return 0
    rest = substr(t, m + 1)
    return (rest ~ /^[[:space:]]*$/) ? 1 : 0
  }
  {
    raw = $0
    if (pf) {
      if (isclose(raw, pfch, pfn)) { pf = 0; next }
      line = raw; sub(/^[[:space:]]+/, "", line); print line; next
    }
    if (oth) {
      # fence content is byte-for-byte per CommonMark: no comment stripping here;
      # a preflight-checks mention inside a documentation fence is refused via seen
      if (isclose(raw, othch, othn)) { oth = 0; next }
      if (raw ~ /(```+|~~~+)[[:space:]]*preflight-checks/) seen++
      next
    }
    # any fence-shaped preflight-checks mention that does not become a live
    # block below is counted in `seen` and refused by the shell — hidden,
    # nested, indented, spaced, or comment-mangled fences never slip through
    mention = (raw ~ /(```+|~~~+)[[:space:]]*preflight-checks/) ? 1 : 0
    # pairwise HTML-comment stripping (outside all fenced blocks only)
    line = raw; out = ""
    while (1) {
      if (com) {
        p = index(line, "-->")
        if (p == 0) { line = ""; break }
        line = substr(line, p + 3); com = 0
      } else {
        p = index(line, "<!--")
        if (p == 0) { out = out line; break }
        out = out substr(line, 1, p - 1); line = substr(line, p + 4); com = 1
      }
    }
    line = out
    if (line ~ /^[[:space:]]*$/ && raw !~ /^[[:space:]]*$/) { if (mention) seen++; next }
    # live opener: a COLUMN-0 fenced block only. CommonMark guarantees a
    # column-0 non-blank line closes any enclosing list item or blockquote, so
    # a column-0 fence cannot be container-nested — this is what makes the
    # isclose-only exit match the renderer. Any INDENTED preflight fence falls
    # through to seen++ below and is loudly refused (never silently parsed).
    # Must be fence-leading on the RAW line (no comment residue): line == raw.
    if (raw ~ /^(`{3,}|~{3,})[[:space:]]*preflight-checks[[:space:]]*$/ && line == raw) {
      pfch = (raw ~ /^`/) ? "`" : "~"; pfn = lead(raw, pfch); pf = 1; entered++; next
    }
    if (line ~ /^ {0,3}(`{3,}|~{3,})/) {
      othch = (line ~ /^ {0,3}`/) ? "`" : "~"; othn = lead(line, othch); oth = 1
      if (mention) seen++
      next
    }
    if (mention) seen++
  }
  END { printf "__EXTRACT_META__ entered=%d com=%d pf=%d seen=%d\n", entered, com ? 1 : 0, pf ? 1 : 0, seen }
' "$MAP" | tr -d '\r')

# --- Extraction integrity (unconditional — never gated on CHECKS being empty) ----
# awk always prints its END metadata as the final line — strip it positionally
# (never by content match, so a check line may legitimately start with anything)
META=$(printf '%s\n' "$CHECKS" | tail -n 1)
CHECKS=$(printf '%s\n' "$CHECKS" | sed '$d')
ENTERED=0; COM_OPEN=0; PF_OPEN=0
case "$META" in
  __EXTRACT_META__*)
    ENTERED=$(printf '%s' "$META" | sed -n 's/.*entered=\([0-9]*\).*/\1/p')
    COM_OPEN=$(printf '%s' "$META" | sed -n 's/.*com=\([0-9]*\).*/\1/p')
    PF_OPEN=$(printf '%s' "$META" | sed -n 's/.*pf=\([0-9]*\).*/\1/p')
    ;;
esac
SEEN=$(printf '%s' "$META" | sed -n 's/.*seen=\([0-9]*\).*/\1/p')
if [ "${COM_OPEN:-0}" -eq 1 ]; then
  echo "REFUSED: the app map has an unterminated HTML comment (<!-- without -->) — checks after it would be silently hidden. Close or remove the comment."
  exit 1
fi
if [ "${PF_OPEN:-0}" -eq 1 ]; then
  echo "REFUSED: the app map's preflight-checks fence is never closed. Add the closing fence."
  exit 1
fi
if [ "${SEEN:-0}" -gt 0 ]; then
  echo "REFUSED: $SEEN preflight-checks fence mention(s) are not a live block (commented out, nested in a documentation fence, indented, or mangled). Fix, uncomment, or delete them so the gate is unambiguous."
  exit 1
fi
if [ -z "$CHECKS" ]; then
  if [ "${ENTERED:-0}" -gt 0 ]; then
    echo "  (preflight-checks block is empty — nothing to verify)"
  else
    echo "  (no preflight-checks block declared in the app map — nothing to verify)"
  fi
  echo "== preflight summary: 0 checks =="
  [ "$DATA_ENV" = "shared" ] && echo "== MUTATION LOCK armed (data_environment: shared) =="
  exit 0
fi

HAVE_DOCKER=""
command -v docker >/dev/null 2>&1 && HAVE_DOCKER=1

trim() { v="$1"; v="${v#"${v%%[![:space:]]*}"}"; v="${v%"${v##*[![:space:]]}"}"; printf '%s' "$v"; }

# --- cmd approval gate: no shell from the map runs without a human ---------------
# cmd targets execute via sh -c. They are enumerated and hashed BEFORE anything
# runs; the approved-set hash lives in .claude/hooks/state/ (gitignored — approval
# is per-clone and can never be committed on anyone else's behalf). The model
# cannot approve: it shows the lines verbatim, asks the user, then re-runs with
# --approve-cmds <hash>. A hash minted against an older map is refused (TOCTOU).
sha() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then shasum -a 256 | awk '{print $1}'
  else cksum | awk '{print $1 "-" $2}'; fi
}
CMD_LIST=$(printf '%s\n' "$CHECKS" | while IFS='|' read -r ctype label target required remedy; do
  ctype=$(trim "${ctype:-}"); target=$(trim "${target:-}"); required=$(trim "${required:-}")
  [ "$ctype" = "cmd" ] || continue
  case "$ctype$required" in *'{{'*) continue ;; esac   # unfilled template line — never executes
  printf '%s\n' "$target"
done)
if [ -n "$CMD_LIST" ]; then
  CMD_HASH=$(printf '%s\n' "$CMD_LIST" | LC_ALL=C sort | sha)
  STATE_DIR=".claude/hooks/state"
  HASH_FILE="$STATE_DIR/live-test-approved-cmds"
  STORED=""
  [ -r "$HASH_FILE" ] && STORED=$(tr -d ' \n\r' < "$HASH_FILE")
  if [ -n "$APPROVE_CMDS" ]; then
    if [ "$APPROVE_CMDS" = "$CMD_HASH" ]; then
      mkdir -p "$STATE_DIR" 2>/dev/null
      printf '%s\n' "$CMD_HASH" > "$HASH_FILE"
      echo "  cmd checks approved for this clone ($CMD_HASH)"
      STORED="$CMD_HASH"
    else
      echo "REFUSED: --approve-cmds hash does not match the map's current cmd lines — the map changed after the commands were shown. Re-run WITHOUT the flag and re-review."
      exit 3
    fi
  fi
  if [ "$STORED" != "$CMD_HASH" ]; then
    echo "== CMD APPROVAL REQUIRED (nothing was executed) =="
    if [ -n "$STORED" ]; then echo "  The map's cmd lines CHANGED since last approved for this clone.";
    else echo "  The map's cmd lines have never been approved for this clone."; fi
    echo "  preflight will run these as shell:"
    n=0
    printf '%s\n' "$CMD_LIST" | while IFS= read -r line; do
      n=$((n+1)); printf '    cmd %s: %s\n' "$n" "$line"
    done
    echo "  approval hash: $CMD_HASH"
    echo "  Show every line above to the user VERBATIM. Only after explicit approval, re-run:"
    echo "    bash \$CLAUDE_SKILL_DIR/scripts/preflight.sh $MAP --approve-cmds $CMD_HASH"
    exit 3
  fi
fi

while IFS='|' read -r ctype label target required remedy; do
  ctype=$(trim "${ctype:-}"); label=$(trim "${label:-}"); target=$(trim "${target:-}"); required=$(trim "${required:-}")
  # skip truly-blank lines and '#' comments; a non-blank line with an empty
  # first field (stray leading '|') is malformed, not blank — fail it loudly
  case "$ctype" in
    '#'*) continue ;;
    '')
      case "$label$target$required$(trim "${remedy:-}")" in
        '') continue ;;
        *) bad "malformed check line (empty type — stray leading '|'?)" "fix the preflight-checks line in $MAP"; continue ;;
      esac ;;
  esac
  # unfilled {{template}} lines — checked on the type and required fields only:
  # labels and cmd targets may legitimately contain '{{' (docker --format
  # '{{.Names}}'); template lines are fully wrapped so ctype always catches them
  case "$ctype$required" in *'{{'*) UNFILLED=$((UNFILLED+1)); continue ;; esac
  [ -n "${remedy:-}" ] || remedy="see app map"

  # fail-closed field validation: a shifted field (a '|' inside a target), an
  # unknown type, or an empty target must be a loud FAIL, never a silent skip
  case "$ctype" in
    http|compose|cmd) ;;
    *) bad "malformed check line (unknown type '$ctype')" "fix the preflight-checks line in $MAP"; continue ;;
  esac
  case "$required" in
    yes|no) ;;
    *) bad "malformed check line '$label' (required must be yes|no, got '$required' — a '|' or stray text inside a field?)" "fix the line in $MAP; use && with a temp file instead of pipes"; continue ;;
  esac
  if [ -z "$target" ]; then
    bad "malformed check line '$label' (empty target)" "fix the preflight-checks line in $MAP"
    continue
  fi

  case "$ctype" in
    http)
      case "$target" in *'{{'*) UNFILLED=$((UNFILLED+1)); continue ;; esac
      if ! is_local_url "$target"; then
        echo "REFUSED: target '$target' is not local. Live tests only run against the local machine."
        exit 1
      fi
      code=$(curl -s -o /dev/null -m 10 -w '%{http_code}' "$target" 2>/dev/null </dev/null); rc=$?
      [ -n "$code" ] || code="000"
      if [ "$rc" -eq 0 ]; then
        case "$code" in
          2*|3*) ok "$label ($target)" ;;
          *)
            [ "$required" = "yes" ] && bad "$label — reachable but returned $code (degraded dependency?): $target" "$remedy" \
                                    || warn "$label — reachable but returned $code (degraded dependency?): $target" "$remedy" ;;
        esac
      else
        case "$code" in
          000|'')
            [ "$required" = "yes" ] && bad "$label — unreachable: $target" "$remedy" \
                                    || warn "$label — unreachable: $target" "$remedy" ;;
          *)
            [ "$required" = "yes" ] && bad "$label — responded $code but the request did not complete (timeout?): $target" "$remedy" \
                                    || warn "$label — responded $code but the request did not complete (timeout?): $target" "$remedy" ;;
        esac
      fi
      ;;
    compose)
      if [ -z "$HAVE_DOCKER" ]; then
        [ "$required" = "yes" ] && bad "$label — docker not installed" "install Docker" \
                                || warn "$label — docker not installed" "install Docker"
      elif ! SVCS=$(bounded docker compose ps --status running --services 2>/dev/null </dev/null); then
        [ "$required" = "yes" ] && bad "$label — docker compose failed (no compose project in $(pwd)?)" "$remedy" \
                                || warn "$label — docker compose failed (no compose project in $(pwd)?)" "$remedy"
      elif printf '%s\n' "$SVCS" | grep -Fqx -- "$target"; then
        ok "$label (compose service '$target' running)"
      else
        [ "$required" = "yes" ] && bad "$label — compose service '$target' not running" "$remedy" \
                                || warn "$label — compose service '$target' not running" "$remedy"
      fi
      ;;
    cmd)
      # Accident-catcher, NOT a security boundary: cmd checks are shell (see
      # TRUST BOUNDARY above) — a map author already has full shell, so no word
      # scan can contain a hostile line. This scan catches an accidental or
      # LLM-generated external URL in otherwise-trusted config: explicit-scheme
      # words anywhere in any command (fail-open on shell metacharacters, so
      # ordinary commands stay unaffected), plus EVERY argument of a curl/wget
      # invocation, where an unverifiable word is refused — fail-closed only in
      # that network-fetch scope.
      remote=""; why=""
      netcmd=""      # '' = ordinary scope · curl/wget = network-fetch scope
      skipval=""     # next word is the value of an option that never takes a URL
      urlnext=""     # next word is the argument of curl --url
      set -f         # word-splitting only — never glob-expand (`ls *.py`)
      for word in $target; do
        lw=$(printf '%s' "$word" | tr '[:upper:]' '[:lower:]')
        if [ -n "$skipval" ]; then skipval=""; continue; fi
        case "$lw" in
          '&&'|'||'|';'|'|'|'&') netcmd=""; urlnext=""; continue ;;
        esac
        if [ -n "$urlnext" ]; then urlnext=""; scan_url_word "$word" "$lw"; continue; fi
        case "$lw" in
          # Explicit scheme — scanned in EVERY command.
          http://*|https://*|ftp://*|ftps://*|scp://*|sftp://*|ssh://*)
            is_local_url "$lw" || remote=1
            case "$lw" in *\;) netcmd="" ;; esac
            continue ;;
        esac
        if [ -z "$netcmd" ]; then
          case "$lw" in curl|wget) netcmd="$lw" ;; esac
          continue
        fi
        # -- inside a curl/wget invocation --
        case "$netcmd:$word" in
          curl:-K|curl:--config|curl:--config=*)
            remote=1; why="— curl -K/--config reads its URLs from a file this gate cannot see; use inline http checks instead"; continue ;;
          wget:-i|wget:--input-file|wget:--input-file=*)
            remote=1; why="— wget -i/--input-file reads its URLs from a file this gate cannot see; use inline http checks instead"; continue ;;
        esac
        case "$word" in
          --url) urlnext=1; continue ;;
          --url=*) ;;                    # value attached — scanned below
          -*=*) continue ;;              # --opt=value: only --url= carries a URL
          -o|-d|-H|-F|-T|-A|-e|-b|-c|-u|-E|-K|-m|-X|--request|--data*|--header|--output|--config|--cookie*|--user*|--referer|--cert|--key|--cacert|--form|--upload-file|--retry*|--max-time)
            skipval=1; continue ;;       # value is never a fetched URL
          -*) continue ;;                # option taking no value
        esac
        scan_url_word "$word" "$lw"
      done
      set +f
      if [ -n "$remote" ]; then
        echo "REFUSED: check '$label' ${why:-targets a non-local URL}. Live tests only run against the local machine."
        exit 1
      fi
      bounded sh -c "$target" </dev/null >/dev/null 2>&1; rc=$?
      if [ "$rc" -eq 0 ]; then
        ok "$label"
      elif [ "$rc" -eq 124 ] && [ -n "$HAVE_TIMEOUT" ]; then
        [ "$required" = "yes" ] && bad "$label — command timed out after 30s: $target" "$remedy" \
                                || warn "$label — command timed out after 30s: $target" "$remedy"
      else
        [ "$required" = "yes" ] && bad "$label — command failed: $target" "$remedy" \
                                || warn "$label — command failed: $target" "$remedy"
      fi
      ;;
  esac
done <<EOF
$CHECKS
EOF

if [ "$UNFILLED" -gt 0 ]; then
  printf "  FAIL  %s unfilled {{template}} check line(s) skipped — the app map is not filled in\n        remedy: complete %s (see the /live-test first-run interview)\n" "$UNFILLED" "$MAP"
  FAIL=$((FAIL+UNFILLED))
fi

echo "== preflight summary: $PASS pass / $FAIL fail / $WARN warn =="
[ "$DATA_ENV" = "shared" ] && echo "== MUTATION LOCK armed (data_environment: shared) =="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
