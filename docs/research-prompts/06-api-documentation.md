# 6. API Documentation

## Research Prompt

```
I need comprehensive deep research on API documentation best practices. The goal is a generic API documentation template that works for REST, GraphQL, gRPC, WebSocket, and event-driven APIs — optimized for AI-assisted development where the AI reads this document to implement correct API interactions.

Research these specific areas:

1. **Industry-Leading API Documentation**
   - Stripe API docs — why they're considered the gold standard, structure analysis
   - Twilio API docs — developer experience innovations
   - GitHub REST and GraphQL API docs — dual-API documentation approach
   - AWS API documentation — how they handle massive API surface areas
   - Postman/Stoplight research on what makes API docs effective
   - What percentage of developer time is spent reading API docs? (studies)

2. **API Documentation Formats & Standards**
   - OpenAPI/Swagger 3.1 — structure, what to specify, what to skip
   - AsyncAPI — for event-driven and WebSocket APIs
   - GraphQL schema documentation — introspection-based vs manual
   - gRPC/Protobuf documentation — proto comments vs separate docs
   - API Blueprint vs RAML — lessons learned from alternative formats
   - Contract-first vs code-first documentation — which produces better docs?

3. **Documentation Sections That Matter**
   - Authentication/authorization documentation patterns
   - Endpoint documentation structure (method, path, parameters, body, response, errors)
   - Error handling documentation — standardized error formats, error code catalogs
   - Rate limiting documentation — headers, quotas, retry strategies
   - Pagination documentation — cursor vs offset, consistent patterns
   - Versioning documentation — URL vs header, deprecation policies
   - Webhook/event documentation — payloads, delivery guarantees, retry policies

4. **API Documentation for AI**
   - How should APIs be documented so AI generates correct integration code?
   - Type information format — what helps AI get types right?
   - Request/response example formats — what level of detail prevents hallucination?
   - How to document API boundaries so AI doesn't create non-existent endpoints?
   - Error handling documentation that AI can implement correctly

5. **Interactive & Living API Docs**
   - API playgrounds and sandboxes — tools and approaches
   - Doc-as-tests — keeping examples verified and current
   - Changelog/migration guides — documenting breaking changes
   - SDKs vs raw API docs — when to generate client documentation

6. **Internal API Documentation**
   - Documentation for internal/private APIs (different from public API docs)
   - Module-to-module API contracts in monoliths
   - Documentation for shared libraries and utilities
   - When to document an API vs when it's self-documenting (types + naming)

For each finding, include source URLs, specific examples of excellent API docs, and assessment of which approaches work for small projects vs. large API surfaces.

Output a structured research report with: recommended template structure, per-section content guidance, format comparisons, and tool recommendations.
```

## Implementation Prompt

```
I have completed deep research on API documentation best practices. The research findings are saved in docs/research/api-documentation.md (or I will paste them below).

Your task: Update the framework's API_DOCUMENTATION.md template to be the best possible API documentation format.

**Context:** This template lives at docs/reference/API_DOCUMENTATION.md (and scaffold/docs/reference/API_DOCUMENTATION.md). It's populated by /bootstrap or manually by developers. It must:
- Work for REST, GraphQL, gRPC, WebSocket, and event-driven APIs
- Be readable by AI for implementing correct API integrations
- Include authentication, endpoints, errors, rate limits, versioning, webhooks
- Support both internal APIs (module boundaries) and external APIs (public endpoints)
- Be maintainable — ideally generated or verified from code/specs
- Integrate with the framework's contract testing strategy

**Instructions:**
1. Read the current API_DOCUMENTATION.md at docs/reference/API_DOCUMENTATION.md
2. Read the research findings
3. Redesign the template:
   - Authentication section (multiple auth patterns)
   - Endpoint documentation format (adaptable to REST/GraphQL/gRPC)
   - Request/response schemas with examples
   - Error catalog with codes, messages, and retry guidance
   - Rate limiting and quotas
   - Versioning and deprecation
   - Webhook/event documentation
   - Internal API contracts section
4. Use a format that AI can read to generate correct integration code
5. Update scaffold version to match
6. Verify contract testing section in TESTING_STRATEGY.md aligns with API doc format

Make this the API documentation that prevents every AI integration mistake — wrong endpoints, missing auth, incorrect error handling, or hallucinated API methods.
```
