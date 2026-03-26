# Agents Directory

Native Claude Code agents (subagents) that provide specialized personas for focused tasks.

## Usage
- Invoked via `claude --agent <name>` or from skills using subagent delegation
- Each `.md` file defines one agent persona with specific expertise and constraints
- Agents inherit project rules and hooks — they are not independent of the framework

## Available Agents
- `code-reviewer` — PR and code review with checklist enforcement
- `architecture-reviewer` — architectural fitness evaluation
- `codebase-explorer` — read-only exploration and analysis
- `integration-tester` — independent dynamic verification (runs tests and commands)
- `research-analyst` — web research with source quality scoring
- `security-analyst` — security-focused code audit
- `spec-reviewer` — specification and requirements review
- `performance-engineer` — performance analysis and optimization

## Conventions
- Keep agent files under 100 lines — agents are personas, not encyclopedias
- Agents should reference project rules/docs by path, not inline content
- Never add tool permissions beyond what the agent's role requires
