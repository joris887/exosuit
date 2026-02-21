______________________________________________________________________

## name: debug-session description: Structured debugging assistance. Helps diagnose issues systematically with hypothesis-driven debugging. argument-hint: \[error-description\] disable-model-invocation: true user-invocable: true allowed-tools: Read, Glob, Grep, Bash

Debug session for: **$ARGUMENTS**

## 1. Gather Information

First, let's understand the issue:

- What error message or unexpected behavior?
- When does it occur?
- What was the last working state?

## 2. Reproduce the Issue

Run relevant tests or commands to reproduce the problem.

## 3. Form Hypotheses

Based on the error, possible causes:

1. \[Hypothesis 1\]
1. \[Hypothesis 2\]
1. \[Hypothesis 3\]

## 4. Test Each Hypothesis

For each hypothesis:

- What would we expect to see if true?
- How can we verify?
- Check relevant code/logs

## 5. Identify Root Cause

Based on investigation:

- Root cause: \[description\]
- Location: \[file:line\]
- Why it happened: \[explanation\]

## 6. Fix Strategy

Options:

1. \[Fix approach 1\] - Pros/cons
1. \[Fix approach 2\] - Pros/cons

Recommended: \[approach\] because \[reason\]

## 7. Implement Fix (TDD)

1. Write test that exposes the bug
1. Verify test fails
1. Apply fix
1. Verify test passes
1. Run full suite

## 8. Verify and Document

- All tests pass
- Issue no longer reproducible
- Document in commit message what caused it
