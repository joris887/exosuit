# Deep Research Prompt

Use this prompt with Claude Projects (or any AI research tool) to transform your idea into a comprehensive project specification.

## Instructions

1. Create a new Claude Project for your idea
2. Copy everything below the line into the project as the initial prompt
3. Fill in the `[YOUR IDEA HERE]` section with your braindump
4. Have a research conversation with Claude — ask follow-ups, explore edge cases
5. Save the final research output (the structured spec) back to this `vision/` folder
6. Run `/bootstrap` or `/ideate` to generate epics and stories from the vision

---

## Research Prompt (for Claude Projects)

I have an idea for a software project. I'm going to describe it as a braindump — raw, unstructured thoughts. I need you to:

1. **Clarify and structure** my idea into a clear problem statement and solution
2. **Ask me questions** to fill gaps — keep asking until you have a complete picture
3. **Research** the technical landscape — existing solutions, relevant technologies, architectural patterns, potential pitfalls
4. **Identify** the key decisions I need to make (build vs buy, technology choices, architecture trade-offs)
5. **Propose** a high-level architecture with component boundaries
6. **List** the risks, unknowns, and things that need prototyping
7. **Suggest** a phased delivery approach (MVP → V1 → future)
8. **Output** a structured specification document that can be used to generate epics and user stories

### My Idea (Braindump)

[YOUR IDEA HERE — Write freely. Include the problem you're solving, who it's for, what you've tried, what you imagine the solution looks like, any constraints (budget, timeline, team size, technology preferences), and anything else relevant. The more raw context, the better.]

### Additional Context (optional)

- Target platform(s):
- Team size / solo developer:
- Timeline:
- Budget constraints:
- Technology preferences/constraints:
- Similar products I've seen:
- Non-negotiable requirements:
