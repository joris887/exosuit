#!/usr/bin/env bash
set -euo pipefail

# render-flow.sh — Generate flow views (mermaid + edge table) from flow.yaml
# Usage: bash render-flow.sh [--write | --check] [<skill-name>]
#
# Default: print the generated view for <skill-name> (or all flows) to stdout.
#   --write  Write/update .claude/skills/<skill>/flow.generated.md per flow
#   --check  Exit 1 if any flow.generated.md is missing or stale (CI drift
#            guard — the generated view can never rot behind flow.yaml)
#
# Output is DETERMINISTIC (no timestamps): same flow.yaml -> same bytes.
# The generated file replaces hand-maintained diagrams for adopting skills:
# regenerate instead of editing (see FLOW_SPEC.md → Generated Views).

if [[ "${1:-}" == "--help" ]]; then
  sed -n '4,14p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
fi

MODE="stdout"
case "${1:-}" in
  --write) MODE="write"; shift ;;
  --check) MODE="check"; shift ;;
esac
ONLY="${1:-}"

SKILLS_DIR=".claude/skills"
stale=0
rendered=0

render_one() {
  local flow_file="$1"
  local skill_name
  skill_name=$(basename "$(dirname "$flow_file")")

  # Parse node lines exactly like validate-flows.sh
  local node_lines
  node_lines=$(grep -E '^  [a-z0-9][a-z0-9-]*: \{.*\}[[:space:]]*$' "$flow_file" || true)
  [[ -n "$node_lines" ]] || return 0
  local start_node
  start_node=$(awk 'sub(/^start:[ \t]*/, "") {print; exit}' "$flow_file")

  printf '<!-- GENERATED FILE — do not edit. Source: flow.yaml (spec 1). -->\n'
  printf '<!-- Regenerate: bash .claude/skills/doctor/scripts/render-flow.sh --write -->\n\n'
  printf '# %s — generated flow view\n\n' "$skill_name"
  printf '```mermaid\nflowchart TD\n'

  # Nodes: shape by type
  local stopn=0
  local edge_buf=""
  while IFS= read -r line; do
    local id body body_clean ntype label mid
    id=$(printf '%s' "$line" | sed -E 's/^  ([a-z0-9-]+):.*/\1/')
    body=$(printf '%s' "$line" | sed -E 's/^  [a-z0-9-]+: \{(.*)\}[[:space:]]*$/\1/')
    body_clean=$(printf '%s' "$body" | sed -E 's/(doc|profile): "[^"]*"//g')
    ntype=$(printf '%s' "$body_clean" | sed -n 's/.*type: \([a-z.]*\).*/\1/p')
    mid=$(printf '%s' "$id" | tr '-' '_')
    label=$(printf '%s' "$id" | tr '-' ' ')
    case "$ntype" in
      step)       printf '  %s["%s"]\n' "$mid" "$label" ;;
      router)     printf '  %s{"%s"}\n' "$mid" "$label" ;;
      gate.hard)  printf '  %s{{"%s"}}\n' "$mid" "$label" ;;
      gate.human) printf '  %s(["%s 👤"])\n' "$mid" "$label" ;;
      loop)       printf '  %s[/"%s"/]\n' "$mid" "$label" ;;
      fanout|join) printf '  %s[["%s"]]\n' "$mid" "$label" ;;
      terminal)   printf '  %s(("%s"))\n' "$mid" "$label" ;;
      *)          printf '  %s["%s"]\n' "$mid" "$label" ;;
    esac

    # Edges: strip quoted attrs and lists, then key: value pairs
    local list_vals lkey
    list_vals=$(printf '%s' "$body_clean" | sed -En 's/.*(to|next_skill): \[([^]]*)\].*/\1=\2/p')
    body_clean=$(printf '%s' "$body_clean" | sed -E 's/(to|next_skill): \[[^]]*\]//g')
    while IFS= read -r pair; do
      local key val
      key=$(printf '%s' "$pair" | sed -E 's/^ *([a-z_-]+):.*/\1/')
      val=$(printf '%s' "$pair" | sed -E 's/^ *[a-z_-]+: *//; s/ *$//')
      [[ -z "$key" || -z "$val" ]] && continue
      case "$key" in type|max|require|evidence) continue ;; esac
      if [[ "$key" == "next_skill" ]]; then
        edge_buf="${edge_buf}  ${mid} -.->|next skill| nsk_$(printf '%s' "$val" | tr '-' '_')\n"
        edge_buf="${edge_buf}  nsk_$(printf '%s' "$val" | tr '-' '_')([\"/${val}\"])\n"
        continue
      fi
      if [[ "$val" == "STOP" ]]; then
        stopn=$((stopn + 1))
        edge_buf="${edge_buf}  stop${stopn}((\"STOP\"))\n"
        if [[ "$key" == "next" ]]; then
          edge_buf="${edge_buf}  ${mid} --> stop${stopn}\n"
        else
          edge_buf="${edge_buf}  ${mid} -->|${key}| stop${stopn}\n"
        fi
      elif [[ "$key" == "next" ]]; then
        edge_buf="${edge_buf}  ${mid} --> $(printf '%s' "$val" | tr '-' '_')\n"
      else
        edge_buf="${edge_buf}  ${mid} -->|${key}| $(printf '%s' "$val" | tr '-' '_')\n"
      fi
    done < <(printf '%s\n' "$body_clean" | tr ',' '\n')
    if [[ -n "$list_vals" ]]; then
      lkey="${list_vals%%=*}"
      while IFS= read -r lval; do
        lval=$(printf '%s' "$lval" | sed 's/^ *//; s/ *$//')
        [[ -z "$lval" ]] && continue
        if [[ "$lkey" == "next_skill" ]]; then
          edge_buf="${edge_buf}  ${mid} -.->|next skill| nsk_$(printf '%s' "$lval" | tr '-' '_')\n"
          edge_buf="${edge_buf}  nsk_$(printf '%s' "$lval" | tr '-' '_')([\"/${lval}\"])\n"
        else
          edge_buf="${edge_buf}  ${mid} --> $(printf '%s' "$lval" | tr '-' '_')\n"
        fi
      done < <(printf '%s\n' "${list_vals#*=}" | tr ',' '\n')
    fi
  done <<< "$node_lines"

  printf '%b' "$edge_buf"
  printf '```\n\n'

  # Edge table (grep-friendly adjacency listing)
  printf '## Edges\n\n'
  printf '| From | Edge | To |\n|------|------|----|\n'
  printf '%b' "$edge_buf" | sed -n 's/^  \([a-z0-9_]*\) -\{1,2\}\.\{0,1\}->\(|\([a-z_ -]*\)|\)\{0,1\} \([a-zA-Z0-9_]*\)$/| \1 | \3 | \4 |/p' | sed 's/|  |/| next |/'
  printf '\nStart node: `%s`\n' "$start_node"
}

for flow_file in "$SKILLS_DIR"/*/flow.yaml; do
  [[ -f "$flow_file" ]] || continue
  skill=$(basename "$(dirname "$flow_file")")
  [[ -n "$ONLY" && "$skill" != "$ONLY" ]] && continue
  rendered=$((rendered + 1))
  out_file="$(dirname "$flow_file")/flow.generated.md"
  case "$MODE" in
    stdout)
      render_one "$flow_file"
      ;;
    write)
      render_one "$flow_file" > "$out_file"
      echo "wrote $out_file" >&2
      ;;
    check)
      if [[ ! -f "$out_file" ]] || ! render_one "$flow_file" | cmp -s - "$out_file"; then
        echo "STALE: $out_file does not match flow.yaml — run render-flow.sh --write" >&2
        stale=1
      fi
      ;;
  esac
done

if [[ "$MODE" == "check" ]]; then
  if [[ "$stale" -eq 1 ]]; then exit 1; fi
  echo "generated views current ($rendered flows)" >&2
fi
exit 0
