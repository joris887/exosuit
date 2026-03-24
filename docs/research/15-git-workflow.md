# Git workflow for AI-assisted development

**The optimal git workflow for AI-human collaboration combines trunk-based development principles with sprint-scoped branches, Conventional Commits, squash merging, and layered safety hooks.** DORA research across 32,000+ professionals shows elite teams are **2.3× more likely** to use trunk-based development and **5.8× more likely** to practice continuous integration. The JD-LLM Framework's existing architecture — sprint branches, story commits, squash merge to main, PR review — aligns remarkably well with these findings. This report synthesizes research across branching strategies, commit conventions, merge strategies, PR practices, AI-specific patterns, and safety mechanisms to propose a complete, evidence-backed workflow.

The core tension in AI-assisted development is volume versus quality: AI tools generate **30–154% more code per PR**, but review effectiveness drops **70%** when PRs exceed 400 lines. Every recommendation below addresses this tension directly — keeping PRs small, history clean, and humans firmly in control of what reaches main.

---

## 1. Branching strategies converge on short-lived branches

### The DORA evidence is decisive

The *Accelerate* research (Forsgren, Humble, Kim, 2018) — based on four years of data from the State of DevOps reports — establishes that high-performing teams share three branch-related characteristics: **three or fewer active branches**, merging to trunk **at least once per day**, and **no code freezes or integration phases**. The 2021 State of DevOps Report quantified this further: elite performers meeting reliability targets are 2.3× more likely to use trunk-based development.

Google operates with **25,000+ developers on a single trunk**, committing 40,000+ changes per day to a monorepo of 2 billion lines. Meta deploys facebook.com from a shared branch twice daily. These are not theoretical preferences — they are battle-tested patterns at extreme scale.

**GitFlow is explicitly deprecated for continuous delivery.** Vincent Driessen himself added a 2020 note to his original 2010 blog post: "If your team is doing continuous delivery of software, I would suggest to adopt a much simpler workflow (like GitHub Flow) instead of trying to shoehorn git-flow into your team." Atlassian now labels GitFlow a "legacy Git workflow."

### The recommended model: modified GitHub Flow with sprint scoping

The JD-LLM Framework's sprint-based flow maps naturally to a **modified GitHub Flow** pattern:

- **`main`** — always deployable, protected, receives only squash-merged PRs
- **`sprint/S01`** — optional integration branch per sprint for multi-story coordination (cut from main at sprint start, merged to main at sprint end)
- **`feat/S01-story-description`** or **`fix/issue-description`** — short-lived story branches, one per story/task, branched from sprint branch (or main for solo developers)

For **solo developers**, this simplifies to pure GitHub Flow: branch from main, work on feature branch, squash merge back. The sprint branch layer adds value only when coordinating multiple stories or developers within a sprint.

The **Ship/Show/Ask** model (Rouan Wilsenach, published on martinfowler.com, 2021) provides a useful decision framework for when to require review: **Ship** established patterns and documentation directly, **Show** interesting approaches via immediately-merged PRs, **Ask** for uncertain or complex changes via review-required PRs. Solo developers default to Ship/Show; teams default to Show/Ask.

### Branch naming conventions

Branch names should use **lowercase with hyphens**, include the type prefix aligned with Conventional Commits, and optionally reference ticket IDs:

| Pattern | Example |
|---------|---------|
| Feature | `feat/user-authentication` |
| Bug fix | `fix/header-css-overflow` |
| Sprint (teams) | `sprint/S01` |
| With ticket | `feat/PROJ-123-payment-processing` |
| Hotfix | `hotfix/critical-auth-bypass` |

Enforce via regex: `^(feat|fix|hotfix|refactor|docs|test|chore|sprint)\/[a-z0-9][a-z0-9-]*$`

### Feature flags complement, not replace, branches

Feature flags and feature branches serve different purposes and **work best together**. Short-lived feature branches provide code isolation during development; feature flags provide **release decoupling** — the ability to deploy code to production with features disabled, enabling trunk-based development for incomplete features. The key risk is "toggle debt" — teams must actively retire flags when no longer needed.

---

## 2. Conventional Commits provide machine-readable history

### The full specification

**Conventional Commits v1.0.0** (maintained by the conventional-changelog community, Creative Commons CC BY 3.0) defines a structured commit message format:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

