# Documentation Accuracy Safeguards

Anti-hallucination safeguards for creating or updating project documentation and context files.

## Self-Verification Questions

Before writing any technical claim in documentation, ask:

1. **"Can I point to specific files that demonstrate this?"** — If not, mark as `[Inferred]` or `[Assumed]`
2. **"Did I verify this by reading actual code, or am I inferring from names?"** — File/directory names are hints, not proof
3. **"Is this based on what I read, or what I expect in a project like this?"** — Pattern-matching from training data is not evidence

## Evidence Levels

Tag claims with their evidence level:

| Level | Marker | Meaning | Example |
|-------|--------|---------|---------|
| **Confirmed** | *(no marker needed)* | Direct evidence from reading code | "Uses Express (see `src/server.ts:3`)" |
| **Inferred** | `[Inferred]` | Reasonable conclusion from structure/patterns | "Appears to use repository pattern (based on `src/repos/` structure)" |
| **Assumed** | `[Assumed — needs verification]` | No direct evidence | "Likely targets Node 18+" |

## Qualifying Language

When evidence is indirect, use qualifying language:

- "appears to", "likely", "based on [file]"
- "the presence of X suggests Y"
- "consistent with [pattern], though not explicitly confirmed"

Do NOT use definitive statements for inferred or assumed claims.

## Post-Creation Validation

After generating any documentation file:

1. Re-read the output
2. For each technical claim, verify: is the referenced file/pattern real?
3. Remove or flag claims that can't be traced to actual code
4. Ensure no technology, library, or pattern is mentioned that doesn't appear in the actual codebase

## Common Hallucination Patterns

| Pattern | Risk | Prevention |
|---------|------|------------|
| Claiming a design pattern from directory names | Medium | Read actual code, not just file tree |
| Listing technologies from package.json devDependencies | Low | Verify they're actually used in code |
| Describing API contracts that don't exist | High | Read actual route/endpoint definitions |
| Inferring architecture from common project layouts | Medium | Check actual import graph and data flow |
| Assuming test frameworks from file naming | Low | Verify test runner config exists |
