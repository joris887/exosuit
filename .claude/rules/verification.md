---
paths:
  - "**"
---

# Verification Rules

## Evidence Required Before Completion Claims

- NEVER claim "tests pass" without running the test command and showing output in the current turn
- NEVER say "should work" or "looks correct" — run the verification command
- NEVER mark a task complete without fresh evidence from the current session
- Partial verification (ran one test, not the suite) is NOT proof of full compliance
- "I already ran this earlier" is NOT fresh evidence — re-run before claiming completion
- Confidence is NOT proof — show command output
- "It compiles" is NOT "it works" — run the tests
- Before invoking any CLI tool with flags you're unsure about, run `[tool] --help` first — do NOT guess flags from memory, tool versions change
