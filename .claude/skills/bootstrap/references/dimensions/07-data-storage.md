# Dimension 7: Data & Storage

## Introduction

"Where does your app's information live? This is about choosing the right database and storage for your data."

## Applicability

Skip for: static sites, simple CLI tools with no persistence, libraries.

## Research Query

Compose `deep-research` at QUICK depth:
"Best database for [project type] with [backend framework] [current year] — pricing, managed options, developer experience"

## Options

```markdown
**Option A: PostgreSQL via Supabase (Recommended for most apps)**
Like a powerful spreadsheet — organized data in tables, with extras built in.
- **Used by:** Thousands of apps from startups to enterprises
- **Good for:** Any app with structured data (users, posts, orders, tasks)
- **Includes:** Real-time subscriptions, built-in auth, auto-generated API, dashboard
- **Cost:** Free up to 500MB and 50K monthly active users, then $25/month
- **Trade-off:** Vendor dependency for managed features (pure PostgreSQL underneath)

**Option B: PostgreSQL (self-managed)**
Same powerful database, you manage the hosting. Full control, more work.
- **Good for:** Teams who want full control, or already have database infrastructure
- **Hosting options:** Neon (free tier), AWS RDS, Railway, Render
- **Cost:** Free tiers available; paid starts ~$5-15/month
- **Trade-off:** You handle backups, migrations, scaling

**Option C: MongoDB**
Like a filing cabinet — each document can have different fields. Flexible schema.
- **Used by:** Adobe, eBay, Toyota
- **Good for:** Apps where data structure varies (CMS, product catalogs with different attributes)
- **Cost:** Free tier (512MB) on MongoDB Atlas, paid from $57/month
- **Trade-off:** Less suited for complex relationships between data; eventual consistency by default

**Option D: SQLite**
A single file on disk — the simplest possible database.
- **Good for:** Desktop apps, CLI tools, prototypes, embedded systems
- **Cost:** Free (built into most languages)
- **Trade-off:** Single-writer. Not for multi-user web apps or serverless.
```

## Additional Storage Question

"Will your app store files (images, documents, videos)?"

If yes, recommend:
- **Supabase Storage** — if using Supabase (included)
- **Cloudflare R2** — cheapest for high volume, S3-compatible
- **AWS S3** — most mature, widest tooling support
- **Uploadthing** — simplest for Next.js/React apps

## ORM Selection

After database choice, select the appropriate ORM/client:
- PostgreSQL + TypeScript → **Drizzle ORM** (lightweight, type-safe) or **Prisma** (full-featured, popular)
- PostgreSQL + Python → **SQLAlchemy** or **Django ORM**
- MongoDB + TypeScript → **Mongoose**
- SQLite + any → built-in drivers or Drizzle

## Cross-Dimension Constraints

- Serverless hosting → cannot use SQLite (no filesystem)
- Supabase chosen → Supabase Auth becomes easy (same platform)
- "Offline support" → consider local-first DB (SQLite + sync) or client-side cache
- "Real-time" → Supabase has built-in real-time; MongoDB has change streams

## Recommendation Logic

- Web app (most cases) → **PostgreSQL via Supabase** (fastest to productive, generous free tier)
- Team/enterprise → **PostgreSQL self-managed** (full control)
- Flexible schema needed → **MongoDB**
- Desktop/CLI → **SQLite**
- Already using Supabase for auth → **Supabase PostgreSQL** (everything in one place)

## Output

Record:
- **Database:** Selected database and hosting
- **ORM/client:** Selected data access library
- **File storage:** Selected file storage (if needed)
- **Caching:** Redis/none (if needed for scale)
- **Rationale:** Why this combination
