# Dimension 10: Business Model & Growth

## Introduction

"Last question — how does this sustain itself, and how big do you want it to get? This affects technology choices (scale) and feature priorities (monetization)."

## Applicability

Skip or simplify for: libraries/packages (always free/open source), internal tools (no monetization), portfolio projects.

## Monetization Options

Present options relevant to the project type:

```markdown
**Free / Open Source**
No revenue. Portfolio project, learning exercise, or internal tool.
→ Simplest. No payment infrastructure needed.

**Freemium**
Free tier with limited features, paid tier unlocks more.
→ Examples: Slack (message history limit), Notion (team features), Figma (projects limit).
→ Needs: feature flagging, upgrade prompts, billing integration (Stripe).

**Subscription**
Monthly or annual payment for access.
→ Examples: Netflix, Spotify, most SaaS tools.
→ Needs: billing integration, trial period, plan management.

**Usage-Based**
Pay per API call, storage, or action.
→ Examples: AWS, Twilio, OpenAI API.
→ Needs: metering, usage tracking, billing integration.

**Marketplace Commission**
Take a percentage of transactions between users.
→ Examples: Airbnb (service fee), Etsy (listing + transaction fee), Uber.
→ Needs: escrow/payment splitting, trust system.

**One-Time Purchase**
Pay once, own forever.
→ Examples: desktop software, premium templates.
→ Needs: license management, download delivery.
```

## Growth Questions

1. **Scale:** "How many users do you expect in the first 3 months?"
   - Tens → free tier hosting is fine, no scaling concerns
   - Hundreds → basic hosting, start thinking about performance
   - Thousands → need proper hosting, caching, monitoring
   - Tens of thousands+ → need scalable architecture from day one

2. **Timeline:** "When do you want the first version live?"
   - This week → fast-track everything, minimal MVP
   - This month → reasonable scope, some polish
   - This quarter → fuller feature set, more planning

These answers feed back into technology recommendations (hosting tier, caching needs, architecture complexity).

## When This Dimension Is INFERRED

If the idea mentions pricing, subscriptions, or marketplace transactions: "It sounds like you're planning a **[model]** approach. Is that right?"

## Recommendation Logic

- Personal project / learning → Free
- SaaS tool → Freemium or Subscription
- Marketplace → Commission
- API product → Usage-based
- If user hasn't thought about it: suggest Free for MVP, note where monetization hooks could go later

## Output

Record:
- **Business model:** Selected model
- **Scale target:** Expected users in 3 months
- **Timeline:** Target launch date
- **Monetization notes:** What payment infrastructure is needed (if any)
- **Growth implications:** How scale target affects architecture choices
