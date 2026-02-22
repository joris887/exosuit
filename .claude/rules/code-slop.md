---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
  - "**/*.py"
  - "**/*.go"
  - "**/*.rs"
  - "**/*.java"
  - "**/*.rb"
  - "**/*.swift"
  - "**/*.kt"
  - "**/*.cs"
  - "**/*.cpp"
  - "**/*.c"
  - "**/*.php"
---

# AI Slop Detection Rules

Comments explain WHY, not WHAT. If the code is self-evident, no comment is needed.

## Banned Comment Patterns

Never write comments containing these filler phrases:

| Pattern | Why It's Slop |
|---------|---------------|
| "Please note that..." | Filler — state the fact directly |
| "It's important to note..." | Filler — if it's important, the code shows it |
| "As you can see..." | Addresses a reader who isn't there |
| "In conclusion..." | This is code, not an essay |
| "Let me know if..." | AI conversation artifact, not a code comment |
| "This function/method does..." | Restates the function signature |
| "The following code..." | Narrates what the reader can already see |
| "We need to..." | Editorial voice in a comment |
| "Make sure to..." | Instruction disguised as a comment |
| "Don't forget to..." | Same as above |
| "Note:" (standalone) | Usually precedes obvious information |
| "TODO" (without ticket/issue) | Untracked work — add an issue reference or fix now |
| "FIXME" (without ticket/issue) | Same — track it or fix it |
| "Helper function for..." | If it needs explanation, rename the function |
| "This is a..." | Restates the type/class declaration |

## Obvious Comment Detection

Delete comments that restate the code:

```
// BAD — restates the code
const user = getUser(id)  // Get the user by ID
items.forEach(...)        // Loop through items
if (isValid) {            // Check if valid
return result             // Return the result

// GOOD — explains WHY
const user = getUser(id)  // Cached lookup; DB call happens in middleware
items.forEach(...)        // Process sequentially — order matters for idempotency
if (isValid) {            // Validation rules defined in schema v2.3
return result             // Early return skips audit logging (intentional for batch ops)
```

## Code Prose Anti-Patterns

- Never add docstrings to functions with self-explanatory names and types
- Never add parameter descriptions that restate the type (`@param name string - the name`)
- Never add `@returns` that restates the return type
- Never add file-level comments that describe what the file contains ("This file contains...")
- Never add section separators (`// ===== SECTION =====`) — use code structure instead

## When Comments ARE Required

- Edge cases that aren't obvious from the code
- Business logic rationale ("per spec v2.3, empty cart returns 200 not 404")
- Workarounds with ticket references ("workaround for #1234")
- Performance-critical decisions ("O(1) lookup required — see benchmark in PR #567")
- Regulatory or compliance notes
- Non-obvious algorithm choices
