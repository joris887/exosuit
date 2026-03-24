# Disaster Prevention Checklist

Reference loaded by `/story-cycle` Phase 4a after the standard self-review. Targets specific categories of LLM-typical implementation failures.

For each category, actively search for the anti-pattern — don't just check a box.

## Wheel Reinvention

- [ ] Search the codebase for existing utilities that do what the new code does
  - `Grep` for function names similar to newly created functions
  - Check `utils/`, `helpers/`, `lib/`, `shared/`, `common/` directories
- [ ] If overlap found: refactor to use existing utility instead of duplicating

## Specification Drift

- [ ] Re-read each acceptance criterion from the approved plan
- [ ] For each criterion: does the implementation match the SPECIFICATION (what), not just the approach (how)?
- [ ] Flag any feature not in the AC that was added (YAGNI violation)
- [ ] Flag any AC that was partially implemented or subtly altered

## Integration Wiring

- [ ] Are all new routes/endpoints registered in the router/app entry point?
- [ ] Are all new exports added to barrel/index files?
- [ ] Are all new config values added to config schemas/defaults/env examples?
- [ ] Are all new components/modules imported where they're used?
- [ ] Are database migrations created for schema changes?

## File Structure

- [ ] Are new files in the correct directories per ARCHITECTURE.md?
- [ ] Do file names follow the existing naming convention in that directory?
- [ ] Are test files co-located with or mirroring source files per project convention?
- [ ] Are new directories justified (not single-file directories)?

## Regression Surface

- [ ] Do changes to shared utilities affect other callers? (search for all import sites)
- [ ] Do interface changes (function signatures, types, API shape) require updates in other files?
- [ ] Are there implicit contracts (environment variables, file paths, config keys) that changed?
- [ ] If a function's behavior changed: do all callers expect the new behavior?

## Architecture Documentation Staleness

- [ ] Did this story add, remove, or significantly restructure any components, modules, services, or data flows?
- [ ] If yes: flag `docs/architecture/ARCHITECTURE.md` for update in Phase 4e
- [ ] Did this story add a new external dependency or integration?
- [ ] If yes: verify it's reflected in the architecture diagram and Module Map
- [ ] Read the Update Triggers section of `docs/architecture/ARCHITECTURE.md` — does this story match any listed trigger?
- [ ] If yes: the architecture doc MUST be updated in Phase 4e — this is not optional
- [ ] Did you discover a non-obvious gotcha during implementation?
- [ ] If yes: add it to the Known Landmines section

Quick check: run `git diff --name-only` — if new directories were created or top-level modules added/removed, architecture likely changed.

## Red Flags — Stop If You Find:

| Finding | Severity | Action |
|---------|----------|--------|
| New utility duplicates existing one | High | Refactor to reuse existing |
| AC implemented differently than specified | High | Fix to match specification |
| New route/export not registered | Critical | Wire it up before proceeding |
| Files in wrong directory | Medium | Move before committing |
| Shared function changed without checking callers | High | Search all callers, verify compatibility |
