<!-- GENERATED FILE — do not edit. Source: flow.yaml (spec 1). -->
<!-- Regenerate: bash .claude/skills/doctor/scripts/render-flow.sh --write -->

# sprint-start — generated flow view

```mermaid
flowchart TD
  emit_start_event["emit start event"]
  read_profile["read profile"]
  check_open_prs["check open prs"]
  open_pr_router{"open pr router"}
  merge_approved_prs["merge approved prs"]
  remaining_awaiting_router{"remaining awaiting router"}
  awaiting_review_gate(["awaiting review gate 👤"])
  verify_clean_tree{{"verify clean tree"}}
  sync_default_branch["sync default branch"]
  verify_tests_pass{{"verify tests pass"}}
  metrics_health_check["metrics health check"]
  debt_check_router{"debt check router"}
  debt_health_check["debt health check"]
  determine_sprint_number["determine sprint number"]
  branch_mode_router{"branch mode router"}
  create_branch["create branch"]
  create_worktree["create worktree"]
  draft_pr_router{"draft pr router"}
  draft_pr_offer(["draft pr offer 👤"])
  create_draft_pr["create draft pr"]
  show_upcoming_stories["show upcoming stories"]
  ready_stories_router{"ready stories router"}
  no_ready_stories_gate(["no ready stories gate 👤"])
  define_sprint_goal(["define sprint goal 👤"])
  prd_summary_router{"prd summary router"}
  derive_sprint_dod["derive sprint dod"]
  create_sprint_spec["create sprint spec"]
  update_progress["update progress"]
  done(("done"))
  emit_start_event --> read_profile
  read_profile --> check_open_prs
  check_open_prs --> open_pr_router
  open_pr_router -->|approved| merge_approved_prs
  open_pr_router -->|awaiting-review| awaiting_review_gate
  open_pr_router -->|default| verify_clean_tree
  merge_approved_prs --> remaining_awaiting_router
  remaining_awaiting_router -->|awaiting-review| awaiting_review_gate
  remaining_awaiting_router -->|default| verify_clean_tree
  awaiting_review_gate -->|ok| verify_clean_tree
  stop1(("STOP"))
  awaiting_review_gate -->|fail| stop1
  verify_clean_tree -->|ok| sync_default_branch
  stop2(("STOP"))
  verify_clean_tree -->|fail| stop2
  sync_default_branch --> verify_tests_pass
  verify_tests_pass -->|ok| metrics_health_check
  stop3(("STOP"))
  verify_tests_pass -->|fail| stop3
  metrics_health_check --> debt_check_router
  debt_check_router -->|debt-active| debt_health_check
  debt_check_router -->|default| determine_sprint_number
  debt_health_check --> determine_sprint_number
  determine_sprint_number --> branch_mode_router
  branch_mode_router -->|worktree| create_worktree
  branch_mode_router -->|default| create_branch
  create_branch --> draft_pr_router
  create_worktree --> draft_pr_router
  draft_pr_router -->|ci-available| draft_pr_offer
  draft_pr_router -->|default| show_upcoming_stories
  draft_pr_offer -->|ok| create_draft_pr
  draft_pr_offer -->|fail| show_upcoming_stories
  create_draft_pr --> show_upcoming_stories
  show_upcoming_stories --> ready_stories_router
  ready_stories_router -->|no-ready-stories| no_ready_stories_gate
  ready_stories_router -->|default| define_sprint_goal
  no_ready_stories_gate -->|ok| define_sprint_goal
  stop4(("STOP"))
  no_ready_stories_gate -->|fail| stop4
  define_sprint_goal -->|ok| prd_summary_router
  prd_summary_router -->|prd-exists| derive_sprint_dod
  prd_summary_router -->|default| create_sprint_spec
  derive_sprint_dod --> create_sprint_spec
  create_sprint_spec --> update_progress
  update_progress --> done
  done -.->|next skill| nsk_story_cycle
  nsk_story_cycle(["/story-cycle"])
```

## Edges

| From | Edge | To |
|------|------|----|
| emit_start_event | next | read_profile |
| read_profile | next | check_open_prs |
| check_open_prs | next | open_pr_router |
| open_pr_router | approved | merge_approved_prs |
| open_pr_router | awaiting-review | awaiting_review_gate |
| open_pr_router | default | verify_clean_tree |
| merge_approved_prs | next | remaining_awaiting_router |
| remaining_awaiting_router | awaiting-review | awaiting_review_gate |
| remaining_awaiting_router | default | verify_clean_tree |
| awaiting_review_gate | ok | verify_clean_tree |
| awaiting_review_gate | fail | stop1 |
| verify_clean_tree | ok | sync_default_branch |
| verify_clean_tree | fail | stop2 |
| sync_default_branch | next | verify_tests_pass |
| verify_tests_pass | ok | metrics_health_check |
| verify_tests_pass | fail | stop3 |
| metrics_health_check | next | debt_check_router |
| debt_check_router | debt-active | debt_health_check |
| debt_check_router | default | determine_sprint_number |
| debt_health_check | next | determine_sprint_number |
| determine_sprint_number | next | branch_mode_router |
| branch_mode_router | worktree | create_worktree |
| branch_mode_router | default | create_branch |
| create_branch | next | draft_pr_router |
| create_worktree | next | draft_pr_router |
| draft_pr_router | ci-available | draft_pr_offer |
| draft_pr_router | default | show_upcoming_stories |
| draft_pr_offer | ok | create_draft_pr |
| draft_pr_offer | fail | show_upcoming_stories |
| create_draft_pr | next | show_upcoming_stories |
| show_upcoming_stories | next | ready_stories_router |
| ready_stories_router | no-ready-stories | no_ready_stories_gate |
| ready_stories_router | default | define_sprint_goal |
| no_ready_stories_gate | ok | define_sprint_goal |
| no_ready_stories_gate | fail | stop4 |
| define_sprint_goal | ok | prd_summary_router |
| prd_summary_router | prd-exists | derive_sprint_dod |
| prd_summary_router | default | create_sprint_spec |
| derive_sprint_dod | next | create_sprint_spec |
| create_sprint_spec | next | update_progress |
| update_progress | next | done |
| done | next skill | nsk_story_cycle |

Start node: `emit-start-event`
