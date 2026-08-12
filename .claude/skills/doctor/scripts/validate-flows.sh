#!/usr/bin/env bash
set -euo pipefail

# validate-flows.sh — Check flow contracts (flow.yaml) against FLOW_SPEC.md
# Usage: bash validate-flows.sh [--verbose]

if [[ "${1:-}" == "--help" ]]; then
  echo "Usage: bash validate-flows.sh [--verbose]"
  echo ""
  echo "Validates all .claude/skills/*/flow.yaml files against the flow spec:"
  echo "  - flow name matches skill directory; supported spec version"
  echo "  - node lines parse; ids kebab-case and unique; types known"
  echo "  - required attrs per node type; edge targets resolve (or STOP)"
  echo "  - at least one terminal; all nodes reachable; no trap regions"
  echo "  - cycles carry a max bound or a gate (WARN otherwise)"
  echo "  - doc anchors exist verbatim as whole lines in SKILL.md"
  echo ""
  echo "A project with no flow.yaml files passes vacuously."
  echo ""
  echo "Options:"
  echo "  --verbose  Show detailed output for each check"
  exit 0
fi

VERBOSE=false
[[ "${1:-}" == "--verbose" ]] && VERBOSE=true

SKILLS_DIR=".claude/skills"
SPEC_VERSION="1"
NODE_TYPES="step gate.hard gate.human router loop fanout join terminal"

pass=0
warn=0
fail=0
total=0

report() {
  local status="$1" flow="$2" msg="$3"
  case "$status" in
    PASS) pass=$((pass + 1)) ; if $VERBOSE; then echo "  PASS  $flow: $msg"; fi ;;
    WARN) warn=$((warn + 1)) ; echo "  WARN  $flow: $msg" ;;
    FAIL) fail=$((fail + 1)) ; echo "  FAIL  $flow: $msg" ;;
  esac
}

echo "Flow Contract Validation"
echo "========================"
echo ""

