# Grep-First Codebase Exploration

A micro-component for efficient codebase exploration that pre-filters files via targeted Grep calls before reading, dramatically reducing context consumption.

## When to Apply

- Story-cycle Phase 1b (codebase exploration)
- Any exploration phase where the story description contains identifiable terms (function names, module names, API endpoints, error messages)

## Process

### Step 1: Extract Search Terms

From the story description, identify:
- Function/method names
- Module/component names
- API endpoints or route patterns
- Error messages or log strings
- Domain terms (e.g., "payment", "auth", "notification")

### Step 2: Parallel Grep Calls

Run targeted Grep calls in parallel across the codebase:

1. **Import/usage grep:** Search for import statements referencing the identified terms
2. **Definition grep:** Search for function/class/type definitions matching the terms
3. **Test grep:** Search test files for test names or describe blocks mentioning the terms

Use `output_mode: "files_with_matches"` to get file paths without reading content.

### Step 3: Rank and Filter

- Rank files by match density (files matching multiple terms rank higher)
- Prioritize: source files > test files > config files > documentation
- Select the top 5-10 most relevant files

### Step 4: Read Selectively

Read only the top-ranked files. If the story is well-defined, 5-7 files is sufficient.

### Fallback

If fewer than 3 files match (common for greenfield stories or entirely new features):
- Fall back to broader exploration using codebase-explorer agents
- Or use Glob patterns to find files in the target directory structure

## Anti-Patterns

- Do NOT read all files in a directory — grep first
- Do NOT use broad patterns like `.*` — be specific to the story terms
- Do NOT skip the ranking step — reading 20 files wastes context as much as reading 0
