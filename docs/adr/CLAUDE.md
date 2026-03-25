# Architecture Decision Records

Decision log for significant architectural choices. **Before proposing any implementation approach, check ADRs in this directory for relevant prior decisions.**

## Key Rules
- Respect all `status: accepted` ADRs — do not propose approaches that contradict them
- Do not propose approaches listed in `rejected-options` frontmatter of any ADR
- Check `Reconsider when` conditions before suggesting a rejected alternative is now viable
- ADRs are immutable once accepted — create a superseding ADR to change a decision
- Use `TEMPLATE.md` format with YAML frontmatter for all new ADRs

## Anti-Patterns (do NOT generate these)
- **Rubber-stamp ADR** — no real alternatives considered. Every ADR MUST have ≥1 rejected option with specific rationale.
- **Mega-ADR** — scope too broad. One decision per ADR. If it covers multiple decisions, split it.
- **Missing "why not"** — chosen option documented but rejected options lack rationale. The rejection rationale is the most valuable content.
- **Post-hoc rationalization** — ADR written long after implementation without acknowledging lost context. Flag with `confidence: low` if writing retroactively.
- **Signal drowning** — ADR for a trivial decision (library minor bump, style choice). Apply the reversibility test: if cheap to reverse, skip the ADR.

## Files
- `README.md` — full process, governance, and review workflow
- `TEMPLATE.md` — template for new ADRs (copy, don't modify)
- `NNNN-short-title.md` — individual decision records
