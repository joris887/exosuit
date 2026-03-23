# 2. Coding Standards

## Research Prompt

```
I need deep research on coding standards documentation best practices. The goal is to determine the best possible approach for a generic coding standards template that works for ANY programming language and is specifically optimized for AI-assisted development — where an AI reads these standards to write code that follows project conventions.

**Framework context:** This template is part of the JD-LLM Development Framework — a language-agnostic AI development framework for Claude Code. The template is populated by a bootstrap process that detects the project's stack and configures standards accordingly. It must:
- Work for ANY language (Python, TypeScript, Go, Rust, Java, Ruby, Swift, C#, PHP, Dart, Kotlin, C/C++)
- Be actionable for AI — every standard should be followable without ambiguity
- Support multi-language projects (shared conventions + per-language sections)
- Stay under 200 lines per language section (strict context budget)
- Distinguish what formatters/linters handle vs what needs AI judgment

**Research areas** (starting points — include anything significant you discover beyond these):

1. **Industry-Leading Style Guides** — Google's guides, Airbnb JS, Microsoft .NET, Rust's official guide, PEP 8/257. What level of specificity actually helps? When does it become noise?

2. **Standards That AI Can Enforce** — Which standards can be verified by tooling? Which require judgment? How should standards be written so AI follows them consistently? Research on AI compliance with coding conventions — what phrasings work best?

3. **Structure & Organization** — How to organize for multi-language projects. Naming conventions (tables vs prose vs examples). Error handling patterns. When to prescribe vs defer to the formatter.

4. **Testing Standards (as part of coding)** — Test naming, assertion styles, organization, quality criteria expressed as standards.

5. **AI-Specific Coding Anti-Patterns** — Patterns AI commonly generates that violate good standards. How to document "don't do this" effectively. Standards that prevent code slop without being restrictive.

6. **Keeping Standards Alive** — Preventing standards rot. Automated enforcement vs manual review balance. How companies evolve standards.

Focus on what makes standards EFFECTIVE (actually followed) rather than COMPREHENSIVE (covers everything).

**Required output format:**
1. Executive summary
2. Per-topic findings with citations
3. **Recommended template structure** — propose the specific organization, section hierarchy, and format (tables? examples? prose?) that produces the highest AI compliance, with justification
4. **Recommended enforcement strategy** — what to automate vs what to express as standards
5. Knowledge gaps
```

## Implementation Prompt

```
I have completed deep research on coding standards best practices. The research findings are saved in docs/research/coding-standards.md (or I will paste them below).

Your task: Update the framework's CODING_STANDARDS.md template to be the best possible generic coding standards format, guided by the research findings.

**Hard constraints (non-negotiable):**
- File locations: docs/reference/CODING_STANDARDS.md AND scaffold/docs/reference/CODING_STANDARDS.md
- Budget: ≤200 lines for universal section + ~50 per language section
- Must work for ANY language
- Must support multi-language projects
- Populated by /bootstrap based on detected stack — include <!-- guidance comments --> for bootstrap

**Instructions:**
1. Read the current CODING_STANDARDS.md at docs/reference/CODING_STANDARDS.md
2. Read the research findings thoroughly
3. Implement the template structure, format, and enforcement strategy the research recommends — trust the research over your own defaults
4. Update scaffold/docs/reference/CODING_STANDARDS.md to match
5. If the research recommends changes to how rules enforce standards (e.g., .claude/rules/code-slop.md), note them but don't change rules without verification

**Outcome criteria (how to evaluate the result):**
- An AI reading this document produces code indistinguishable from a senior developer on the team
- Every standard is unambiguous — no room for AI interpretation drift
- Clear separation between tool-enforced standards and AI-judgment standards
- Bootstrap can populate language-specific sections from stack detection
- Under context budget
```
