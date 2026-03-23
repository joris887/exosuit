# Vision Directory

Braindump-to-backlog pipeline for new projects (Path B in /bootstrap).

## Files
- `BRAINDUMP_PROMPT.md` — structured prompt that guides users through project vision capture
- `README.md` — instructions for the braindump process

## How It Works
1. User fills out `BRAINDUMP_PROMPT.md` with their project vision (problem, users, features)
2. `/bootstrap` (Path B) reads the braindump and generates the full project scaffold
3. `/ideate` can also use braindump content for backlog generation

## Conventions
- The braindump prompt is language-agnostic — it asks about goals, not implementation
- Keep questions open-ended to avoid biasing toward specific solutions
- This directory is copied into new projects via scaffold — keep it self-contained
