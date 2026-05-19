Select the best tool for the current operation. Prefer MCP servers when available and beneficial; fall back to built-in tools otherwise.

## Decision Matrix

| Task | MCP Server (if available) | Built-in Fallback |
|------|--------------------------|-------------------|
| Verify API/library docs | Documentation server | Training data + `--help` |
| Web research | Search server | WebSearch / WebFetch |
| Cross-session memory | Memory server | `docs/sessions/` handoffs + `docs/brain/` |
| Browser testing | Browser automation server | Manual testing via `/manual-test` |
| Symbol refactoring | Code intelligence server | Grep + manual edit |
| Multi-file pattern edits | Pattern edit server | Edit tool file-by-file |

## Rules

- NEVER require MCP servers — always have a built-in fallback path
- Prefer MCP servers when they provide verified/authoritative data (docs, search results)
- Prefer built-in tools when the operation is simple or the MCP server adds latency without value
- If an MCP server call fails, fall back to built-in tools without blocking the workflow
