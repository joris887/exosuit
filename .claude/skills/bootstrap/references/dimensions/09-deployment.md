# Dimension 9: Deployment & Infrastructure

## Introduction

"Where does your app run so people can actually use it? This is the last technical decision — after this, we build."

## Applicability

Skip for: libraries/packages (published to npm/PyPI/etc.), CLI tools (distributed as binary).

## Research Query

Compose `deep-research` at **STANDARD** depth (pricing changes frequently):
"Best hosting platform for [backend framework] [project type] pricing and limits [current year]"

## Options

Present with current pricing from research:

```markdown
**Option A: Vercel**
Push your code and it's live. The easiest deployment for web apps.
- **Best for:** Next.js apps, frontend-heavy apps, marketing sites
- **Cost:** Free (hobby), $20/month (pro). Free tier handles most MVPs.
- **Limits:** Serverless functions timeout at 60s. No persistent background jobs on free tier.
- **CI/CD:** Built in — push to GitHub and it deploys automatically.
- **Trade-off:** Optimized for serverless. Long-running tasks need a separate service.

**Option B: Railway**
A modern Heroku replacement. Databases included. Click deploy.
- **Best for:** Full-stack apps with databases and background workers
- **Cost:** $5/month base + usage. PostgreSQL included.
- **Limits:** None significant for small-medium apps.
- **CI/CD:** GitHub integration, automatic deploys.
- **Trade-off:** Less mature ecosystem than Vercel. Smaller community.

**Option C: Fly.io**
Containers that run close to your users worldwide.
- **Best for:** Apps needing low latency globally, WebSocket apps, Docker-based apps
- **Cost:** Free tier (3 shared VMs), then usage-based. ~$5-15/month for small apps.
- **Limits:** Requires Docker knowledge for custom setups.
- **CI/CD:** GitHub Actions integration.
- **Trade-off:** More configuration than Vercel/Railway. More control.

**Option D: AWS / GCP / Azure**
Full cloud platforms. Maximum power and complexity.
- **Best for:** Enterprise apps, complex architectures, specific compliance requirements
- **Cost:** Pay-per-use. Can be cheap or very expensive depending on setup.
- **Services:** EC2/ECS, Lambda, RDS, S3, CloudFront, etc.
- **Trade-off:** Significant learning curve. Only choose if your team has cloud experience.
```

**For non-technical users**, simplify the recommendation:
"If you're using Next.js → **Vercel** (made for it, free to start). Otherwise → **Railway** (simple, includes database). Only pick AWS/GCP if you have someone who knows cloud infrastructure."

## Additional Questions

1. **Custom domain:** "Do you have a domain name (like yourapp.com)?"
   - Yes → guide DNS setup during deployment
   - No → suggest registrars (Cloudflare, Namecheap) and note it's not needed for MVP

2. **Environments:** "Do you need separate test and production environments?"
   - For solo/MVP → "Not yet. We'll deploy one version. You can add a staging environment later."
   - For teams → "Yes — a staging environment catches bugs before users see them."

3. **CI/CD:** Default to GitHub Actions (most universal). Mention alternatives only if asked.

## Cross-Dimension Constraints

- Frontend is Next.js → **Vercel** is the natural choice (built by the same team)
- Database is Supabase → hosting doesn't need to include database (Supabase is external)
- Database is self-managed PostgreSQL → **Railway** includes PostgreSQL
- Backend is Go/Rust → **Fly.io** (container-based, supports any runtime)
- "Offline required" → frontend is a PWA, backend hosting still needed for sync
- Scale target >10K users → verify hosting can handle it (Vercel Pro, Railway scaling, Fly.io regions)
- Compliance (HIPAA, SOC2) → **AWS/GCP** (compliance certifications available)

## Recommendation Logic

- Next.js app → **Vercel** (seamless integration)
- Full-stack with database → **Railway** (includes PostgreSQL, simple)
- Docker-based / non-JS backend → **Fly.io** (container support)
- Enterprise / compliance → **AWS** or **GCP** (certifications)
- Just prototyping → **Vercel free tier** or **Railway starter** (cheapest path to live)

## Output

Record:
- **Hosting platform:** Selected platform
- **Deployment method:** Git push / Docker / manual
- **CI/CD:** GitHub Actions / platform built-in / other
- **Domain:** Has domain / needs domain / not needed yet
- **Environments:** Production only / staging + production
- **Estimated cost:** Monthly at expected scale
- **Rationale:** Why this platform fits