The two mandatory types are **`feat:`** (correlates with SemVer MINOR) and **`fix:`** (correlates with SemVer PATCH). Breaking changes are indicated by a `BREAKING CHANGE:` footer or `!` after the type. Additional recommended types from @commitlint/config-conventional include: `build`, `chore`, `ci`, `docs`, `style`, `refactor`, `perf`, and `test` — these trigger no version bump unless they include a breaking change footer.

The specification contains **16 formal rules** using RFC 2119 keywords. Key requirements: types MUST be nouns followed by a colon and space; scope is optional but MUST be a parenthesized noun; footers use git trailer convention with `-` replacing whitespace in tokens; `BREAKING CHANGE` MUST be uppercase.

### Atomic commits correlate with lower defect rates

Research consistently shows smaller commits produce fewer bugs. Purushothaman and Perry (2005, IEEE TSE) found **less than 4% probability** that a single-line change introduces an error. Kamei et al. (2013, TSE) established that change size is consistently associated with defect likelihood. A 2026 SANER paper demonstrated that commit-size-aware metrics improve defect prediction by **3.5–7.3% AUROC**.

An atomic commit encapsulates **one logical unit of change**, leaves the codebase in a working state, and can be described in a single sentence. During AI-assisted development, this means instructing the AI to commit after each completed logical step — not after each file edit, but after each meaningful, testable change.

### AI-generated commit messages need guardrails

Claude Code uses parallel subagents internally — one detects commit style from git history, another analyzes changes — and adds `Co-Authored-By: Claude <noreply@anthropic.com>` by default. Aider appends `(aider)` to the author name and generates Conventional Commits messages using a weaker/cheaper model. GitHub Copilot generates messages but adds **no attribution**.

Best practices for AI commit messages: treat AI output as a draft, enforce Conventional Commits via commitlint hooks (the AI will adapt to hook failures), add AI context in the commit body rather than the subject line, and use structured git trailers (`Generated-with:`, `Reviewed-by:`) for audit trails.

### Co-authorship and git blame

The `Co-authored-by:` trailer format requires a blank line between the description and trailers. **Critical limitation**: `git blame` only shows the primary author — co-authors exist only in commit message metadata and require `git log --format=%B` to surface. For AI attribution, this means the AI's contribution is recorded but doesn't clutter blame output.

---

## 3. Small PRs are the single highest-leverage practice

### The research is unambiguous

The **SmartBear/Cisco study** (2,500 reviews, 3.2M lines of code, 10 months) established the definitive benchmarks: **optimal review size is 200–400 LOC**, defect detection yield hits **70–90%** at this size, and inspection rates above **400 LOC/hour cause severe effectiveness drops**. Maximum productive review time is **60–90 minutes**.

Google's internal data (Sadowski et al., ICSE-SEIP 2018) shows their **median change is just 24 lines**, 90% of reviews touch fewer than 10 files, and median review turnaround is **under 4 hours**. Graphite's analysis of 1.5M PRs found PRs with 200–400 lines have **40% fewer defects** and get approved **3× faster** than larger ones.

This research creates an urgent constraint for AI-assisted development. The 2025 DORA Report found that AI tools increased **PR sizes by 154%** and **review time by 91%**, with bug rates climbing 9%. The solution is not to review more — it's to **scope AI work to produce PRs under 400 lines**.

### PR templates that get used

Effective templates share four characteristics: they are **concise** (4–6 sections maximum), use **HTML comments** for invisible instructions, include **checkboxes** for visible completion status, and **automate** what can be checked by CI rather than requiring human attestation. Essential sections:

1. **What** — summary of changes (1–3 sentences)
2. **Why** — motivation, linked issue/ticket
3. **How tested** — test commands run, manual verification steps
4. **Type** — checkbox list (feat/fix/refactor/docs/chore)
5. **Reviewer notes** — areas of concern, specific questions

Kononenko et al. (Shopify) found that **PR description quality has more impact on review outcomes than PR size alone** — a well-described 1,000 LOC PR outperforms a vaguely described 100 LOC PR.

### Draft PRs and stacked PRs

