# 6. API Documentation

## Research Prompt

```
I need deep research on API documentation best practices. The goal is to determine the best possible approach for a generic API documentation template that works for REST, GraphQL, gRPC, WebSocket, and event-driven APIs — optimized for AI-assisted development where the AI reads this document to implement correct API interactions.

**Framework context:** This template is part of the JD-LLM Development Framework — a language-agnostic AI development framework for Claude Code. The API docs:
- Are populated by /bootstrap or manually by developers
- Must be readable by AI for implementing correct API integrations
- Must support both internal APIs (module boundaries) and external APIs (public endpoints)
- Should integrate with the framework's contract testing strategy
The template must be maintainable — ideally verifiable from code/specs.

**Research areas** (starting points — include anything significant you discover beyond these):

1. **Industry-Leading API Documentation** — Stripe (gold standard), Twilio, GitHub REST/GraphQL, AWS. What makes API docs effective? What percentage of developer time is spent reading API docs?

2. **API Documentation Formats & Standards** — OpenAPI/Swagger 3.1, AsyncAPI, GraphQL schema docs, gRPC/Protobuf docs. Contract-first vs code-first. Lessons from API Blueprint and RAML.

3. **Documentation Sections That Matter** — Authentication, endpoint structure, error handling, rate limiting, pagination, versioning, webhooks/events. Which sections are essential vs nice-to-have?

4. **API Documentation for AI** — How should APIs be documented so AI generates correct integration code? Type information format. Request/response examples that prevent hallucination. Preventing AI from creating non-existent endpoints.

5. **Interactive & Living API Docs** — Doc-as-tests, changelog/migration guides, SDK generation. Keeping examples verified and current.

6. **Internal API Documentation** — Internal/private API docs vs public. Module-to-module contracts. When to document vs when it's self-documenting (types + naming).

**Required output format:**
1. Executive summary
2. Per-topic findings with citations
3. **Recommended template structure** — propose the specific sections, their format, and ordering for maximum AI utility, with justification
4. **Recommended endpoint documentation format** — adaptable across REST/GraphQL/gRPC
5. **Recommended approach for internal vs external APIs** — how to handle both in one template
6. Tool recommendations
7. Knowledge gaps
```

## Implementation Prompt

```
I have completed deep research on API documentation best practices. The research findings are saved in docs/research/api-documentation.md (or I will paste them below).

Your task: Update the framework's API_DOCUMENTATION.md template to be the best possible API documentation format, guided by the research findings.

**Hard constraints (non-negotiable):**
- File locations: docs/reference/API_DOCUMENTATION.md AND scaffold/docs/reference/API_DOCUMENTATION.md
- Must work for REST, GraphQL, gRPC, WebSocket, and event-driven APIs
- Must be readable by AI for implementing correct API integrations
- Must support both internal APIs (module boundaries) and external APIs (public endpoints)
- Must be maintainable — ideally generated or verified from code/specs
- Must integrate with the framework's contract testing strategy (see TESTING_STRATEGY.md)

**Instructions:**
1. Read the current API_DOCUMENTATION.md at docs/reference/API_DOCUMENTATION.md
2. Read the research findings thoroughly
3. Implement the template structure, endpoint format, and internal/external approach the research recommends — trust the research over your own defaults
4. Update scaffold/docs/reference/API_DOCUMENTATION.md to match
5. Verify the contract testing section in TESTING_STRATEGY.md aligns with the API doc format

**Outcome criteria (how to evaluate the result):**
- An AI reading this generates correct integration code on the first attempt — right endpoints, right auth, right error handling
- The document prevents AI from hallucinating non-existent API methods
- Both internal module boundaries and external endpoints are clearly documented
- The format can be generated or verified from OpenAPI/AsyncAPI specs where available
- Works equally well for a REST API, a GraphQL API, and an event-driven system
```
