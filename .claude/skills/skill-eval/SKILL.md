---
name: skill-eval
version: 2.5.0
description: Use when you want to test, measure, or compare skill effectiveness. Supports eval, compare, metrics, baseline capture, and regression detection.
trigger: manual
depends-on: []
references: []
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Edit, Write
argument-hint: "<mode> [skill-name] [--scenario <desc>]"
---
______________________________________________________________________

## skill-eval

Evaluating skill: **$ARGUMENTS**

## Modes

Parse the first argument to determine mode:

| Mode | Syntax | Purpose |
|------|--------|---------|
| **eval** | `/skill-eval eval <skill-name> --scenario "<prompt>"` | Test a skill against a known scenario |
| **compare** | `/skill-eval compare <skill-name> --old <path> --new <path> --scenario "<prompt>"` | A/B test two versions of a skill |
| **metrics** | `/skill-eval metrics <skill-name>` | Analyze a skill's evaluation criteria and pressure scenarios |
| **baseline** | `/skill-eval baseline <skill-name> --scenario "<prompt>"` | Capture baseline output for regression detection |
| **regression** | `/skill-eval regression <skill-name>` | Compare current skill against saved baseline |

## Mode: eval

Test a skill against a scenario and grade the output against expectations.

### Process

1. **Load the skill** — Read `.claude/skills/<skill-name>/SKILL.md`
2. **Load evaluation criteria** — Read the skill's `## Evaluation Criteria` section (if present in SKILL.md or SKILL_TEMPLATE.md)
3. **Define the scenario** — Use the provided `--scenario` or prompt the user for one
4. **Execute mentally** — Walk through what Claude would do with this skill loaded, given the scenario prompt. Trace the expected decision points, tool calls, and outputs.
5. **Grade against criteria** — For each evaluation criterion, determine PASS/FAIL with evidence

### Output

```markdown
## Skill Evaluation: <skill-name>

### Scenario
> <the test scenario>

### Expected Behavior
| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | [criterion text] | PASS/FAIL | [why] |

### Hard Gate Compliance
- [ ] All hard gates would be respected
- [ ] Red flags table would prevent shortcuts (if applicable)

### Context Budget
- Estimated SKILL.md tokens: X
- References loaded: [list]
- Total estimated tokens: X

### Verdict: PASS / FAIL / PARTIAL
[Summary of findings]
```

## Mode: compare

Blind A/B comparison of two skill versions.

### Process

1. **Load both versions** — Read the old and new skill files
2. **Define scenario** — Use provided `--scenario` or prompt for one
3. **Evaluate independently** — Run the eval process for BOTH versions, labeling them "Version A" and "Version B" (randomize which is old/new)
4. **Compare blind** — Without knowing which is old/new, assess which version:
   - Produces better outcomes for the scenario
   - Has stronger enforcement (hard gates, red flags)
   - Is more context-efficient
   - Handles edge cases better
5. **Reveal and recommend** — Reveal which was old/new, present the winner with reasoning

### Output

```markdown
## Skill Comparison: <skill-name>

### Scenario
> <the test scenario>

### Version A Assessment
[Strengths, weaknesses, estimated behavior]

### Version B Assessment
[Strengths, weaknesses, estimated behavior]

### Winner: Version [A/B]
**Reason:** [why this version is better for this scenario]

### Reveal
- Version A = [old/new path]
- Version B = [old/new path]

### Recommendation
[Keep new / revert to old / cherry-pick specific changes]
```

## Mode: metrics

Analyze a skill's testability and evaluation readiness.

### Process

1. **Load the skill** — Read SKILL.md and any references
2. **Check for evaluation criteria** — Does the skill have a `## Evaluation Criteria` section?
3. **Identify pressure scenarios** — What realistic prompts would test this skill's enforcement?
4. **Assess coverage** — Are hard gates testable? Are red flags covered by scenarios?
5. **Suggest improvements** — What evaluation criteria or pressure scenarios should be added?

### Output

```markdown
## Skill Metrics: <skill-name>

### Evaluation Readiness
- Has evaluation criteria: YES/NO
- Has pressure scenarios: YES/NO
- Hard gates: X (testable: Y)
- Red flag entries: X

### Suggested Pressure Scenarios
1. [Scenario that would test hard gate compliance]
2. [Scenario that would trigger a red flag rationalization]
3. [Edge case scenario]

### Suggested Evaluation Criteria
- [ ] [Criterion to add to the skill]
```

## Mode: baseline

Capture a baseline output for regression detection.

### Process

1. **Load the skill** — Read `.claude/skills/<skill-name>/SKILL.md`
2. **Define scenario** — Use provided `--scenario` or prompt for one
3. **Execute eval** — Run the standard eval process
4. **Save baseline** — Write the graded output to `.claude/skills/skill-eval/baselines/<skill-name>-v<version>.md`

### Baseline Format

```markdown
# Baseline: <skill-name> v<version>

## Scenario
> <the test scenario>

## Expected Behavior
[Full eval criteria results]

## Captured: <date>
```

## Mode: regression

Compare current skill behavior against a saved baseline.

### Process

1. **Load the skill** — Read current `.claude/skills/<skill-name>/SKILL.md`
2. **Load baseline** — Read `.claude/skills/skill-eval/baselines/<skill-name>-v<latest>.md`
3. **Run eval** — Execute eval with the baseline's scenario
4. **Diff results** — Compare current eval against baseline criteria
5. **Report regressions** — Flag any criteria that changed from PASS to FAIL

### Output

```markdown
## Regression Check: <skill-name>

### Baseline: v<old> → Current: v<new>

| # | Criterion | Baseline | Current | Status |
|---|-----------|----------|---------|--------|
| 1 | [text]    | PASS     | PASS    | OK     |
| 2 | [text]    | PASS     | FAIL    | REGRESSION |

### Verdict: CLEAN / REGRESSION DETECTED
[Details of any regressions]
```

## Rules

- This skill is for ANALYSIS only — do not modify skill files during eval or compare
- In compare mode, do NOT reveal which version is old/new until the blind assessment is complete
- Be honest about limitations — mental execution is not the same as actual execution
- Reference specific lines in skill files when citing evidence
- In baseline mode, always include the version number in the filename
- In regression mode, always compare against the most recent baseline
