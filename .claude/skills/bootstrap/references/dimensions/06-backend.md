# Dimension 6: Backend Technology

## Introduction

"Now let's pick the technology that handles the logic, data processing, and behind-the-scenes work."

## Applicability

Applies to all project types except pure static sites.

## Research Query

Compose `deep-research` at QUICK depth:
"Best backend framework for [project type] [language preference if any] [current year] — performance, ecosystem, developer experience"

## Options

Group by language ecosystem:

```markdown
**TypeScript / Node.js**

- **Next.js API routes** — If you already chose Next.js for frontend, the backend is built in. Zero extra setup.
  *Best for: Full-stack apps where frontend and backend are one project.*

- **Express.js** — The veteran. Simple, flexible, massive ecosystem. Add what you need.
  *Best for: APIs, microservices, when you want full control.*

- **Fastify** — Like Express but faster. Better for high-traffic APIs.
  *Best for: Performance-sensitive APIs, real-time apps.*

- **NestJS** — Enterprise-grade structure. Enforces patterns (dependency injection, modules).
  *Best for: Large teams, complex domain logic, when consistency matters.*

**Python**

- **FastAPI** — Modern, fast, auto-generates API documentation. Excellent type safety.
  *Best for: Data-heavy apps, ML backends, rapid prototyping.*

- **Django** — Batteries-included. Admin panel, ORM, auth, all built in.
  *Best for: CRUD-heavy apps, content management, rapid MVP.*

**Go**

- **Standard library / Chi / Gin** — Compiled, fast, simple. Excellent for high-performance services.
  *Best for: Microservices, infrastructure tools, performance-critical APIs.*

**Rust**

- **Actix Web / Axum** — Maximum performance and safety. Steeper learning curve.
  *Best for: Systems programming, extremely high-throughput services.*
```

**For non-technical users**, simplify:
"If your frontend is Next.js → use Next.js for the backend too (simplest). If you need heavy data processing → Python (FastAPI). If you're not sure → Next.js API routes."

## Cross-Dimension Constraints

- Frontend is Next.js → strongly prefer Next.js API routes (same project, same deploy)
- Frontend is React + Vite → need separate backend (Express, FastAPI, etc.)
- "Real-time features" mentioned → consider WebSocket support (Fastify, NestJS, Go)
- "Machine learning" mentioned → Python (FastAPI + ML libraries)
- Database is Supabase → can skip backend entirely for simple CRUD (Supabase client SDK)

## API Style

After framework selection, briefly ask:
- **REST** — Standard, well-understood, good for public APIs
- **tRPC** — Type-safe API calls (TypeScript full-stack only, developer experience)
- **GraphQL** — Flexible queries, good for complex data relationships (more setup)
- Default: REST for most projects, tRPC for TypeScript full-stack

## Recommendation Logic

- Next.js frontend + simple CRUD → **Next.js API routes** (zero extra setup)
- Next.js frontend + complex backend → **Next.js API routes + tRPC** or separate Express
- Data science / ML → **Python FastAPI**
- Need admin panel fast → **Django**
- Maximum performance → **Go (Chi/Gin)** or **Rust (Axum)**
- Enterprise/team project → **NestJS** (enforced structure helps team consistency)

## Output

Record:
- **Backend language:** Selected language
- **Backend framework:** Selected framework
- **API style:** REST / tRPC / GraphQL
- **Rationale:** Why this combination fits
- **Separate service?:** Whether backend is in the same project as frontend or separate
