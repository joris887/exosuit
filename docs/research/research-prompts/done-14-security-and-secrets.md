# 14. Security Documentation & Secrets Management

## Research Prompt

```
I need deep research on security documentation and secrets management for software projects — specifically addressing the unique security risks of AI-assisted development where AI may introduce vulnerabilities, leak secrets, or install phantom dependencies.

**Framework context:** This template is part of the JD-LLM Development Framework — a language-agnostic AI development framework for Claude Code. Security is enforced at multiple layers:
- .claude/rules/security.md — auto-loaded rule with CWE checklist for security-sensitive files
- .claude/skills/security-audit/SKILL.md — quality agent for security review
- scaffold/docs/reference/SECRETS_INVENTORY.md — secret rotation tracking template
- .claude/hooks/post-edit-format.sh — automated secrets detection (pattern matching on every edit)
The framework must prevent AI-generated security vulnerabilities without excessive overhead.

**Research areas** (starting points — include anything significant you discover beyond these):

1. **OWASP & Security Standards** — OWASP SAMM, ASVS, Top 10 2021+, CWE Top 25. Which apply most to AI-generated code? NIST SSDF — what's practical for small teams?

2. **AI-Specific Security Risks** — Vulnerabilities in AI-generated code (academic papers, industry reports). Phantom dependency attacks. Prompt injection via code comments. Secret leakage patterns. Over-permissive code (CORS *, admin access). Supply chain attacks via AI (typosquatting, dependency confusion).

3. **Secrets Management** — Rotation best practices by secret type. Inventory formats. Scanning tools (detect-secrets, truffleHog, gitleaks). .env management. Vault patterns. Git history cleanup.

4. **Security Documentation Formats** — Threat modeling (STRIDE, PASTA, attack trees). Security as testable criteria. Compliance documentation (SOC 2, GDPR, HIPAA). Incident response docs. SBOM (CycloneDX vs SPDX).

5. **Security in CI/CD** — SAST, DAST, dependency scanning, container scanning. What blocks a PR? Tool comparisons per language.

6. **Security Culture** — Security champions model. Developer security education that works. "Shift left" — what actually works vs theater. Balancing security overhead with velocity.

**Required output format:**
1. Executive summary
2. Per-topic findings with citations
3. **Recommended security documentation set** — which documents to maintain and what each should contain, with justification
4. **Recommended secrets management lifecycle** — inventory, rotation, scanning, cleanup
5. **Recommended AI-specific security checklist** — ranked by frequency and severity
6. Tool recommendations per language
7. Knowledge gaps
```

## Implementation Prompt

```
I have completed deep research on security documentation and secrets management. The research findings are saved in docs/research/security-management.md (or I will paste them below).

Your task: Update the framework's security documentation to be the most effective security governance for AI-assisted development, guided by the research findings.

**Hard constraints (non-negotiable):**
- Files to update:
  - .claude/rules/security.md — auto-loaded rule for security-sensitive files
  - .claude/skills/security-audit/SKILL.md — quality agent skill
  - scaffold/docs/reference/SECRETS_INVENTORY.md — secret rotation tracking
  - .claude/hooks/post-edit-format.sh — secrets detection patterns section
- Must prevent the most common AI-generated security vulnerabilities
- Must track secrets without storing secret values
- Must integrate with the framework's quality gates
- Must support compliance requirements without excessive overhead

**Instructions:**
1. Read all current security-related files listed above
2. Read the research findings thoroughly
3. Implement the security documentation set, secrets lifecycle, and AI-specific checklist the research recommends — trust the research over your own defaults
4. Update scaffold versions to match
5. Verify the post-edit hook's secret patterns are comprehensive
6. Verify the security-audit skill's CWE checklist aligns with research

**Outcome criteria (how to evaluate the result):**
- Every common AI-introduced security vulnerability has a specific defense
- Secrets are tracked and rotation-managed without storing actual secret values
- The security rule catches vulnerabilities on every edit without false-positive fatigue
- The security audit skill provides comprehensive review without being a rubber stamp
- Works for web apps, APIs, CLIs, and libraries — not web-only
```
