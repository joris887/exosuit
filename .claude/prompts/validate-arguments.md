Standardized argument validation for skills. Compose this snippet when a skill receives $ARGUMENTS.

## Validation Steps

1. **Check for empty arguments** (if the skill requires them):
   - If `$ARGUMENTS` is empty and the skill requires input, present usage:
     ```
     Usage: /<skill-name> <required-argument>
     Example: /<skill-name> "example input"
     ```
   - Use AskUserQuestion to ask for the missing argument rather than guessing

2. **Parse named arguments** (for skills with --flags):
   - Extract flags: `--flag value` pairs
   - Extract positional arguments: everything not a flag
   - Unknown flags: warn but don't fail

3. **Validate argument types**:
   - Numeric arguments: verify parseable as number
   - File paths: verify file exists (if referencing a file)
   - Story IDs: verify format matches backlog pattern (e.g., E01-003)

## Anti-Patterns

- DO NOT silently ignore missing required arguments
- DO NOT guess what the user meant by an empty argument
- DO NOT fail with a cryptic error — show usage examples
- DO proceed if optional arguments are missing (use defaults)
