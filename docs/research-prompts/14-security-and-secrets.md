# 14. Security Documentation & Secrets Management

## Research Prompt

```
I need comprehensive deep research on security documentation and secrets management for software projects — specifically addressing the unique security risks of AI-assisted development where AI may introduce vulnerabilities, leak secrets, or install phantom dependencies.

Research these specific areas:

1. **OWASP & Security Standards**
   - OWASP SAMM (Software Assurance Maturity Model) — maturity levels for security practices
   - OWASP ASVS (Application Security Verification Standard) — verification checklist
   - OWASP Top 10 2021+ — which apply most to AI-generated code?
   - CWE Top 25 — mapping to AI-specific vulnerability patterns
   - NIST Secure Software Development Framework (SSDF) — what's practical for small teams

2. **AI-Specific Security Risks**
   - Research on security vulnerabilities in AI-generated code (academic papers, industry reports)
   - Phantom dependency attacks — how AI can be tricked into importing malicious packages
   - Prompt injection via code comments — how malicious code could influence AI behavior
   - Secret leakage patterns — how AI accidentally introduces credentials into code
   - Over-permissive code — how AI tends to use broad permissions (CORS *, admin access)
   - Supply chain attacks via AI — research on typosquatting and dependency confusion

3. **Secrets Management**
   - Secret rotation best practices — frequency by secret type
   - Secrets inventory formats — what to track (name, type, location, rotation date, owner)
   - Secret scanning tools: detect-secrets, truffleHog, gitleaks — comparison
   - .env management: dotenv patterns, .env.example, validation libraries
   - Vault patterns: HashiCorp Vault, AWS Secrets Manager, Azure Key Vault — when to use
   - Git history secret cleanup — BFG, git filter-repo approaches

4. **Security Documentation Formats**
   - Threat modeling documentation — STRIDE, PASTA, attack trees
   - Security requirements format — how to express security as testable criteria
   - Compliance documentation — SOC 2, GDPR, HIPAA checklists
   - Incident response documentation — what to have ready
   - SBOM (Software Bill of Materials) — CycloneDX vs SPDX, tooling per language

5. **Security in CI/CD**
   - SAST (Static Application Security Testing) — tools and integration patterns
   - DAST (Dynamic Application Security Testing) — when and how
   - Dependency scanning in CI — npm audit, pip-audit, cargo audit
   - Container scanning — if applicable
   - Security gates — what blocks a PR?

6. **Security Culture**
   - Security champions model — how to embed security in development teams
   - Security training that works — research on developer security education
   - "Shift left" security — what actually shifts left vs what's theater?
   - When security overhead kills velocity — finding the right balance

For each finding, include sources, tool comparisons, and assessment of overhead vs risk reduction.

Output a structured research report with: recommended security documentation set, secrets management lifecycle, AI-specific security checklist, and tool recommendations per language.
```

## Implementation Prompt

```
I have completed deep research on security documentation and secrets management. The research findings are saved in docs/research/security-management.md (or I will paste them below).

Your task: Update the framework's security documentation to be the most effective security governance for AI-assisted development.

**Context:** Security-related files:
- .claude/rules/security.md — auto-loaded rule for security-sensitive files
- .claude/skills/security-audit/SKILL.md — quality agent skill
- scaffold/docs/reference/SECRETS_INVENTORY.md — secret rotation tracking
- .claude/hooks/post-edit-format.sh — secrets detection (patterns section)

They must:
- Prevent the most common AI-generated security vulnerabilities
- Track secrets without storing secret values
- Integrate with the framework's quality gates
- Support compliance requirements without excessive overhead

**Instructions:**
1. Read all current security-related files
2. Read the research findings
3. Update security.md rule:
   - Verify CWE checklist is current (research may show new AI-specific patterns)
   - Add any new AI-specific anti-patterns from research
   - Verify fix-immediately patterns are comprehensive
4. Update security-audit SKILL.md:
   - Verify CWE checklist aligns with research
   - Update SBOM section with research findings
   - Add any new checking categories from research
5. Update SECRETS_INVENTORY.md template:
   - Verify rotation schedule aligns with research
   - Add compliance mapping section if research recommends it
6. Update post-edit-format.sh secret patterns:
   - Add any new credential patterns from research
7. Update scaffold versions to match

Make this the security layer that catches every AI-introduced vulnerability before it reaches production.
```
