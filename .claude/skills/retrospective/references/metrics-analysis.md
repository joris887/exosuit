# Metrics Analysis Reference

## Leading vs Lagging Classification

Leading indicators predict future quality; lagging indicators measure past outcomes.

| Category | Metrics | Rationale |
|----------|---------|-----------|
| **Leading** | Code churn ratio, Test coverage Δ, Sprint satisfaction | Early signals: churn predicts defects (89% accuracy), coverage decay signals testing discipline loss, satisfaction divergence from objective metrics signals perception gap |
| **Lagging** | Change failure rate, Tasks completed | Outcome signals: CFR measures actual quality failures, task count measures delivery |

**Divergence interpretation:**
- Leading degrading + lagging stable = **early warning window** — quality problems building but not yet visible. Intervene now.
- Leading improving + lagging degrading = **delayed effect** — course correction underway. Maintain patience, lagging will follow in 1-2 sprints.
- Both degrading = **active quality crisis** — immediate sprint focus on stabilization.
- Both improving = **healthy trajectory** — continue current approach.

## Anti-pattern Detection

Check these metric combinations from Sprint History data:

### 1. Perception Gap
**Signal:** Sprint satisfaction ≥4 AND (CFR rising OR churn ratio rising for 2+ sprints)
**Meaning:** Developer thinks output is good, but objective quality metrics disagree. The METR study found perceived vs actual productivity diverge by ~40 percentage points with AI.
**Action:** Review recent code changes critically. Run `/code-quality` and `/test-validator` on the sprint's diff.

### 2. Task Fragmentation
**Signal:** Tasks completed increasing AND average cycle time decreasing for 2+ sprints
**Meaning:** Stories may be getting too small to be meaningful. AI makes it easy to complete more tasks while the tasks themselves shrink in value.
**Action:** Review story scope — are stories delivering meaningful increments, or is scope being artificially split?

### 3. Weak Test Coverage
**Signal:** Test coverage Δ positive AND change failure rate rising for 2+ sprints
**Meaning:** Tests are being added but may not catch real defects — possibly assertion-free tests or tests that execute code without verifying behavior.
**Action:** Run `/test-validator` to check for tautological tests, weakened assertions, and assertion-free coverage.

### 4. Maintenance Spiral
**Signal:** <50% of stories are type "feature" AND code churn ratio rising
**Meaning:** Most effort goes to fixing/refactoring instead of delivering new value. The codebase may be accumulating structural debt.
**Action:** Consider a dedicated refactoring sprint targeting the highest-churn files. Use `scripts/pm/metrics.sh --churn` to identify hotspots.
