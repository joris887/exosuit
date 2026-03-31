# Dimension 5: Frontend Technology

## Introduction

"Now for the technology that builds what users see and interact with."

## Applicability

Skip for: CLI tools, libraries/packages, API-only services, data pipelines.

## Research Query

Compose `deep-research` at QUICK depth:
"Best frontend frameworks for [project type] [current year] — popularity, performance, ecosystem, learning curve"

## Options

Present options based on project type and user's technical level.

**For non-technical users** (lead with analogies):

```markdown
**Option A: Next.js (Recommended for most web apps)**
Like a Swiss Army knife for websites — handles everything in one place.
- **Used by:** TikTok, Notion, Netflix
- **Good for:** Any web app. Handles both the visual part and the behind-the-scenes logic.
- **Trade-off:** Tied to React's way of doing things. Larger learning curve than simpler options.
- **Cost:** Free. Deploys free on Vercel.

**Option B: React + Vite**
Like building with LEGO — maximum flexibility, more assembly required.
- **Used by:** Facebook, Instagram, Airbnb
- **Good for:** When you need full control over every piece, or want a separate backend.
- **Trade-off:** More decisions to make. Need to pick routing, state management, etc. separately.
- **Cost:** Free.

**Option C: No frontend (API only)**
The engine without the car — your app is used by other software, not directly by people.
- **Good for:** Building a service for mobile apps, integrations, or developer tools.
- **Trade-off:** No user interface. Need a separate client app to use it.
```

**For technical users** (add details):

Add to each option: TypeScript support level, SSR/SSG capabilities, bundle size, ecosystem maturity, React Server Components support, and edge runtime compatibility.

**Additional options for specific cases:**
- **Svelte/SvelteKit:** Smaller bundle, simpler mental model, growing ecosystem
- **Vue/Nuxt:** Gentle learning curve, excellent docs, strong in Asia/Europe
- **Astro:** Content-heavy sites with minimal JavaScript
- **Vanilla HTML/CSS:** Simplest possible — for landing pages, docs, static sites

## Cross-Dimension Constraints

- If deployment is serverless → recommend frameworks with serverless support (Next.js, SvelteKit)
- If "offline required" → must support service workers / PWA
- If mobile app → this dimension becomes "mobile framework" (React Native, Flutter, Expo)

## Recommendation Logic

- Full-stack web app (most cases) → **Next.js** (batteries-included, largest ecosystem)
- Need separate frontend/backend → **React + Vite** (flexibility)
- Content-heavy / marketing site → **Astro** or **Next.js** with static generation
- Mobile app → **React Native / Expo** (if coming from React) or **Flutter** (cross-platform)
- Simplest possible → **HTML + Tailwind** (no framework overhead)

## Output

Record:
- **Frontend framework:** Selected framework and version
- **Styling approach:** Tailwind CSS / CSS Modules / styled-components / shadcn/ui
- **State management:** Built-in / Zustand / Redux (if applicable)
- **Rendering strategy:** SSR / SSG / CSR / hybrid
- **Rationale:** Why this choice fits the project
