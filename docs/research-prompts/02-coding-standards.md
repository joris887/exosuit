# 2. Coding Standards

## Research Prompt

```
I need comprehensive deep research on coding standards documentation best practices. The goal is to create the ultimate generic coding standards template that works for ANY programming language and is specifically optimized for AI-assisted development — where an AI reads these standards to write code that follows project conventions.

Research these specific areas:

1. **Industry-Leading Style Guides**
   - Google's style guides (Python, Java, C++, Go, TypeScript) — structure, specificity, enforcement
   - Airbnb JavaScript Style Guide — why it became the most popular, what makes it effective
   - Microsoft's .NET coding conventions — how they structure multi-concern standards
   - Rust's official style guide — how a language-level standard works
   - PEP 8 and PEP 257 — Python's approach to conventions + documentation
   - What level of specificity actually helps? When does it become noise?

2. **Standards That AI Can Enforce**
   - Which coding standards can be verified by linters/formatters? (format vs. semantic)
   - Which require human judgment? (naming quality, abstraction decisions)
   - How should standards be written so that an AI follows them consistently?
   - Research on AI compliance with coding conventions — what phrasings work best?
   - How do you encode "follow nearby patterns" without listing every pattern?

3. **Structure & Organization**
   - How to organize standards for multi-language projects (shared vs. language-specific)
   - Naming convention formats (tables vs. prose vs. examples)
   - Error handling convention documentation — patterns that prevent silent failures
   - Import ordering standards — what actually matters
   - When to prescribe vs. when to defer to the formatter

4. **Testing Standards (as part of coding)**
   - Test naming conventions that communicate intent
   - Assertion style standards (specific vs. flexible)
   - Test organization standards (file naming, directory structure, fixture patterns)
   - What test quality rules can be expressed as standards?

5. **AI-Specific Coding Anti-Patterns**
   - Patterns AI commonly generates that violate good standards (over-abstraction, phantom packages, obvious comments)
   - How to document "don't do this" effectively for AI consumption
   - Standards that prevent code slop without being overly restrictive
   - How to balance "follow standards" with "use judgment"

6. **Keeping Standards Alive**
   - How to prevent standards rot (standards that nobody follows)
   - Automated enforcement vs. manual review — the right balance
   - When to update standards based on team evolution
   - How companies evolve their standards over time

For each finding, include source URLs, credibility assessment, specific examples, and whether it's universally applicable or language-specific. Focus on what makes standards EFFECTIVE (actually followed) rather than COMPREHENSIVE (covers everything).

Output a structured research report with recommendations for the optimal coding standards template structure.
```

## Implementation Prompt

```
I have completed deep research on coding standards best practices. The research findings are saved in docs/research/coding-standards.md (or I will paste them below).

Your task: Update the framework's CODING_STANDARDS.md template to be the best possible generic coding standards format.

**Context:** This template lives at docs/reference/CODING_STANDARDS.md (and scaffold/docs/reference/CODING_STANDARDS.md). It's populated by /bootstrap based on detected stack. It must:
- Work for ANY language (Python, TypeScript, Go, Rust, Java, Ruby, Swift, C#, PHP, Dart, Kotlin, C/C++)
- Be actionable for AI — every standard should be followable without ambiguity
- Support multi-language projects (shared conventions + per-language sections)
- Stay under 200 lines per language section (the framework's documentation rule budget)
- Include both "do this" and "don't do this" with examples
- Be enforceable — distinguish what formatters/linters handle vs. what needs AI judgment

**Instructions:**
1. Read the current CODING_STANDARDS.md at docs/reference/CODING_STANDARDS.md
2. Read the research findings
3. Redesign the template:
   - Universal Conventions section (all languages): file organization, naming, error handling, imports, configuration, API design
   - Per-Language section template: version, tools, formatting, naming overrides, idioms, common pitfalls
   - Testing Standards section: naming, assertions, organization, quality criteria
   - AI-Specific section: anti-patterns to avoid, slop detection, pattern following
4. Use tables and code examples — prose paragraphs are harder for AI to follow
5. Include <!-- guidance comments --> for bootstrap
6. Update scaffold version to match
7. Verify total stays within context budget (200 lines for universal + ~50 per language section)

Make this the coding standards document that, when read by an AI, produces code indistinguishable from a senior developer on the team.
```