Draft PRs (introduced February 2019) block merging, suppress CODEOWNERS notifications, and signal work-in-progress — use them at the start of every feature to enable early CI feedback. For larger features, **stacked PRs** break work into 3–5 dependent PRs. Graphite (founded by former Meta engineers) provides the most complete tooling; Git 2.38+'s `--update-refs` enables manual stacking. Keep stacks to 3–5 PRs to avoid cascading conflicts.

### Review turnaround targets

Google's engineering practices documentation sets the standard: **one business day maximum** for first response, with actual median under 4 hours. The Rigby & Bird (2013) convergent practices study found **two reviewers** independently emerged as optimal across Google, Microsoft, AMD, and open-source projects. For solo developers, self-review with a 24-hour cooling period before merge provides similar benefits.

---

## 4. Squash merge wins for AI-assisted work — with caveats

### The three strategies compared

| Strategy | History | Bisect granularity | Revert ease | Best for |
|----------|---------|-------------------|-------------|----------|
| **Squash merge** | 1 commit per PR | PR-level only | Clean atomic revert | Small/medium PRs, AI-heavy workflows |
| **Merge commit** | All commits preserved + merge commit | Individual commits | `git revert -m 1` | Large PRs needing debug granularity |
| **Rebase and merge** | All commits, linear, new SHAs | Individual commits | No single-command PR revert | Teams wanting linear history |

**Squash merge is the recommended default** for the JD-LLM Framework because AI-assisted development produces high volumes of intermediate, exploratory commits that are noise in the permanent history. Each squashed commit represents one **complete, tested, reviewed feature** — the atomic unit that matters for understanding project evolution.

### The counterargument is real but addressable

Ken Imoto's March 2025 analysis ("Why 'Just Squash Merge' No Longer Works in the Age of AI") argues that squashing 1,000+ line PRs is dangerous because `git bisect` loses granularity. **This is correct** — the solution is not to abandon squash, but to **enforce the 400 LOC PR limit**. A squashed 200-line commit is perfectly debuggable. Mitchell Hashimoto (HashiCorp founder) prefers merge commits for 9/10 PRs, but his context is large-scale open source, not sprint-scoped AI-assisted development.

**Recommended policy**: squash merge by default; allow merge commits for PRs exceeding 400 LOC or touching critical infrastructure where individual commit granularity aids debugging.

### Semi-linear history is ideal but impractical on GitHub

Semi-linear merge (rebase then `--no-ff`) combines linear readability with merge-commit PR boundaries — the theoretical optimum. GitLab and Azure DevOps support it natively. **GitHub does not**, and there is no timeline for support despite years of feature requests. Since the JD-LLM Framework targets GitHub, squash merge remains the pragmatic choice.

### Merge queues eliminate broken-main scenarios

GitHub's merge queue (GA mid-2023) creates temporary branches combining all queued PRs, runs CI on the combined state, and only merges if tests pass. This eliminates the classic semantic merge conflict where two independently-passing PRs break when combined. Block/Square reports merge queues "practically eliminated all build failures" in their monorepo. For solo developers, merge queues add unnecessary overhead — enable them when the team grows beyond 3 contributors.

---

## 5. AI-specific git patterns are maturing rapidly

### Checkpointing: the foundation of safe AI development

**Claude Code's built-in checkpoint system** captures code state before each file modification (under 50ms, under 100KB per checkpoint). The `/rewind` command or `Esc+Esc` opens a scrollable restoration UI with three options: restore code only, conversation only, or both. Anthropic explicitly states: "Checkpoints complement but don't replace proper version control."

For git-level checkpointing, three patterns have emerged for Claude Code:

- **CLAUDE.md instructions** (simplest): "Create commits after completing each logical unit of work using Conventional Commits." Claude decides when a unit is complete.
- **PostToolUse hooks** (most granular): Auto-commit after every file write. Produces many WIP commits that get squashed before PR.
- **Stop hooks** (balanced): Commit when Claude finishes a full response turn. Natural breakpoints, fewer commits.

**Aider has the most mature git integration**: every AI-suggested change gets an automatic commit with a descriptive message by default. Before editing files with uncommitted changes, Aider first commits preexisting changes separately — keeping human and AI edits cleanly separated.

The critical safety rule across all tools: **allow `git add` and `git commit` automatically, but never auto-allow `git push`**. Local commits are always safe to amend, squash, or reset. Pushing is irreversible in shared contexts.

