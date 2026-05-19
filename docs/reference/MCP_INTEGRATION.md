---
updated: 2026-02-23
purpose: MCP server selection guide and integration patterns for enhanced workflows
---

# MCP Server Integration Guide

MCP (Model Context Protocol) servers extend Claude Code with specialized capabilities. This guide helps select the right server for each task type and integrate them with framework workflows.

All framework skills work without MCP servers. When available, MCP servers enhance specific workflows with better data, faster research, or persistent memory.

## Server Categories

### Documentation Servers

**Use when:** Verifying API compatibility, checking library behavior, preventing hallucinated APIs.

**Integration points:**
- story-cycle Phase 1c (codebase research) — verify external API contracts
- debug-session Phase 1d (backward tracing) — confirm expected library behavior
- bootstrap A1 (stack detection) — verify framework version capabilities

**Example servers:** Context7, official doc lookup tools

### Memory/Persistence Servers

**Use when:** Cross-session context is critical, handoff files aren't sufficient, or project context is complex.

**Integration points:**
- continue (session resumption) — restore rich context beyond file-based handoffs
- handoff (session end) — persist structured state
- story-cycle Phase 1g (plan completeness) — recall decisions from prior sessions

**Example servers:** Serena, knowledge graph tools

### Search Servers

**Use when:** Research requires current information beyond training data, fact-checking external claims.

**Integration points:**
- brainstorm (design exploration) — research existing solutions and patterns
- story-cycle spike/research type — gather external information
- debug-session Phase 2 (pattern analysis) — find known issues in libraries

**Example servers:** Tavily, web search tools

### Browser Automation Servers

**Use when:** E2E testing, visual validation, or interaction with web UIs is needed.

**Integration points:**
- UAT-cycle — automate acceptance test execution
- manual-test — validate UI behavior programmatically
- testing-cycle — reproduce user-reported UI issues

**Example servers:** Playwright MCP, browser automation tools

### Code Intelligence Servers

**Use when:** Safe refactoring across large codebases, symbol renaming, type-aware operations.

**Integration points:**
- story-cycle refactoring type — safe cross-file symbol operations
- architecture-check — dependency analysis via LSP

**Example servers:** LSP-based tools, language-specific analyzers

### ADR Management Servers

**Use when:** Projects with many ADRs that benefit from programmatic querying, filtering, and creation of architecture decision records.

**Integration points:**
- architecture-check — query ADRs by tag, status, or rejected-options for compliance checks
- story-cycle Phase 1e — filter relevant ADRs by domain tags before planning
- brainstorm — scan rejected-options across all ADRs before proposing alternatives

**Example servers:** `adrs` (Rust) MCP server — 15 tools for ADR creation, querying, and management. Supports MADR 4.0 templates.

## Selection Decision Tree

```
Need current/external information?
  → YES: Search server
  → NO: Continue

Need to verify API/library behavior?
  → YES: Documentation server
  → NO: Continue

Need cross-session memory beyond handoff files?
  → YES: Memory server
  → NO: Continue

Need browser interaction or visual validation?
  → YES: Browser automation server
  → NO: Continue

Need type-aware refactoring across many files?
  → YES: Code intelligence server
  → NO: Built-in tools are sufficient
```

## Graceful Degradation

All framework skills function without MCP servers:
- Documentation verification → rely on training data + `--help` flags
- Memory persistence → use `docs/sessions/` handoff files and `docs/brain/` knowledge base
- Search → use WebSearch/WebFetch built-in tools
- Browser automation → manual testing with `/manual-test`
- Code intelligence → Glob + Grep + careful manual refactoring

## Configuration

MCP servers are configured in Claude Code settings (not in the framework). The framework detects available servers and uses them when beneficial.

After `/bootstrap`, check `CLAUDE.md` for detected MCP servers. If servers are added later, note them manually in the Commands section.
