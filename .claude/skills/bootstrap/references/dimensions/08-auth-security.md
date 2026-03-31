# Dimension 8: Authentication & Security

## Introduction

"How should users log in, and what data needs protecting? Getting auth right from the start saves painful rewrites later."

## Applicability

Skip for: libraries/packages, CLI tools without user accounts, static sites, internal tools with OS-level auth.

## Research Query

Compose `deep-research` at QUICK depth:
"Best authentication solution for [backend framework] [current year] — pricing, features, developer experience, security"

## Options

```markdown
**Option A: Clerk (Recommended for most apps)**
A complete login system you drop into your app — handles everything.
- **Includes:** Sign up, login, social login (Google/GitHub/etc.), MFA, user management UI
- **Cost:** Free up to 10,000 monthly active users, then $0.02/user
- **Setup:** Drop-in React components. Works in ~10 minutes.
- **Trade-off:** External service — user data on their servers. Vendor lock-in.

**Option B: Supabase Auth**
Built into Supabase — if you're already using it for your database, auth is free.
- **Includes:** Email/password, social login, magic links, phone auth
- **Cost:** Included with Supabase free tier (50K MAU)
- **Setup:** Already integrated if using Supabase. Zero additional setup.
- **Trade-off:** Fewer features than Clerk (no built-in user management UI). Tied to Supabase.

**Option C: Auth.js (NextAuth.js)**
Self-hosted auth — your data stays on your servers.
- **Includes:** Any OAuth provider, sessions, JWT, database adapters
- **Cost:** Free (open source, self-hosted)
- **Setup:** More configuration required. You manage the auth flow and session storage.
- **Trade-off:** More work to set up and maintain. But full control over user data.

**Option D: No auth (public app)**
No user accounts needed.
- **When:** Public blogs, documentation sites, static tools, open APIs
- **Note:** Can always add auth later if needed
```

## Security Questions

Based on project type, ask relevant compliance questions:

```markdown
**Does your app handle any of these?** (check all that apply)
- [ ] Payment or credit card information → PCI compliance considerations
- [ ] Health or medical data → HIPAA considerations (US) / relevant local regulations
- [ ] Personal data of EU users → GDPR considerations
- [ ] Children's data (under 13/16) → COPPA/age verification considerations
- [ ] None of the above → standard security practices are sufficient
```

For each checked item, explain in plain English:
- **PCI:** "You can't store credit card numbers yourself. Use Stripe or a similar payment provider — they handle the compliance."
- **HIPAA:** "Health data needs encryption at rest and in transit, access logging, and a BAA with your hosting provider."
- **GDPR:** "Users must be able to see and delete their data. You need a privacy policy and consent management."

## Cross-Dimension Constraints

- Database is Supabase → Supabase Auth is the easiest choice (same platform, zero setup)
- Framework is Next.js → Clerk and Auth.js both have excellent Next.js integrations
- "Enterprise/team" context → consider SSO/SAML support (Clerk Pro, Auth.js + provider)
- "Passwordless only" → Supabase magic links or Clerk passwordless mode
- Scale >100K users → verify pricing at scale (Clerk gets expensive, Auth.js stays free)

## Recommendation Logic

- Using Supabase for database → **Supabase Auth** (zero additional setup)
- Want fastest setup with React/Next.js → **Clerk** (drop-in components)
- Want full control / self-hosted → **Auth.js**
- No user accounts needed → **No auth** (don't over-engineer)
- Compliance requirements → Add appropriate security measures regardless of auth provider

## Output

Record:
- **Auth solution:** Selected provider
- **Auth features:** Social login providers, MFA, passwordless
- **Security requirements:** Compliance needs identified (PCI/HIPAA/GDPR/none)
- **Compliance notes:** Plain-English summary of what compliance means for this project
- **Rationale:** Why this auth solution fits