### Worktrees enable parallel AI sessions

Git worktrees have become **the critical infrastructure pattern** for AI-assisted development. A single repo has one working tree; worktrees create additional working directories sharing the same `.git` history and refs. Each AI agent gets complete file isolation.

Claude Code provides a native **`--worktree` (`-w`) flag**: `claude -w feature-payments` creates a worktree at `.claude/worktrees/feature-payments/`. incident.io reports routinely running **4–5 parallel Claude agents** using worktrees with significant acceleration in feature delivery.

Practical considerations: a 2GB codebase can consume ~10GB with multiple worktrees in 20 minutes; each worktree + AI agent uses 2–4GB RAM; **choose truly independent tasks** to avoid cross-worktree merge conflicts. The GitButler team warns: "You can create merge conflicts between worktrees without knowing."

### Reviewing AI-generated diffs demands new discipline

Salesforce Engineering observed code volume increasing **~30% with AI tools**, with review latency rising and per-PR attention declining. Addy Osmani's 2026 framework captures the emerging consensus: "Ship changes with evidence like manual verification and automated tests, then use review for risk, intent, and accountability." Over 30% of senior developers now report shipping mostly AI-generated code, with errors **75% more common in logic** than syntax.

Practical techniques: read tests before implementation, focus on behavioral risks rather than syntax, watch for hallucinated APIs, use AI review tools (CodeRabbit, Graphite Agent) as a first pass, and stage changes line-by-line using Git GUIs (Fork, GitKraken) when AI makes broad, sweeping changes.

### Agent identity separation

Give AI agents a distinct git identity (`GIT_AUTHOR_NAME="claude-bot"`) to enable different branch protection rules for bot versus human PRs, CODEOWNERS rules requiring human approval for bot changes to critical paths, and easy audit via `git log --author=claude-bot`. GitHub's Copilot Coding Agent enforces that **the developer who assigned the task cannot approve the resulting PR**.

---

## 6. Layered safety prevents catastrophic git operations

### Hook framework selection

| Framework | Best for | Speed | Key advantage |
|-----------|----------|-------|--------------|
| **Husky** | JS/TS projects | Sequential | ~20M weekly npm downloads, massive ecosystem |
| **pre-commit** | Multi-language teams | Medium | Language-agnostic, 150+ shared hook repos |
| **Lefthook** | Monorepos, performance | **Parallel (~10×)** | Go binary, no runtime dependency, built-in file filtering |

For the JD-LLM Framework's language-agnostic requirement, **Lefthook** is the recommended choice: it's a single Go binary with no runtime dependency, runs hooks in parallel (critical when AI generates frequent commits), and supports glob-based file filtering natively. The pre-commit framework is a strong alternative for teams already using Python tooling.

### Branch protection configuration

**Main branch** (strictest):
- Require pull request before merging (1+ approving review for teams; 0 for solo with CI gates)
- Require status checks to pass (lint, test, build)
- Require conversation resolution
- Require linear history (enforces squash/rebase)
- Do not allow bypassing (include administrators)
- Disable force pushes and deletions

**GitHub Rulesets** (newer, recommended over classic branch protection) support organization-wide rules, dry-run evaluate mode, layered rulesets, and metadata rules for commit message validation on Enterprise Cloud. Multiple rulesets can apply simultaneously with the most restrictive winning.

### Dangerous commands to block in AI contexts

The JD-LLM Framework's existing `pre-tool-use.sh` + `safety.patterns` approach is well-aligned with emerging best practices. Essential blocked patterns using regex (not glob — AI agents find creative alternative syntax like `git -C /path push`):

```
git\s+(-C\s+\S+\s+)?push\s+--force
git\s+(-C\s+\S+\s+)?push\s+-f
git\s+(-C\s+\S+\s+)?reset\s+--hard
git\s+(-C\s+\S+\s+)?clean\s+-f
git\s+(-C\s+\S+\s+)?branch\s+-D
rm\s+-rf\s+\.git
```

**Allow-listed safe commands**: `git status`, `git log`, `git diff`, `git branch` (list only), `git fetch`, `git stash list`, `git add`, `git commit`. When Claude Code hits a hook failure, it reads the error, fixes the violation, and re-commits — creating an effective self-correcting feedback loop.

