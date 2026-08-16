<!-- GENERATED FILE — do not edit. Source: flow.yaml (spec 1). -->
<!-- Regenerate: bash .claude/skills/doctor/scripts/render-flow.sh --write -->

# sprint-end — generated flow view

```mermaid
flowchart TD
  init["init"]
  discover_sprint_state["discover sprint state"]
  default_branch_gate{{"default branch gate"}}
  no_commits_gate{{"no commits gate"}}
  child_streams_gate{{"child streams gate"}}
  smoke_test_offer(["smoke test offer 👤"])
  gate_selection(["gate selection 👤"])
  quality_agent_dispatch["quality agent dispatch"]
  quality_hard_gate{{"quality hard gate"}}
  fix_quality_issues["fix quality issues"]
  uat_coverage_check["uat coverage check"]
  documentation_updates["documentation updates"]
  prd_review["prd review"]
  persona_update["persona update"]
  commit_doc_artifacts["commit doc artifacts"]
  pr_size_check(["pr size check 👤"])
  split_pr["split pr"]
  push_create_pr["push create pr"]
  ci_configured_router{"ci configured router"}
  wait_for_ci{{"wait for ci"}}
  fix_ci_failures["fix ci failures"]
  review_required_router{"review required router"}
  human_review_gate(["human review gate 👤"])
  merge_cleanup["merge cleanup"]
  sprint_complete(("sprint complete"))
  init --> discover_sprint_state
  discover_sprint_state --> default_branch_gate
  default_branch_gate -->|ok| no_commits_gate
  stop1(("STOP"))
  default_branch_gate -->|fail| stop1
  no_commits_gate -->|ok| child_streams_gate
  stop2(("STOP"))
  no_commits_gate -->|fail| stop2
  child_streams_gate -->|ok| smoke_test_offer
  stop3(("STOP"))
  child_streams_gate -->|fail| stop3
  smoke_test_offer -->|ok| gate_selection
  gate_selection -->|ok| quality_agent_dispatch
  quality_agent_dispatch --> quality_hard_gate
  quality_hard_gate -->|ok| uat_coverage_check
  quality_hard_gate -->|fail| fix_quality_issues
  fix_quality_issues --> quality_agent_dispatch
  uat_coverage_check --> documentation_updates
  documentation_updates --> prd_review
  prd_review --> persona_update
  persona_update --> commit_doc_artifacts
  commit_doc_artifacts --> pr_size_check
  pr_size_check -->|ok| push_create_pr
  pr_size_check -->|fail| split_pr
  split_pr --> ci_configured_router
  push_create_pr --> ci_configured_router
  ci_configured_router -->|ci-configured| wait_for_ci
  ci_configured_router -->|default| review_required_router
  wait_for_ci -->|ok| review_required_router
  wait_for_ci -->|fail| fix_ci_failures
  fix_ci_failures --> wait_for_ci
  review_required_router -->|review-required| human_review_gate
  review_required_router -->|default| merge_cleanup
  human_review_gate -->|ok| merge_cleanup
  human_review_gate -->|fail| human_review_gate
  merge_cleanup --> sprint_complete
  sprint_complete -.->|next skill| nsk_retrospective
  nsk_retrospective(["/retrospective"])
  sprint_complete -.->|next skill| nsk_sprint_start
  nsk_sprint_start(["/sprint-start"])
  sprint_complete -.->|next skill| nsk_handoff
  nsk_handoff(["/handoff"])
```

## Edges

| From | Edge | To |
|------|------|----|
| init | next | discover_sprint_state |
| discover_sprint_state | next | default_branch_gate |
| default_branch_gate | ok | no_commits_gate |
| default_branch_gate | fail | stop1 |
| no_commits_gate | ok | child_streams_gate |
| no_commits_gate | fail | stop2 |
| child_streams_gate | ok | smoke_test_offer |
| child_streams_gate | fail | stop3 |
| smoke_test_offer | ok | gate_selection |
| gate_selection | ok | quality_agent_dispatch |
| quality_agent_dispatch | next | quality_hard_gate |
| quality_hard_gate | ok | uat_coverage_check |
| quality_hard_gate | fail | fix_quality_issues |
| fix_quality_issues | next | quality_agent_dispatch |
| uat_coverage_check | next | documentation_updates |
| documentation_updates | next | prd_review |
| prd_review | next | persona_update |
| persona_update | next | commit_doc_artifacts |
| commit_doc_artifacts | next | pr_size_check |
| pr_size_check | ok | push_create_pr |
| pr_size_check | fail | split_pr |
| split_pr | next | ci_configured_router |
| push_create_pr | next | ci_configured_router |
| ci_configured_router | ci-configured | wait_for_ci |
| ci_configured_router | default | review_required_router |
| wait_for_ci | ok | review_required_router |
| wait_for_ci | fail | fix_ci_failures |
| fix_ci_failures | next | wait_for_ci |
| review_required_router | review-required | human_review_gate |
| review_required_router | default | merge_cleanup |
| human_review_gate | ok | merge_cleanup |
| human_review_gate | fail | human_review_gate |
| merge_cleanup | next | sprint_complete |
| sprint_complete | next skill | nsk_retrospective |
| sprint_complete | next skill | nsk_sprint_start |
| sprint_complete | next skill | nsk_handoff |

Start node: `init`
