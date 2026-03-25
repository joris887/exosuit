# LLM-Readiness Assessment Reference

Reference loaded by `/bootstrap` Path A step A3.1. Assesses whether the codebase structure supports effective LLM-assisted development.

## Purpose

Story-cycle sizes stories to "1-3 hours, touches no more than 5-8 files." If the codebase has oversized files, high coupling, or circular dependencies, LLM effectiveness degrades — the AI can't hold enough context to make safe changes.

## Assessment Steps

### 1. File Size Analysis (Stack-Agnostic)

Measure file sizes for all detected source file extensions (exclude vendor, node_modules, .git, build output):

```bash
# Count LOC per source file (adapt extensions to detected stack)
find . -type f \( -name "*.py" -o -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \
  -o -name "*.go" -o -name "*.rs" -o -name "*.rb" -o -name "*.java" -o -name "*.kt" \
  -o -name "*.php" -o -name "*.dart" -o -name "*.cs" -o -name "*.swift" \
  -o -name "*.c" -o -name "*.cpp" -o -name "*.h" \) \
  -not -path '*/node_modules/*' -not -path '*/.git/*' \
  -not -path '*/vendor/*' -not -path '*/build/*' -not -path '*/dist/*' \
  -not -path '*/__pycache__/*' -not -path '*/target/*' | \
  xargs wc -l 2>/dev/null | sort -rn | head -20
```

### 2. Fan-Out Analysis (Stack-Aware)

Count how many other files import each file. High fan-out means a change ripples widely.

| Stack | Import Pattern |
|-------|---------------|
| Python | `^import \|^from ` |
| TypeScript/JS | `^import \|require(` |
| Go | `"project/` in import blocks |
| Rust | `^use crate::` |
| Java/Kotlin | `^import ` |
| Ruby | `^require \|^require_relative ` |
| PHP | `^use \|^require \|^include ` |
| C/C++ | `^#include "` (local includes only) |

```bash
# Example: Python fan-out analysis
grep -r "^import\|^from" --include="*.py" -l | \
  xargs grep -h "^import\|^from" 2>/dev/null | \
  sed 's/^from \([^ ]*\).*/\1/' | sed 's/^import \([^ ]*\).*/\1/' | \
  sort | uniq -c | sort -rn | head -10
```

### 3. Circular Dependency Detection (Where Feasible)

Check for mutual imports between modules. Circular dependencies confuse LLMs and break incremental refactoring.

| Stack | Detection Method |
|-------|-----------------|
| Python | `python3 -c "import importlib; ..."` or scan for mutual `from X import` / `from Y import` pairs |
| TypeScript | Check for circular `import` patterns between files |
| Go | `go vet ./...` reports import cycles |
| Rust | Compiler rejects cycles (if it compiles, no cycles) |

For Python and TypeScript, scan for mutual import pairs:
```bash
# Find all import relationships, then detect cycles
# This is a simplified heuristic — flag for manual review if detected
```

Note: Full circular dependency detection is complex. Flag suspicious mutual imports for manual review rather than attempting full graph analysis.

## Thresholds

| Metric | Green (✓) | Yellow (⚠️) | Red (✗) |
|--------|-----------|-------------|---------|
| Max file LOC | ≤300 | 300-500 | >500 |
| Average file LOC | ≤150 | 150-300 | >300 |
| Files over 500 LOC | 0 | 1-3 | >3 |
| Max fan-out (imports of one module) | ≤5 | 5-10 | >10 |
| Circular dependencies | 0 | — | ≥1 detected |

## Metrics to Record

Record in `docs/progress.md` → `## Current Sprint` → **Notes** field as part of bootstrap baseline:

```markdown
**Notes:** Bootstrap baseline — {total_loc} LOC across {file_count} files, largest: {file_path} ({max_loc} LOC), {count} files over 500 LOC.
```

## Integration with Readiness Report

Feed results into the Context-efficient check (readiness-report.md):

- **Ready:** No files over 500 LOC, average ≤150, no high fan-out
- **Risk:** 1-3 files over 500 LOC, or average 150-300, or fan-out 5-10
- **Missing:** >3 files over 500 LOC, or average >300, or circular dependencies detected

## Foundation Story Generation

For each file flagged as oversized (>500 LOC), generate a refactoring story:

```markdown
### E00-S{nn}: Split {filename} ({loc} LOC) into focused modules

**Type:** Refactoring
**Priority:** P2
**Source:** Framework Readiness Report — Context-efficient (⚠️ Risk)

**Description:**
{filename} at {loc} LOC exceeds the 500 LOC threshold for effective LLM-assisted development. Large files reduce context efficiency and increase the risk of incomplete changes.

**Acceptance Criteria:**
- [ ] {filename} is split into modules, each ≤300 LOC
- [ ] All existing tests still pass after the split
- [ ] No circular dependencies introduced by the split
- [ ] Import paths updated across the codebase
```

For high fan-out modules, generate a decoupling story:

```markdown
### E00-S{nn}: Reduce coupling in {module} (fan-out: {count})

**Type:** Refactoring
**Priority:** P2
**Source:** Framework Readiness Report — Context-efficient (⚠️ Risk)

**Description:**
{module} is imported by {count} other files. High fan-out means changes ripple widely, making LLM-assisted changes risky.

**Acceptance Criteria:**
- [ ] Fan-out reduced to ≤5 through interface extraction or module splitting
- [ ] All existing tests still pass
- [ ] No new circular dependencies introduced
```
