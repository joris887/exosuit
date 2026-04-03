# Dimension Completeness Sweep

Phase 5 of /discover. Ensures every technical decision gets made by running through dimensions D04-D10. Dimensions D01-D03 are already covered by Phases 2-3 and should be skipped.

## Pre-Sweep: Load Decision State

Read `docs/reference/DECISION_LOG.md`. For each dimension, check: is there already a decision logged? If yes, skip that item. Only ask what's still undecided.

Typical post-elicitation coverage:
- D01 Problem & Vision: ✅ COVERED (Phase 2)
- D02 User Personas: ✅ COVERED (Phase 3)
- D03 Features & MVP: ✅ COVERED (Phase 3)
- D04 UX & Design: ⚠️ PARTIAL (may have emerged during elicitation)
- D05-D10: ❌ NOT YET (unless emerged during elicitation)

## Scale-Adapted Depth

| Scale | Approach per Dimension |
|---|---|
| **Quick Build** | "I'd go with [X]. Sound good?" → confirm/change. ~2 minutes total. |
| **Standard** | 2-3 options with tradeoffs → user picks. ~15-20 minutes total. |
| **Platform** | Full treatment + research + ADR for significant decisions. ~30-45 minutes. |
| **Pioneering** | Defer to post-spike: "We'll decide after spikes." Mark OPEN. |

## The 10 Dimensions

For each dimension, load the corresponding module from `.claude/skills/bootstrap/references/dimensions/{NN}-{name}.md` for base questions, options, and research queries.

### D04. UX & Design
**Base:** Load `bootstrap/references/dimensions/04-ux-design.md`

**Archetype additions:**
- Experiential: "What's the animation style? Smooth/snappy/bouncy?" + "Visual mood: bright/dark/neon/muted?"
- Viral: "What does the share card look like? Design share output BEFORE features." + "OG image concept?"
- Educational: "Visualization style: charts/maps/scrollytelling/interactive?" + "Scroll behavior: long-scroll/paginated/explorable?"
- Creative: "Editor UX metaphor: canvas/timeline/layers/blocks?" + "How do creations get shared/exported?"

### D05. Frontend Tech
**Base:** Load `bootstrap/references/dimensions/05-frontend.md`
**Research:** "[framework] vs [alternative] [year]"

### D06. Backend Tech
**Base:** Load `bootstrap/references/dimensions/06-backend.md`
**Research:** "[framework] [project type] best practice"
**Platform addition:** Microservices vs monolith decision, event-driven architecture consideration.

### D07. Data & Storage
**Base:** Load `bootstrap/references/dimensions/07-data-storage.md`
**Research:** "[database] vs [alternative] for [use case]"
**Platform addition:** Sharding strategy, data warehouse, backup and recovery strategy.

### D08. Auth & Security
**Base:** Load `bootstrap/references/dimensions/08-auth-security.md`
**Research:** "[auth approach] [framework] implementation"
**Platform addition:** RBAC design, multi-tenant architecture, audit logging requirements.

### D09. Deployment & Infra
**Base:** Load `bootstrap/references/dimensions/09-deployment.md`
**Research:** "[hosting] [project type] deployment guide"
**Platform addition:** Staging environments, blue-green deployment, CDN configuration, WAF.

### D10. Business & Growth
**Base:** Load `bootstrap/references/dimensions/10-business-growth.md`
**Research:** "[archetype] monetization models [year]"
**Archetype additions:**
- Marketplace: Supply-side + demand-side growth strategies separately
- Viral: Organic spread mechanics, viral coefficient targets
- DevTool: Developer advocacy, community building, documentation-as-marketing

## Cross-Dimension Constraint Check

After all dimensions are decided, detect contradictions:

| Combination | Issue | Resolution |
|---|---|---|
| Serverless + WebSocket | Most serverless can't hold persistent connections | Use managed WebSocket (API Gateway) or switch to SSE |
| Static site + SSR | SSR requires a server runtime | Choose one rendering strategy |
| "1M users" + free tier hosting | Free tiers cap at ~10K-100K monthly | Upgrade hosting plan or adjust scale expectation |
| "Offline required" + server-rendered | SSR needs server; offline needs client-side | Use PWA with client-side rendering |
| SQLite + serverless | No persistent filesystem in serverless | Switch to managed DB or different hosting |
| Mobile app + web-only deployment | Need native/cross-platform framework | Add React Native/Flutter/Expo |

Present conflicts with explanation. Let user choose resolution. Log resolved conflicts in DECISION_LOG with rationale.

## Decision Logging

After each dimension decision, append to `docs/reference/DECISION_LOG.md`:

```markdown
| D{NN} | 5-sweep | {question} | {decision} | {CONFIRMED/ASSUMED} | {rationale} | {revisit trigger or —} |
```

Confidence levels:
- **CONFIRMED** — User explicitly stated and validated
- **ASSUMED** — Auto-picked or defaulted, acknowledged by user
- **SPECULATIVE** — Neither stated nor inferable, flagged for validation