### Secret detection: defense in depth

Run **Gitleaks as a pre-commit hook** for speed (milliseconds, 150+ regex patterns, 88% recall) and **TruffleHog in CI/CD** for depth (800+ detectors, live credential verification, fewer false positives). Academic research confirms no single tool catches all secrets — using multiple tools is necessary. GitHub Push Protection provides an additional server-side layer for known token patterns but has limitations: 5-second timeout on large pushes, cannot protect against private-to-public repository transitions.

---

## Recommended git workflow specification

This section provides the complete recommended workflow for the JD-LLM Framework's `docs/reference/GIT_WORKFLOW.md`.

### Branching

**Model**: Modified GitHub Flow with optional sprint scoping.

- `main` is always deployable and protected. All code reaches main via squash-merged PRs.
- For teams: `sprint/S01` branches cut from main at sprint start, merged at sprint end.
- Story branches: `feat/description` or `fix/description`, branched from sprint branch (teams) or main (solo).
- All branches live ≤1 week. Branches older than 1 sprint are stale by definition.
- Solo developers may skip sprint branches entirely.

### Commits

**Standard**: Conventional Commits v1.0.0, enforced by commitlint via Lefthook commit-msg hook.

- Required types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`
- Scope optional, parenthesized: `feat(auth): add OAuth2 support`
- Breaking changes: `feat!:` or `BREAKING CHANGE:` footer
- AI attribution: `Co-Authored-By: Claude <noreply@anthropic.com>` trailer (automatic in Claude Code)
- Atomic commits during development; squashed to single commit on merge to main

### Pull requests

- **Maximum 400 LOC** per PR (hard limit; target ≤200 LOC)
- **Template**: What/Why/How-tested/Type/Reviewer-notes (5 sections, with checkboxes)
- **Draft PRs**: Create immediately when starting work for early CI feedback
- **Review SLA**: First response within 4 hours (team), same-day self-review (solo)
- **Reviewers**: 1–2 per PR; code owners for critical paths

### Merging

- **Default**: Squash and merge (enforced via GitHub repository settings)
- **Exception**: Merge commit allowed for PRs >400 LOC or infrastructure changes
- **Post-merge**: Auto-delete head branches (GitHub setting); local cleanup via `git fetch --prune`
- **Merge queue**: Enable when team exceeds 3 contributors

---

## Recommended AI-specific patterns

### Checkpointing protocol

1. Add to CLAUDE.md: "Commit after each completed logical unit using Conventional Commits. Never push without explicit instruction."
2. Configure PostToolUse or Stop hooks for automatic local checkpointing during sessions.
3. Use `/rewind` or `Esc+Esc` for instant rollback within sessions.
4. Before squash-merging, review checkpoint commits and ensure the final state is correct.

### Parallel development with worktrees

1. Use `claude -w <branch-name>` for isolated parallel sessions.
2. Choose **truly independent tasks** to avoid cross-worktree conflicts.
3. Limit to 4–5 concurrent worktrees on a 32GB machine.
4. Run `git worktree prune` regularly; maintain per-worktree CLAUDE.md if needed.

### Safe rollback hierarchy

1. **Within session**: `/rewind` to checkpoint (code, conversation, or both)
2. **Last commit**: `git reset --soft HEAD~1` (keep changes staged)
3. **Multiple commits**: Interactive rebase `git rebase -i` to select/squash/drop
4. **After push**: `git revert <hash>` (creates new commit, safe for shared branches)
5. **Nuclear option**: `git reset --hard` (blocked by default — requires manual override)

### Review protocol for AI-generated code

1. Read tests first to understand intended behavior.
2. Focus on logic and behavioral risks, not syntax.
3. Watch for hallucinated APIs, deleted tests, ignored constraints.
4. Use line-level staging via Git GUIs for selective acceptance.
5. Require test evidence, not AI explanation.

---

## Recommended safety configuration

### Lefthook hooks (`lefthook.yml`)

```yaml
pre-commit:
  parallel: true
  commands:
    lint:
      glob: "*.{ts,tsx,js,py}"
      run: <project-specific linter> {staged_files}
    secrets:
      run: gitleaks detect --staged --no-banner

