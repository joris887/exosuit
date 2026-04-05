---
created: <!-- filled by /bootstrap -->
updated: <!-- filled by /sprint-end -->
---

# System Patterns

## Implementation Patterns
<!-- For each pattern: name, where used, reference file. Use positive formulation.
     Example:
     **Repository pattern** — All data access goes through `src/repositories/`.
     Reference: `src/repositories/UserRepository.ts`. New entities follow this structure. -->

## Architectural Conventions
<!-- Naming conventions, file organization, import rules, module boundaries.
     Example:
     - Files: kebab-case. Classes: PascalCase. Functions: camelCase.
     - Handlers in `src/handlers/`, services in `src/services/`, repos in `src/repositories/`.
     - Imports flow: handlers → services → repositories. Never reversed. -->

## Error Handling Strategy
<!-- How errors propagate, custom error types, logging approach, user-facing error format.
     Example:
     - All errors wrapped in AppError with status code + error code.
     - Services throw; handlers catch and format HTTP response.
     - Logging via structured logger (winston/pino/slog). Never console.log in production. -->

## Testing Conventions
<!-- Test file naming, fixture patterns, assertion style, mock strategy.
     Example:
     - Tests colocated: `src/auth/login.ts` → `src/auth/login.test.ts`.
     - Use real DB for integration tests (testcontainers). Mock only external HTTP.
     - Assertion style: expect().toEqual() with specific values, never computed from production code. -->

## Implementation Recipes
<!-- Step-by-step for common additions. These are the highest-value patterns — they tell
     the LLM exactly how to add something new without diverging from established conventions.
     Example:
     **To add a new API endpoint:**
     1. Create handler in `src/handlers/<resource>.ts` (follow UserHandler pattern)
     2. Add route in `src/routes/index.ts`
     3. Create service in `src/services/<resource>Service.ts` if business logic needed
     4. Add test in `src/handlers/<resource>.test.ts` (follow UserHandler.test.ts pattern)
     5. Add to API_DOCUMENTATION.md -->
