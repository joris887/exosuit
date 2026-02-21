# Vision Folder

This folder is for the **new project flow**. Use it when starting a project from scratch.

## How to Use

### Step 1: Research Your Idea

Open `BRAINDUMP_PROMPT.md`. It contains a structured research prompt with clear sections to fill in.

### Step 2: Run Deep Research

Copy the filled-in prompt into Claude Projects, ChatGPT, Perplexity, or your preferred AI research tool. Have a deep conversation — explore the problem space, challenge assumptions, ask follow-ups.

### Step 3: Save Output

Save the final structured output back here as `.md` files. Name them descriptively:
- `research-output.md` — Main specification
- `architecture-proposal.md` — If architecture was discussed separately
- `competitive-analysis.md` — If alternatives were analyzed

### Step 4: Generate Project

Run `/bootstrap` in Claude Code. It reads everything in this folder and generates:

- **PRD summary** → `docs/reference/PRD_SUMMARY.md`
- **Architecture** → `docs/architecture/ARCHITECTURE.md`
- **Epic structure** → `docs/reference/BACKLOG_INDEX.md`
- **Typed stories** → `docs/reference/backlog/E01-*.md` through `E0N-*.md`
- **Project config** → `CLAUDE.md`

### Alternative: Quick Start

Don't want to do deep research? Run `/bootstrap` with an empty vision folder. It will ask you to describe your idea inline and will ask clarifying questions before generating.

## Note for Existing Projects

If you're adding the framework to an existing codebase, you can delete this folder. The `/bootstrap` skill will detect your existing code and auto-configure instead.