commit-msg:
  commands:
    conventional:
      run: npx --no -- commitlint --edit {1}

pre-push:
  commands:
    branch-check:
      run: |
        BRANCH=$(git rev-parse --abbrev-ref HEAD)
        if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
          echo "Direct push to $BRANCH blocked"; exit 1
        fi
    tests:
      run: <project-specific test command>
```

### Claude Code hooks (`.claude/hooks/pre-tool-use.sh`)

Block patterns using regex (not glob) to prevent AI syntax workarounds:
- `git\s+.*push\s+--force`, `git\s+.*push\s+-f`
- `git\s+.*reset\s+--hard`
- `git\s+.*clean\s+-f`
- `git\s+.*branch\s+-D`
- `git\s+.*checkout\s+main` (prevent switching to main for commits)
- `rm\s+-rf\s+\.git`

### GitHub branch protection (main)

Require PR with 1+ approval (team) or 0 approvals with required status checks (solo), require status checks, require linear history, disable force push, disable deletion, include administrators. Migrate to GitHub Rulesets for evaluate mode, organization-wide scope, and layered rules.

---

## Tool recommendations

| Category | Recommended | Alternative | Rationale |
|----------|------------|-------------|-----------|
| **Hook framework** | Lefthook | pre-commit framework | Language-agnostic, parallel, fast, no runtime deps |
| **Commit linting** | commitlint + @commitlint/config-conventional | — | De facto standard, 16-rule enforcement |
| **Interactive commits** | commitizen (cz-cli) + cz-conventional-changelog | cz-git (lighter) | Guided prompts prevent format errors |
| **Secret detection (local)** | Gitleaks | detect-secrets (Yelp) | Fast (ms), 88% recall, 150+ patterns |
| **Secret detection (CI)** | TruffleHog | GitHub Push Protection | 800+ detectors, live credential verification |
| **Automated versioning** | semantic-release | changesets (for monorepos) | Full CI automation: version + changelog + publish |
| **PR descriptions** | GitHub Copilot + manual context | CodeRabbit, Graphite Agent | 80% acceptance rate; add human "why" |
| **AI code review** | CodeRabbit | Graphite Agent, Qodo PR-Agent | Line-by-line analysis, free for OSS |
| **Stacked PRs** | Graphite | git --update-refs (native) | Full-featured with merge queue awareness |
| **Merge queue** | GitHub merge queue | Mergify (for advanced batching) | Native integration, free for public repos |
| **Git GUI for staging** | Fork | GitKraken, Sourcetree | Line-level staging critical for AI diffs |
| **Worktree tooling** | Claude Code native (`-w`) | agentree, git-worktree-runner | Built-in, zero configuration |

---

## Knowledge gaps and uncertainties

**Empirical data on AI-specific git workflows is thin.** Most recommendations for AI-assisted git practices come from blog posts, community discussions, and vendor documentation — not peer-reviewed research. The 2025 DORA finding that AI increased PR sizes by 154% and review time by 91% is the strongest quantitative signal, but the study doesn't prescribe specific workflow solutions.

**Squash merge versus merge commit for AI work remains genuinely debated.** The argument depends entirely on PR size discipline. No controlled study compares defect rates between squash and merge-commit strategies specifically in AI-assisted contexts.

**Worktree scalability limits are anecdotal.** The 4–5 parallel agent recommendation comes from incident.io's experience and RAM estimates, not systematic benchmarking. Disk I/O, memory pressure, and merge conflict frequency at higher parallelism are not well-documented.

**GitHub's lack of semi-linear merge and true fast-forward support** forces a suboptimal choice between squash (loses granularity) and rebase-and-merge (rewrites SHAs, breaks GPG signatures, loses PR boundaries). Teams with flexibility to use GitLab gain a meaningful advantage here.

**Long-term effects of AI attribution on code ownership are unknown.** When 30–40% of code is AI-generated with Co-authored-by trailers, how does this affect git blame utility, code ownership models, and developer accountability? No research addresses this yet.

**Hook bypass by AI agents is a real risk.** At least one documented case shows an AI agent bypassing a `git commit` blocker by using `git -C /path commit` syntax. Regex-based blocking is more robust than glob matching, but the adversarial surface area of creative flag combinations is large. Server-side enforcement remains the only truly authoritative gate.