# Scale Classification & Discovery Modes

## Axis 1: Archetype (What Kind of Project)

Routes the ELICITATION STYLE — what questions to ask, what research to run, what success looks like.

| # | Archetype | Core Question | Examples |
|---|---|---|---|
| 1 | **Utility / Productivity** | "What task does this make easier?" | CRM, expense tracker, booking system |
| 2 | **Experiential / Entertainment** | "What should someone FEEL?" | Games, interactive art, music visualizers |
| 3 | **Viral / Shareable** | "What makes someone share this?" | Wordle, Spend Bill Gates' Money |
| 4 | **Educational / Explanatory** | "What should someone understand after?" | Kurzgesagt-style, data essays |
| 5 | **Creative Expression** | "What can people MAKE?" | Canva, GarageBand, Scratch |
| 6 | **Personal / Hobby** | "What annoys YOU about how you do this?" | My recipe app, my gym tracker |
| 7 | **Developer Tool / Library** | "What workflow pain for devs?" | CLIs, SDKs, testing frameworks |
| 8 | **Data & Analytics** | "What decision should this inform?" | Dashboards, BI tools, monitoring |
| 9 | **Marketplace / Platform** | "What two sides are you connecting?" | Airbnb, Uber, Etsy |
| 10 | **Automation / Integration** | "What manual process does this eliminate?" | Zapier-style, corporate workflow |
| — | **Uncategorized / Hybrid** | "Tell me more and I'll help classify" | Novel concepts, AI-native apps |

### Archetype Selection Card (present to user)

```
1. UTILITY — Makes a task easier or faster
   Like: Notion, Stripe, Todoist
2. EXPERIENCE — Makes people feel something
   Like: Fruit Ninja, A Short Hike, Patatap
3. VIRAL/SHAREABLE — Try once, share immediately
   Like: Wordle, Spend Bill Gates' Money, Spotify Wrapped
4. EDUCATIONAL — Helps understand something complex
   Like: Scale of the Universe, Kurzgesagt, The Pudding
5. CREATIVE PLATFORM — Lets people create things
   Like: Canva, GarageBand, Scratch
6. PERSONAL — Built for yourself / your own need
   Like: "my recipe app", "my gym tracker"
7. DEV TOOL — Built for other developers
   Like: ESLint, Prisma, shadcn/ui
8. DATA/ANALYTICS — Visualizes data for decisions
   Like: Grafana, Metabase, admin panels
9. MARKETPLACE — Connects two sides
   Like: Airbnb, Uber, Etsy
10. AUTOMATION — Eliminates manual processes
    Like: Zapier, corporate workflows, RPA
11. NONE OF THESE — I'll describe it
```

Hybrid handling: Most real projects span 2 archetypes. Identify primary (drives main elicitation) and secondary (adds supplementary questions).

## Axis 2: Scale (How Big and Complex)

Routes the DEPTH and DOCUMENTATION level — independently of archetype.

| Scale | Duration | Complexity | Docs Level | Examples |
|---|---|---|---|---|
| **Quick Build** | 1-3 days | Single concern, 1 user type | Minimal | Pixel art viz, CLI tool, game jam entry |
| **Standard** | 1-4 weeks | Frontend + backend + DB, target audience | Standard | SaaS MVP, mobile app, API service |
| **Platform** | 1-6 months | Multiple services/user types/integrations | Full (architecture, API docs, ADRs) | Enterprise CRM, payment platform |
| **Pioneering** | Unknown | Novel/uncharted, architecture is the question | Spike-first, then decide | Org OS with gen UI, novel AI agent |

### Scale ↔ Profile Interaction

Scale controls **discovery depth**. Profile (lean/standard/strict) controls **development ceremony**. They are orthogonal.

| | lean profile | standard profile | strict profile |
|---|---|---|---|
| **Quick Build** | Fastest possible: 3 Qs + auto-pick | Quick discovery + standard dev | Quick discovery + full audit trail |
| **Standard** | Guided discovery + lean dev workflow | Default: guided discovery + standard dev | Guided discovery + full audit |
| **Platform** | Platform discovery + lean dev | Platform discovery + standard dev | Platform discovery + full audit |
| **Pioneering** | Spike-first + lean dev | Spike-first + standard dev | Spike-first + full audit |

## Per-Scale Depth Rules

### Question Counts
| Scale | Phase 2 (Core) | Phase 3 (Deep) | Phase 4 (Assumptions) | Phase 5 (Dimensions) |
|---|---|---|---|---|
| Quick Build | 3-4 | Skip | Auto-generate, user rates | Confirm defaults (~2 min) |
| Standard | 5-7 | 8-12 | Full with pre-mortem | 2-3 options per dimension |
| Platform | 7-10 | 12-15 + multi-user | Full + compliance | Full treatment + ADRs |
| Pioneering | 4-5 | Deep research focus | Core feasibility only | Defer to post-spike |

### Research Depth
| Scale | Searches per checkpoint |
|---|---|
| Quick Build | 1-3 |
| Standard | 3-8 |
| Platform | 8-15 |
| Pioneering | 10-20 |

### Phase Transition Stories
| Scale | Stories |
|---|---|
| Quick Build | 3 (E0N-001 + E0N-004 + E0N-006) |
| Standard | 6 (all) |
| Platform | 7 (all + E0N-007: Architecture Review) |
| Pioneering (post-spike) | E0N-001 + E0N-004 + full /discover re-entry |

### Epic Structure by Scale

**Quick Build:** E01 Core Build (3-5 stories) + E02-REVIEW (3 stories)

**Standard:** E01 Foundation + E02 Core MVP + E03 MVP Polish + E04-REVIEW (6 stories)

**Platform:** E01 Foundation (infra, CI/CD, testing, monitoring) + E02 Core Domain + E03 Integration + E04 Core UX + E05 Secondary Flows + E06 Quality & Security + E07-REVIEW (7 stories)

**Pioneering:** E01 Spikes (2-3 experiments) + E02-REVIEW Post-Spike Review
