# Archetype: Developer Tool / Library

**Core Question:** "What workflow pain for devs?"
**Examples:** CLIs, SDKs, testing frameworks, API wrappers, linters, build tools

## Phase 2: Core Identity Questions

**Q1:** "Show me the dream API."
Scaffold: "Write the code snippet — the ideal interface. How would a developer USE this? This is the most important artifact for a dev tool."

**Q2:** "What workflow pain does this eliminate? How long is the workaround?"
Scaffold: "Currently takes 30 minutes of boilerplate? Requires 5 manual steps? Needs reading 3 docs? Quantify the pain."

**Q3:** "Competitive landscape?"
Scaffold: "What exists already?" → Auto-search npm/PyPI/GitHub/crates.io for the category.

**Q4:** "Why would a dev switch to this?"
Scaffold: "Faster? Simpler API? Better types? Fewer deps? More opinionated? Less opinionated? What's the wedge?"

**Q5:** "Target ecosystem — languages, frameworks, platforms?"
Scaffold: "Node.js only? Any JS runtime? Python 3.10+? Multi-language? This constrains everything."

## Phase 3: Deep Dive

**API design session:**
Walk through the 3 most common use cases. For each: what's the ideal code? What's the config? What are the defaults?

**Error experience:**
"When something goes wrong, what does the dev see? Good error messages are the #1 differentiator for dev tools."

**Documentation-first design:**
"Write the README before the code. What sections does it need? Getting started, API reference, examples, migration guide?"

**Distribution:**
"How do people install this? npm/pip/cargo/brew? How do they discover it? What's the onboarding — time from `install` to `working example`?"

## Pre-Mortem Failure Scenarios

- "The API is powerful but the learning curve is too steep"
- "A competitor has better documentation and examples"
- "Breaking changes alienate early adopters"
- "Only works in a narrow set of environments"
- "No one discovers it — distribution is the bottleneck"
- "The maintained dependency burden becomes unsustainable"
