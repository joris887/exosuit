# Dimension 4: User Experience & Design

## Introduction

"Let's decide how your product looks and feels. This isn't about pixel-perfect design — it's about choosing a direction that matches your users and your brand."

## Applicability

Skip this dimension for: CLI tools, libraries/packages, API-only services, data pipelines.

## Style Direction Options

Present 3-4 options with real-world references:

```markdown
**Option A: Clean & Professional**
Think: Linear, Notion, Stripe
- Lots of whitespace, subtle animations, muted colors
- Best for: productivity tools, B2B, professional audiences
- Complexity: Low (fewer custom components needed)

**Option B: Warm & Friendly**
Think: Slack, Figma, Duolingo
- Rounded corners, illustrations, playful micro-interactions
- Best for: consumer apps, community platforms, creative tools
- Complexity: Medium (custom illustrations and animations)

**Option C: Bold & Data-Dense**
Think: Bloomberg Terminal, Grafana, trading platforms
- Dark themes, dense layouts, real-time data visualizations
- Best for: dashboards, analytics, power-user tools
- Complexity: High (complex data visualization components)

**Option D: Minimal & Content-First**
Think: Medium, Substack, iA Writer
- Typography-focused, minimal chrome, content takes center stage
- Best for: content platforms, blogs, documentation sites
- Complexity: Low (simple layout, great typography)
```

## Additional UX Questions

After style direction, ask:

1. **Device priority:** "Will most people use this on their phone or computer?"
   - Phone first → mobile-first responsive design
   - Computer first → desktop-first, then adapt for mobile
   - Both equally → responsive from the start
2. **Offline access:** "Do people need to use this without internet?" → Yes = PWA considerations
3. **Dark mode:** "Should it have a dark mode option?" → Yes/No/Both

## When This Dimension Is INFERRED

If competitive research suggests a clear style direction: "Products like yours typically go with a **[style]** look — think [example]. Want to go with that, or see other options?"

## Recommendation Logic

- Productivity/B2B → Clean & Professional
- Consumer/social → Warm & Friendly
- Data/analytics → Bold & Data-Dense
- Content/publishing → Minimal & Content-First
- If user's primary persona is non-technical → recommend simpler, warmer styles
- If user mentioned "dashboard" → lean toward Data-Dense

## Output

Record:
- **Design direction:** Selected style with reference examples
- **Device priority:** Mobile-first / desktop-first / responsive
- **Offline support:** Yes/No
- **Dark mode:** Yes/No/Both
- **Design reference:** 2-3 specific products to use as visual benchmarks
