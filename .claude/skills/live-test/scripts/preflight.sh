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
#       malformed/unfilled, a non-local target was seen, or a declared block could
#       not be extracted · 2 = app map missing/unreadable (run the interview).
set -uo pipefail

MAP="${1:-docs/testing/APP_MAP.md}"

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
  exit 0
fi

HAVE_DOCKER=""
command -v docker >/dev/null 2>&1 && HAVE_DOCKER=1

trim() { v="$1"; v="${v#"${v%%[![:space:]]*}"}"; v="${v%"${v##*[![:space:]]}"}"; printf '%s' "$v"; }

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
      # containment note, not a guarantee: cmd checks are shell (see TRUST
      # BOUNDARY above). This guard only catches obvious remote http(s) URLs.
      remote=""
      for word in $target; do
        lw=$(printf '%s' "$word" | tr '[:upper:]' '[:lower:]')
        case "$lw" in
          # Explicit scheme.
          http://*|https://*|ftp://*|ftps://*|scp://*|sftp://*|ssh://*)
            is_local_url "$lw" || remote=1 ;;
          # Scheme-LESS host arguments. curl/wget default to http://, so
          # `curl evil.example.com/x` would otherwise slip past a check that
          # only inspects http(s):// words. Treat any bare word that looks
          # like a host (dotted name or user@host) as a URL and test it.
          -*|/*|./*|../*|'')
            ;;
          *@*|*.*)
            case "$lw" in
              *[!a-z0-9.:@_/-]*) ;;   # has shell/path metachars: not a bare host
              *) is_local_url "http://${lw#*@}" || remote=1 ;;
            esac ;;
        esac
      done
      if [ -n "$remote" ]; then
        echo "REFUSED: check '$label' targets a non-local URL. Live tests only run against the local machine."
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
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
