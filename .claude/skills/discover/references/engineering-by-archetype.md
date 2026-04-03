# Engineering Adaptation by Archetype

## Testing Strategy Per Archetype

### Utility / Productivity
Standard TDD. Full unit + integration + E2E pyramid. AC: Given/When/Then.

### Experiential / Entertainment
Hybrid approach:
- Deterministic logic (scoring, state, data): full TDD
- Visual output: visual regression testing (screenshot baselines)
- Performance: automated framerate + load time benchmarks
- Experience quality: structured playtest protocol (manual)

AC template (layered):
- Layer 1 — Technical: FPS ≥ 60, load < 3s, no console errors
- Layer 2 — Functional: state transitions correct, input response < 100ms
- Layer 3 — Experience: ≥ 4/5 playtesters report target emotion
- Layer 4 — Creative sign-off: approved by project owner

### Viral / Shareable
- Share artifact generation: unit tests for correct output format
- Social meta tags: automated OG tag validation
- Load under spikes: load testing
- Mobile rendering: visual regression across devices
- Input validation: edge case testing
- AC: share card renders on Twitter/FB/WhatsApp, flow < 60s, artifact self-explanatory, handles 10K concurrent

### Educational / Explanatory
- Data accuracy: unit tests for calculations/transforms
- Narrative flow: E2E tests for scroll progression
- Accessibility: automated a11y (axe-core)
- Visual regression: baseline per viewport
- Comprehension: structured user test

### Creative Expression
Standard TDD for backend. Visual regression for UI. Performance for data ops. Accessibility.

### Personal / Hobby
Lean: test core workflow, smoke test happy path, manual verification fine.

### Developer Tool / Library
- Full TDD for all public APIs
- Integration tests per supported platform/version
- API contract testing
- Documentation tests (code examples must execute)
- Time-to-first-use benchmark

### Data & Analytics / Dashboard
Standard TDD for backend. Visual regression. Performance for data queries. Accessibility.

### Marketplace / Platform
- Full TDD for transaction logic
- Integration tests for payment/trust systems
- E2E for both supply and demand flows
- Load testing for concurrent transactions
- Security testing for payment data

### Automation / Integration
- Full TDD for automation logic
- Integration tests for each connected system (with mocks)
- Error handling/retry tests
- Idempotency tests
- Monitoring/alerting tests

## Converting Subjective Goals to Testable AC

"It should feel whimsical" becomes:
- Animation easing uses bounce/elastic curves (not linear)
- Color palette matches approved "playful" reference board
- ≥ 4/5 playtesters smile or express delight in first interaction
- Interaction response < 100ms
- Framerate ≥ 60fps during all animations

"It should feel professional" becomes:
- No animation overshoot or bounce
- Color palette uses ≤ 4 colors from approved brand guide
- Typography follows a strict scale (no arbitrary sizes)
- All states have loading indicators
- Error messages use professional tone (no exclamation marks)

## Success Criteria Templates Per Archetype

### Utility / Productivity
- Activation rate: X% of sign-ups complete core workflow in first session
- Retention: X% return within 7 days
- Task completion time: X minutes (vs Y minutes with current solution)
- Circuit breaker: if activation < X% after N users, pivot

### Experiential / Entertainment
- Playtest emotion match: ≥ X/5 playtesters report target emotion
- Session length: average ≥ X minutes
- Return rate: X% play again within 7 days
- Circuit breaker: if emotion match < X/5 after N playtests, redesign core loop

### Viral / Shareable
- Shares per user: ≥ X
- Completion rate: X% finish the experience
- Platform reach: shared on ≥ X platforms
- Viral coefficient: ≥ X (each user brings X new users)
- Circuit breaker: if shares/user < X after N users, redesign share moment

### Educational / Explanatory
- Completion rate: X% reach the end
- Comprehension: X% answer the key question correctly after
- Shares: X% share with others
- Circuit breaker: if completion < X% after N visitors, simplify narrative

### Creative Expression
- Creations per user: ≥ X in first session
- Share rate: X% of creations are shared/exported
- Return rate: X% create again within 7 days

### Personal / Hobby
- Do YOU use it daily? (binary: yes/no)
- Does it save YOU time? (minutes saved per use)

### Developer Tool / Library
- Time to first use: < X minutes from install
- Community adoption: X stars/downloads in first month
- Documentation completeness: all public APIs documented with examples

### Data & Analytics / Dashboard
- Time to insight: < X seconds to answer the primary question
- Decision accuracy: users make correct decision X% of the time
- Return frequency: checked X times per week

### Marketplace / Platform
- Supply sign-ups: X in first month
- Demand sign-ups: X in first month
- First transaction: within X days of launch
- Disintermediation rate: < X% go around the platform

### Automation / Integration
- Process time saved: X hours/week vs manual
- Error rate: < X% vs manual process
- Uptime: X% availability
- Circuit breaker: if error rate > manual after X runs, reassess automation scope