for flow_file in "$SKILLS_DIR"/*/flow.yaml; do
  [[ -f "$flow_file" ]] || continue
  total=$((total + 1))

  skill_dir=$(dirname "$flow_file")
  skill_name=$(basename "$skill_dir")
  skill_md="$skill_dir/SKILL.md"

  # CRLF files would fail every check with confusing messages — one clear FAIL
  if grep -q "$(printf '\r')" "$flow_file"; then
    report FAIL "$skill_name" "file has CRLF line endings (convert to LF)"
    continue
  fi

  # --- 1. Top-level keys ---
  # awk reads the file directly (no pipe) — a sed|head pipeline can die of
  # SIGPIPE under pipefail
  flow_name=$(awk 'sub(/^flow:[ \t]*/, "") {print; exit}' "$flow_file")
  spec_ver=$(awk 'sub(/^spec:[ \t]*/, "") {print; exit}' "$flow_file")
  start_node=$(awk 'sub(/^start:[ \t]*/, "") {print; exit}' "$flow_file")

  if [[ "$flow_name" == "$skill_name" ]]; then
    report PASS "$skill_name" "flow name matches directory"
  else
    report FAIL "$skill_name" "flow name '$flow_name' does not match directory '$skill_name'"
  fi

  if [[ "$spec_ver" == "$SPEC_VERSION" ]]; then
    report PASS "$skill_name" "spec version $spec_ver"
  else
    report FAIL "$skill_name" "unsupported spec version '$spec_ver' (expected $SPEC_VERSION)"
  fi

  # --- 2. Parse node lines ---
  # Node lines: exactly two-space indent, "id: {attrs}"
  node_lines=$(grep -E '^  [a-z0-9][a-z0-9-]*: \{.*\}[[:space:]]*$' "$flow_file" || true)
  # Any indented non-comment line that is NOT a valid node line is a parse
  # error — this also catches wrong indent (1/4 spaces, tabs) and bad ids
  bad_lines=$(grep -E '^[[:space:]]+[^#[:space:]]' "$flow_file" | grep -Evc '^  [a-z0-9][a-z0-9-]*: \{.*\}[[:space:]]*$' || true)
  if [[ "$bad_lines" -gt 0 ]]; then
    report FAIL "$skill_name" "$bad_lines node line(s) do not parse (want '  id: {type: ..., ...}')"
  fi

  if [[ -z "$node_lines" ]]; then
    report FAIL "$skill_name" "no nodes found"
    continue
  fi

  node_ids=$(printf '%s\n' "$node_lines" | sed -E 's/^  ([a-z0-9-]+):.*/\1/')

  # --- 3. Duplicate ids ---
  dups=$(printf '%s\n' "$node_ids" | sort | uniq -d)
  if [[ -n "$dups" ]]; then
    report FAIL "$skill_name" "duplicate node ids: $(echo "$dups" | tr '\n' ' ')"
  else
    report PASS "$skill_name" "node ids unique ($(printf '%s\n' "$node_ids" | wc -l | tr -d ' ') nodes)"
  fi

  # --- 4. start resolves ---
  if [[ -n "$start_node" ]] && printf '%s\n' "$node_ids" | grep -qxF -- "$start_node"; then
    report PASS "$skill_name" "start node '$start_node' resolves"
  else
    report FAIL "$skill_name" "start node '$start_node' does not resolve"
    continue
  fi

  # --- 5. Per-node checks; build edge list for graph analysis ---
  # edges file lines: "from to"; nodes file lines: "id type has_max"
  edges_tmp=$(mktemp)
  nodes_tmp=$(mktemp)
  no_doc=0
  terminals=0

  while IFS= read -r line; do
    id=$(printf '%s' "$line" | sed -E 's/^  ([a-z0-9-]+):.*/\1/')
    body=$(printf '%s' "$line" | sed -E 's/^  [a-z0-9-]+: \{(.*)\}[[:space:]]*$/\1/')

    # Extract and strip quoted attrs (doc, profile) before splitting on commas
    doc=$(printf '%s' "$body" | sed -n 's/.*doc: "\([^"]*\)".*/\1/p')
    body_clean=$(printf '%s' "$body" | sed -E 's/(doc|profile): "[^"]*"//g')
    # Extract bracketed lists (fanout to / terminal next_skill), then strip them
    list_attr=$(printf '%s' "$body_clean" | sed -En 's/.*(to|next_skill): \[([^]]*)\].*/\1=\2/p')
    body_clean=$(printf '%s' "$body_clean" | sed -E 's/(to|next_skill): \[[^]]*\]//g')

    ntype=$(printf '%s' "$body_clean" | sed -n 's/.*type: \([a-z.]*\).*/\1/p')
    has_max="no"
    printf '%s' "$body_clean" | grep -Eq 'max: [0-9]+' && has_max="yes"

    if ! printf '%s\n' $NODE_TYPES | grep -qxF -- "$ntype"; then
      report FAIL "$skill_name" "node '$id': unknown type '$ntype'"
      continue
    fi
    echo "$id $ntype $has_max" >> "$nodes_tmp"
    [[ "$ntype" == "terminal" ]] && terminals=$((terminals + 1))
    [[ -z "$doc" ]] && no_doc=$((no_doc + 1))

    # doc anchor must exist verbatim as a whole line in SKILL.md
    # ('--' guards anchors that start with '-')
    if [[ -n "$doc" ]]; then
      if [[ -f "$skill_md" ]] && grep -qxF -- "$doc" "$skill_md"; then
        report PASS "$skill_name" "node '$id': doc anchor found"
      else
        report FAIL "$skill_name" "node '$id': doc anchor not found in SKILL.md: \"$doc\""
      fi
    fi

    # Collect edges: every remaining "key: value" except type/max/require
    attrs_seen=""
    while IFS= read -r pair; do
      key=$(printf '%s' "$pair" | sed -E 's/^ *([a-z_-]+):.*/\1/')
      val=$(printf '%s' "$pair" | sed -E 's/^ *[a-z_-]+: *//; s/ *$//')
      [[ -z "$key" || -z "$val" ]] && continue
      case "$key" in
        type|max|require) continue ;;
      esac
      attrs_seen="$attrs_seen $key"
      if [[ "$key" == "next_skill" ]]; then
        # id-shape check first: '..', '.', 'a/b' must not pass the -d test
        if [[ "$val" =~ ^[a-z0-9][a-z0-9-]*$ && -d "$SKILLS_DIR/$val" ]]; then
          report PASS "$skill_name" "node '$id': next_skill '$val' exists"
        else
          report FAIL "$skill_name" "node '$id': next_skill '$val' is not a skill"
        fi
        continue
      fi
      echo "$id $val" >> "$edges_tmp"
    done < <(printf '%s\n' "$body_clean" | tr ',' '\n')

    # List attrs (to / next_skill lists)
    fanout_targets=0
    if [[ -n "$list_attr" ]]; then
      lkey="${list_attr%%=*}"
      lvals=$(printf '%s' "${list_attr#*=}" | tr ',' '\n' | sed 's/^ *//; s/ *$//')
      while IFS= read -r lval; do
        [[ -z "$lval" ]] && continue
        if [[ "$lkey" == "next_skill" ]]; then
          if [[ "$lval" =~ ^[a-z0-9][a-z0-9-]*$ && -d "$SKILLS_DIR/$lval" ]]; then
            report PASS "$skill_name" "node '$id': next_skill '$lval' exists"
          else
            report FAIL "$skill_name" "node '$id': next_skill '$lval' is not a skill"
          fi
        else
          echo "$id $lval" >> "$edges_tmp"
          attrs_seen="$attrs_seen to"
          fanout_targets=$((fanout_targets + 1))
        fi
      done <<< "$lvals"
    fi

    # Required attrs per type (including spec cardinality: router needs a
    # named edge besides default; fanout needs >=2 targets)
    missing=""
    case "$ntype" in
      step)      printf '%s' "$attrs_seen" | grep -qw next || missing="next" ;;
      gate.hard) printf '%s' "$attrs_seen" | grep -qw ok || missing="ok"
                 printf '%s' "$attrs_seen" | grep -qw fail || missing="$missing fail" ;;
      gate.human) printf '%s' "$attrs_seen" | grep -qw ok || missing="ok" ;;
      router)    printf '%s' "$attrs_seen" | grep -qw default || missing="default"
                 named_edges=0
                 for a in $attrs_seen; do [[ "$a" != "default" ]] && named_edges=$((named_edges + 1)); done
                 (( named_edges >= 1 )) || missing="$missing <a named edge>" ;;
      loop)      printf '%s' "$attrs_seen" | grep -qw back || missing="back"
                 printf '%s' "$attrs_seen" | grep -qw done || missing="$missing done"
                 [[ "$has_max" == "yes" ]] || missing="$missing max" ;;
      fanout)    (( fanout_targets >= 2 )) || missing="to (list of >=2 ids)" ;;
      join)      printf '%s' "$attrs_seen" | grep -qw next || missing="next" ;;
    esac
    if [[ -n "$missing" ]]; then
      report FAIL "$skill_name" "node '$id' ($ntype): missing required attr(s):$missing"
    fi
  done <<< "$node_lines"

  # --- 6. Edge targets resolve ---
  unresolved=0
  while read -r from to; do
    [[ -z "$to" ]] && continue
    [[ "$to" == "STOP" ]] && continue
    if ! printf '%s\n' "$node_ids" | grep -qxF -- "$to"; then
      report FAIL "$skill_name" "edge '$from' -> '$to': target does not resolve"
      unresolved=$((unresolved + 1))
    fi
  done < "$edges_tmp"
  [[ "$unresolved" -eq 0 ]] && report PASS "$skill_name" "all edge targets resolve"

  # --- 7. Terminals ---
  if [[ "$terminals" -ge 1 ]]; then
    report PASS "$skill_name" "$terminals terminal node(s)"
  else
    report FAIL "$skill_name" "no terminal node"
  fi

  # --- 8. Graph analysis (reachability, trap regions, unbounded cycles) ---
  # awk builds a boolean transitive closure (Floyd-Warshall over node ids +
  # STOP) and prints findings; the shell turns them into reports.
  if [[ "$unresolved" -eq 0 && "$terminals" -ge 1 ]]; then
    graph_out=$(awk -v start="$start_node" '
      NR == FNR { id[$1] = 1; type[$1] = $2; hasmax[$1] = $3; n++; order[n] = $1; next }
      { adj[$1 "," $2] = 1 }
      END {
        id["STOP"] = 1; order[++n] = "STOP"
        for (k = 1; k <= n; k++)
          for (i = 1; i <= n; i++) {
            if (!adj[order[i] "," order[k]]) continue
            for (j = 1; j <= n; j++)
              if (adj[order[k] "," order[j]]) adj[order[i] "," order[j]] = 1
          }
        for (i = 1; i <= n; i++) {
          v = order[i]
          if (v == "STOP") continue
          reachable = (v == start || adj[start "," v])
          if (!reachable) { print "UNREACHABLE " v; continue }
          ok = (type[v] == "terminal")
          if (!ok) for (j = 1; j <= n; j++) {
            t = order[j]
            if (adj[v "," t] && (t == "STOP" || type[t] == "terminal")) { ok = 1; break }
          }
          if (!ok) print "TRAPPED " v
          if (adj[v "," v]) {
            incycle[v] = 1
            if (hasmax[v] == "yes" || type[v] == "gate.hard" || type[v] == "gate.human") bounded[v] = 1
          }
        }
        # Warn once per cycle (via its lexicographically-smallest member),
        # not once per member — a 5-node cycle is one problem, not five.
        for (v in incycle) {
          guarded = 0; rep = v
          for (w in incycle) {
            mutual = (v == w || (adj[v "," w] && adj[w "," v]))
            if (mutual && bounded[w]) { guarded = 1; break }
            if (mutual && w < rep) rep = w
          }
          if (!guarded && rep == v) print "UNBOUNDED " v
        }
      }
    ' "$nodes_tmp" "$edges_tmp" | sort | uniq)
    while read -r kind node; do
      [[ -z "$kind" ]] && continue
      case "$kind" in
        UNREACHABLE) report WARN "$skill_name" "node '$node' unreachable from start" ;;
        TRAPPED)     report FAIL "$skill_name" "node '$node' cannot reach a terminal or STOP (trap region)" ;;
        UNBOUNDED)   report WARN "$skill_name" "node '$node' is in a cycle with no max bound or gate" ;;
      esac
    done <<< "$graph_out"
    if [[ -z "$graph_out" ]]; then
      report PASS "$skill_name" "graph sound: all nodes reachable, no trap regions, cycles bounded"
    fi
  fi

  # --- 9. Missing doc anchors (summary) ---
  if [[ "$no_doc" -gt 0 ]]; then
    report WARN "$skill_name" "$no_doc node(s) lack a doc anchor"
  else
    report PASS "$skill_name" "all nodes carry doc anchors"
  fi

  rm -f "$edges_tmp" "$nodes_tmp"
done

echo ""
echo "========================"
echo "Flows checked: $total"
echo "Results: $pass passed, $warn warnings, $fail failures"
echo ""
if (( fail > 0 )); then
  echo "Overall: ACTION REQUIRED"
  exit 1
elif (( warn > 0 )); then
  echo "Overall: NEEDS ATTENTION"
  exit 0
else
  echo "Overall: ALL CONFORMANT"
  exit 0
fi
