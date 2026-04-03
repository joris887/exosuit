# Archetype: Automation / Integration

**Core Question:** "What manual process does this eliminate?"
**Examples:** Zapier-style connectors, corporate workflow automation, RPA, email processors

## Phase 2: Core Identity Questions

**Q1:** "What manual process does this automate?"
Scaffold: "Step by step. Who does it today? What tools do they touch? How long does it take? How often?"

**Q2:** "What triggers the automation?"
Scaffold: "New email arrives? Form submitted? Scheduled time? Threshold breached? Button pressed? Webhook received?"

**Q3:** "What systems talk to each other?"
Scaffold: "List every tool/API/database involved. 'Salesforce → Slack → Google Sheets → email notification.' Draw the chain."

**Q4:** "What happens when it goes wrong?"
Scaffold: "API is down? Data format changed? Duplicate records? Who gets notified? What's the fallback — manual process resumes?"

**Q5:** "Human-in-the-loop?"
Scaffold: "Fully autonomous (no human involved)? Human approval required at certain steps? Human override always available? The answer determines architecture."

## Phase 3: Deep Dive

**Process mapping:**
Map the complete current manual process: every step, every decision point, every handoff between people/systems. Identify which steps are deterministic (can automate) vs judgment-based (needs human).

**Integration inventory:**
For each system: What API exists? REST? Webhook? SDK? Rate limits? Auth method? Is there a sandbox for testing?

**Error handling strategy:**
"For each integration point: what if it fails? Retry? Queue? Alert? Skip? Roll back? The error handling IS the automation — happy path is easy."

**Monitoring and observability:**
"How do you know it's working? Dashboard? Logs? Alerts? How do you detect silent failures (automation runs but produces wrong results)?"

## Pre-Mortem Failure Scenarios

- "The API of a key integration changes or breaks"
- "Edge cases cause incorrect automated decisions"
- "Users don't trust the automation for critical tasks"
- "Error handling doesn't cover real-world failures"
- "The manual process was actually nuanced and hard to automate"
- "Rate limits throttle the automation during peak load"
