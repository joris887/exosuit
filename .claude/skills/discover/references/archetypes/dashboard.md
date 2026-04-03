# Archetype: Data & Analytics Dashboard

**Core Question:** "What decision should this inform?"
**Examples:** Grafana, Metabase, admin panels, KPI dashboards, monitoring tools

## Phase 2: Core Identity Questions

**Q1:** "What decision can someone make after 10 seconds of looking at this?"
Scaffold: "'Are we on track?' 'Where's the problem?' 'What needs attention next?' 'Should we scale up?' The dashboard exists to answer ONE primary question fast."

**Q2:** "Who looks at this and how often?"
Scaffold: "CEO checks weekly? Ops team monitors all day? Customers self-serve? The audience determines complexity and refresh rate."

**Q3:** "What are the data sources?"
Scaffold: "APIs? Databases? CSV uploads? Real-time streams? Manual entry? List every source."

**Q4:** "What's the most important metric and its thresholds?"
Scaffold: "When is it green (all good), yellow (watch it), red (act now)? What number triggers action?"

**Q5:** "Real-time or periodic refresh?"
Scaffold: "Real-time (WebSocket/SSE — complex, expensive), Every minute, Every hour, Daily batch, On-demand refresh. What does the use case actually need?"

## Phase 3: Deep Dive

**Information hierarchy:**
"Rank the metrics: what's at the top (glanceable), what's in the middle (detailed view), what's buried (drill-down only)?"

**Interaction model:**
"Read-only dashboard, or can users take action from it? (e.g., approve/reject, trigger workflow, export data)"

**Alert and notification:**
"When a threshold is breached, what happens? Email? Slack? In-app notification? Who gets notified?"

**Data freshness and accuracy:**
"How stale can the data be before it's misleading? What happens if a source is down?"

## Pre-Mortem Failure Scenarios

- "Too many metrics — information overload, nothing stands out"
- "Data refresh is too slow for the use case"
- "Users don't trust the numbers (data accuracy issues)"
- "The dashboard is built but nobody checks it"
- "A data source API changes format and breaks the pipeline"
- "Performance degrades as data volume grows"
