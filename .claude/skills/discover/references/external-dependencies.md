# External Dependency Summary

Post-dimension-sweep step within Phase 5. Runs AFTER the cross-dimension constraint check, BEFORE Phase 6 (Vision Synthesis). **Only triggers when external services were selected.**

## Definition

An **external dependency** is any service that requires:
- Creating an account on a third-party platform
- API keys, tokens, or credentials the project consumes
- Infrastructure running outside the project's own environment
- Its own billing, quotas, or rate limits

**NOT external dependencies:** Open-source libraries installed via package managers, self-hosted tools, local databases, development-only tools (linters, formatters).

## Trigger

After the cross-dimension constraint check completes, scan all DECISION_LOG entries from Phase 5 (D04-D10). Identify every decision that selects an external service.

- **Zero external services:** Skip entirely. Proceed to Phase 6.
- **One or more external services:** Execute the summary flow below.

## Flow

### Step 1: Compile Service List

For each external service identified in the dimension decisions, determine:

| Field | Description |
|-------|-------------|
| **Service** | Name of the external service |
| **Role** | What it does in the project (e.g., database hosting, authentication) |
| **Account** | Account type needed, whether free tier is available, whether credit card is required |
| **Setup steps** | 3-5 bullet points of what the user needs to do |
| **Credentials** | What environment variables the project needs (e.g., `DATABASE_URL`, `AUTH_SECRET_KEY`) |
| **Estimated time** | Initial setup time estimate |
| **Dimension** | Which dimension decision (D05-D10) selected this service |

Use web research if needed to confirm current setup steps and free tier availability.

### Step 2: Present Summary

Show a progress update and the compiled list:

```
---
**Discover** | Phase 5 of 7: Technical Decisions — External Services
[==============>.....] [N] of ~22 decisions
Your tech choices include [X] external service(s). Here's what each one needs.
---

Your project depends on these external services. I'll add setup stories to your
backlog for each one — you'll set them up right before building the features
that need them.
```

Then for each service, present a card:

```
**[Service Name]** — [Role]
- **Account:** [type] ([free tier info])
- **Setup:** [3-5 step summary]
- **Credentials:** [env vars needed]
- **Time:** ~[estimate]
```

### Step 3: Confirm or Revise (use AskUserQuestion)

```
header: "External services"
question: "Your project uses [N] external service(s) listed above. Each will get
           a setup story in your backlog, scheduled right before the features
           that depend on it. Does this look right?"
options:
  - label: "Looks good, continue (Recommended)"
    description: "I'm comfortable with these services. Continue to vision
                  synthesis."
  - label: "I want to change a choice"
    description: "The setup for one or more services feels like too much.
                  I'll tell you which to revisit."
  - label: "Show me alternatives for a service"
    description: "I want to see what else I could use — including simpler
                  or self-hosted options."
```

**If user wants to change:** Return to the specific dimension (D05-D10) and re-present its options via AskUserQuestion. After the change, re-run both the cross-dimension constraint check AND this external dependency summary.

**If user wants alternatives:** Present alternatives for the requested service, including self-hosted options where available. Use AskUserQuestion with the original dimension's options plus any additional alternatives discovered via research.

### Step 4: Record

Log the confirmed external dependencies in DECISION_LOG:

```markdown
| EXTERNAL-DEP | 5-ext-dep | External services confirmed | [comma-separated list] | CONFIRMED | User reviewed setup requirements | — |
```

Save the full service list (all fields from Step 1) to `vision/external-dependencies.md`. This file is consumed by `/ideate` to generate setup prerequisite stories.

## Service Category Reference

Common categories and their typical setup patterns. Use as guidance when compiling the service list — the LLM should verify current setup steps via research rather than relying solely on these templates.

### Database Hosting
Examples: Supabase, PlanetScale, Neon, MongoDB Atlas, Railway
- Account: Platform account (most have free tier)
- Setup: Create project/cluster, configure access rules, get connection string
- Credentials: `DATABASE_URL`
- Time: ~5-10 min

### Authentication
Examples: Clerk, Auth0, Firebase Auth, Supabase Auth
- Account: Platform account (free tier usually available)
- Setup: Create application, configure allowed origins, select auth methods, set up OAuth providers if needed
- Credentials: `AUTH_PUBLIC_KEY`, `AUTH_SECRET_KEY` (names vary by provider)
- Time: ~10-20 min (longer with OAuth providers)

### Hosting / Deployment
Examples: Vercel, Railway, Fly.io, Render, Netlify
- Account: Platform account (free tier varies)
- Setup: Connect Git repo, configure build settings, set environment variables
- Credentials: Managed by platform; env vars via dashboard
- Time: ~5-15 min

### Payments
Examples: Stripe, LemonSqueezy, Paddle
- Account: Business account (production requires identity verification)
- Setup: Create account, get API keys, configure webhooks, create products/prices
- Credentials: `STRIPE_PUBLIC_KEY`, `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`
- Time: ~15-30 min (test mode quick; production verification takes longer)

### Email / Messaging
Examples: SendGrid, Resend, Postmark, Twilio
- Account: Platform account (free tier available)
- Setup: Verify domain or sender, get API key, configure templates
- Credentials: `EMAIL_API_KEY`, verified sender address
- Time: ~10-20 min (domain DNS verification can take hours to propagate)

### File Storage
Examples: AWS S3, Cloudflare R2, Uploadthing
- Account: Platform account
- Setup: Create bucket, configure CORS, get access credentials
- Credentials: `STORAGE_ACCESS_KEY`, `STORAGE_SECRET_KEY`, `STORAGE_BUCKET`
- Time: ~5-10 min

### Search
Examples: Algolia, Meilisearch Cloud, Typesense Cloud
- Account: Platform account (free tier available)
- Setup: Create index, configure searchable attributes, get API key
- Credentials: `SEARCH_API_KEY`, `SEARCH_APP_ID`
- Time: ~10-15 min

### Analytics / Monitoring
Examples: PostHog, Sentry, Datadog, LogRocket
- Account: Platform account (free tier available)
- Setup: Create project, install SDK, configure tracking
- Credentials: `ANALYTICS_KEY` or `SENTRY_DSN`
- Time: ~5-10 min
