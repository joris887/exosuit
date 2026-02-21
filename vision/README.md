# Vision Folder

This folder is for the **new project flow**. Use it when starting a project from scratch.

## How to Use

1. Open `BRAINDUMP_PROMPT.md` — it contains a structured research prompt
2. Copy the research prompt into Claude Projects, ChatGPT, Perplexity, or your preferred AI research tool
3. Fill in the `[YOUR IDEA HERE]` section with your raw idea braindump
4. Have a deep research conversation — explore the problem space, ask follow-ups, challenge assumptions
5. Save the final structured output back here as `.md` files
6. Run `/bootstrap` to generate your project structure from the vision

## What Goes Here

- Research output from AI conversations
- Structured specifications
- Architecture proposals
- Technology evaluations
- Competitive analysis

## What Happens Next

When you run `/bootstrap` with content in this folder, the framework will:

- Generate a PRD summary (`docs/reference/PRD_SUMMARY.md`)
- Propose an architecture (`docs/architecture/ARCHITECTURE.md`)
- Create an epic structure (`docs/reference/BACKLOG_INDEX.md`)
- Generate individual epic files with typed stories (`docs/reference/backlog/`)
- Configure `CLAUDE.md` with your project overview

## Note for Existing Projects

If you're adding the framework to an existing codebase, you can delete this folder. The `/bootstrap` skill will detect your existing code and auto-configure instead.
