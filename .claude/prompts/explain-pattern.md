---
## name: explain-pattern description: Explain a code pattern found in the codebase argument-hint: <pattern-name> [file-path] user-invocable: true allowed-tools: Read, Glob, Grep
---

Explain the **$1** pattern as used in this codebase.

If a file path is provided (`$2`), focus on that file. Otherwise, search the codebase for examples.

Cover:
1. **What it does:** Brief explanation of the pattern
2. **Where it's used:** File paths and line numbers of examples in this codebase
3. **Why it's used here:** What problem it solves in this specific context
4. **How to follow it:** Guidelines for using this pattern in new code

Keep the explanation concise and grounded in actual code from this project — not generic textbook definitions.
