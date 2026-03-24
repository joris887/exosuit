# Security documentation and secrets management for AI-assisted development

**AI code generation tools produce vulnerable code 40–45% of the time, introduce 2.74× more vulnerabilities than human-written code, and increase secret leakage by 40%.** These findings, drawn from peer-reviewed studies at Stanford, NYU, and USENIX alongside 2025 industry reports from Veracode, Apiiro, and CodeRabbit, make security-by-default architecture not optional but essential for any framework governing AI-assisted development. The JD-LLM Development Framework's multi-layer enforcement model (rules, skills, hooks, templates) maps directly to the defense-in-depth strategy that NIST SP 800-218A, OWASP SAMM, and OWASP ASVS collectively prescribe. This report provides the evidence base, tooling comparisons, and actionable checklists needed to implement that model.

---

## 1. Executive summary

AI-generated code amplifies known vulnerability classes rather than introducing novel ones. **CWE-79 (XSS), CWE-89 (SQL injection), CWE-78 (OS command injection), CWE-94 (code injection), and CWE-798 (hardcoded credentials)** dominate AI-generated vulnerabilities — all appearing in MITRE's 2024 CWE Top 25. A new attack class, "slopsquatting" (AI hallucinating non-existent packages that attackers register), affects **19.7% of all AI-recommended packages** per the USENIX Security 2025 study. Prompt injection via code comments reached **84% attack success rates** against mainstream coding agents.

The defensive response requires three interlocking systems: (1) automated scanning in every pipeline stage, from pre-commit hooks through deployment gates; (2) a secrets management lifecycle with automated rotation, inventory tracking, and layered detection; and (3) security documentation that embeds testable criteria into developer workflows rather than living in unread policy binders. STRIDE threat modeling, OWASP ASVS Level 2 controls, and NIST SP 800-218/218A provide the standards backbone. Semgrep + CodeQL for SAST, Gitleaks + TruffleHog for secrets, Trivy for containers, and Dependabot/Renovate for dependencies form the recommended open-source toolchain across all major language ecosystems.

---

## 2. OWASP and security standards for AI-generated code

### OWASP SAMM: five practices demand immediate attention

OWASP SAMM v2.0 defines 15 security practices across 5 business functions, each with 3 maturity levels. When AI generates code, five practices become critical:

**Secure Build** (Implementation) governs how AI-generated code enters the pipeline. Stream B specifically covers software dependencies — directly relevant to AI package hallucination risks. **Security Testing** (Verification) must shift from "sufficient for human-authored code" to "mandatory for all AI output" given the 40–45% vulnerability rate. **Security Architecture** (Design) matters because AI lacks architectural context; it generates functional code that may violate trust boundaries. **Education & Guidance** (Governance) must now include training developers to critically review AI output. **Defect Management** (Implementation) must handle the higher defect volume AI introduces.

For a small team, start at SAMM Maturity Level 1 across these five practices before advancing any single practice to Level 2. The OWASP GenAI Security Project provides supplementary guidance.

### OWASP ASVS: 286 controls, prioritized for AI risks

ASVS v4.0.3 contains **286 verification requirements** across 14 chapters at three assurance levels. Level 1 (penetration-testable) applies to all applications; Level 2 (standard assurance) applies to most applications handling sensitive data; Level 3 (high assurance) applies to critical systems.

The chapters most relevant to AI-generated code are:

- **V5 (Validation, Sanitization, Encoding):** AI fails input sanitization in **86% of XSS cases and 88% of log injection cases** per Veracode's 2025 cross-model evaluation. Every AI-generated endpoint needs V5 controls.
- **V6 (Cryptography):** AI achieves only an 86% pass rate on cryptographic implementations, frequently selecting deprecated algorithms like MD5 or hardcoding keys.
- **V2 (Authentication):** AI routinely generates auth code with hardcoded credentials, weak password policies, and missing MFA.
- **V13 (API Security):** AI-generated APIs commonly lack authentication middleware and rate limiting.
- **V14 (Configuration):** AI uses default configurations and does not apply security headers.

ASVS is comprehensively mapped to CWE identifiers, enabling direct traceability from framework requirements to specific weakness types.

### OWASP Top 10: the 2025 update elevates supply chain risk

The OWASP Top 10:2025, released November 2025, contains two significant changes from 2021. **Software Supply Chain Failures** enters at #3 as a new standalone category (previously "Vulnerable and Outdated Components" at #6), reflecting community alarm: **50% of survey respondents** ranked it their top concern. **Mishandling of Exceptional Conditions** enters at #10. SSRF was consolidated into Broken Access Control at #1.

AI amplifies these risks asymmetrically. Injection (A05) is amplified VERY HIGH — AI fails sanitization most of the time. Supply Chain Failures (A03) is amplified HIGH due to package hallucination. Broken Access Control (A01) is amplified HIGH because AI lacks business context for authorization logic. Cryptographic Failures (A04) carries a 14% insecurity rate in AI-generated crypto code.

The separate **OWASP Top 10 for LLM Applications 2025** (v2.0, released November 2024) directly governs AI coding assistants. Prompt Injection (LLM01) retained #1. New entries include System Prompt Leakage (LLM07) and Vector/Embedding Weaknesses (LLM08). Supply Chain (LLM03) became standalone, covering package hallucinations and poisoned training data.

### CWE Top 25: AI reproduces the most dangerous weaknesses

The 2024 CWE Top 25 (published November 2024, based on 31,770 CVE records) ranks CWE-79 (XSS) at #1 with score 56.92, followed by CWE-787 (out-of-bounds write) and CWE-89 (SQL injection). Notable movers include CWE-94 (Code Injection) surging from #23 to #11 and CWE-862 (Missing Authorization) rising from #11 to #9.

Schreiber & Tippe's 2025 large-scale analysis of 7,703 AI-generated files on GitHub found **4,241 CWE instances across 77 distinct vulnerability types**, with CWE-78 (OS command injection), CWE-94 (code injection), and CWE-259/798 (hardcoded credentials) dominating. Python code had the highest vulnerability rates at **16–18.5%**, JavaScript at 8.7–9%, and TypeScript at 2.5–7.1%. Four of the five most common CWEs in AI-generated code appear directly in MITRE's 2024 Top 25.

### NIST SSDF and its AI supplement are the authoritative government framework

NIST SP 800-218 v1.1 (the Secure Software Development Framework) defines four practice groups: **Prepare the Organization (PO)**, **Protect the Software (PS)**, **Produce Well-Secured Software (PW)**, and **Respond to Vulnerabilities (RV)**. For small teams of 1–10 developers, start with PO.1 (assign security roles, even part-time), PO.3 (define security requirements using ASVS), PW.5 (secure coding with SAST), PW.7 (code review), and RV.1 (vulnerability identification).

**NIST SP 800-218A** (finalized July 2024) is the most authoritative AI-specific secure development guidance available. Developed per Executive Order 14110 on AI safety, it adds practice PW.3 — "Confirm the Integrity of Training, Testing, Fine-Tuning, and Aligning Data Before Use" — and modifies existing SSDF practices with AI-specific tasks and priority ratings. It should be used alongside, not instead of, SP 800-218.

**ISO/IEC 42001:2023** is the first international standard for AI Management Systems, complementing ISO 27001 for organizations with AI components. ISO 27001:2022 introduced control **A.8.28 (Secure Coding)**, which explicitly names SAST scan reports as required audit evidence. SOC 2 Type II has **~80% overlap** with ISO 27001 and is increasingly incorporating generative AI risk management into audit scope.

---

## 3. AI-specific security risks: quantified and ranked

### The vulnerability rates are worse than assumed

The landmark studies paint a consistent picture:

The **NYU study** (Pearce et al., IEEE S&P 2022, Distinguished Paper Award) tested Copilot across 89 scenarios producing 1,689 programs. **40.73% of top suggestions were vulnerable**, spanning SQL injection, insecure crypto, and path traversal across 18 CWE categories.

The **Stanford study** (Perry et al., ACM CCS 2023) found participants with AI assistant access wrote **significantly less secure code** on 4 of 5 tasks — and were simultaneously **more likely to believe their code was secure** (trust score of 4.0 for insecure solutions vs. 1.5 for secure ones). This false confidence effect is arguably more dangerous than the vulnerabilities themselves.

**Veracode's 2025 GenAI Code Security Report** tested 100+ LLMs across 80 coding tasks: **45% of AI-generated code failed security tests**. Java was the riskiest language at 72% failure rate. AI-generated code contained **2.74× more vulnerabilities** than human-written code.

**Apiiro's September 2025 analysis** of Fortune 50 enterprises found AI-generated code introducing **over 10,000 new security findings per month** by June 2025 — a **10× increase** from December 2024. Privilege escalation paths jumped **322%**. Architectural design flaws spiked **153%**. CVSS 7.0+ vulnerabilities appeared **2.5× more often** in AI-generated code.

Model-specific performance varies dramatically. **GPT-4o** produces secure code in only **10% of cases** (20% with security prompting). **Claude 3.7 Sonnet** achieves **60% security by default** (100% with security-focused prompts) — demonstrating that explicit security instructions in system prompts and rules files have measurable impact.

### Slopsquatting: AI hallucinates packages attackers then weaponize

The **USENIX Security 2025 study** (Spracklen et al.) generated 576,000 code samples across 16 LLMs and found **19.7% of all recommended packages (440,445 of 2.23 million) were hallucinated**. They discovered **205,474 unique hallucinated package names**. Commercial models hallucinated at 5.2% vs. open-source models at 21.7%. Critically, **58% of hallucinated packages repeated** across runs and **43% appeared consistently every time**, making them predictable attack targets.

The term "slopsquatting" was coined by Seth Larson (PSF Developer-in-Residence). Real-world exploitation has been documented: a hallucinated package "huggingface-cli" was downloaded **over 30,000 times in three months**. Three malicious npm packages targeting Cursor (sw-cur, sw-cur1, aiide-cur) silently replaced core application files and installed persistent backdoors.

### Prompt injection through code reaches 84% success rates

The **"Rules File Backdoor" attack** (Pillar Security, March 2025) demonstrated that attackers can inject hidden malicious instructions into AI configuration files using Unicode obfuscation (zero-width joiners, bidirectional text markers). The attack works cross-agent — affecting both Cursor and GitHub Copilot.

The **"CopyPasta" virus** (HiddenLayer, 2025) represents the first practical **self-replicating prompt injection** for AI code assistants. It convinces the AI that a malicious payload is a "license file" requiring inclusion in every edited file, spreading across entire codebases semi-autonomously.

The **AIShellJack framework** implemented 314 unique attack payloads covering 70 MITRE ATT&CK techniques, achieving attack success rates as high as **84%** against Cursor and GitHub Copilot for executing malicious commands.

Critical CVEs in 2025 include **CVE-2025-54135 (CurXecute)** — indirect prompt injection enabling remote code execution in Cursor via MCP config files — and **CVE-2025-54136 (MCPoison)** — trust abuse enabling persistent team-wide compromise through silently swapped MCP configurations.

### Secret leakage is amplified 40% by AI tools

Research from CUHK and Sun Yat-sen University extracted **2,702 valid secrets** from 8,127 Copilot suggestions. **3.6% of valid Copilot secrets** never appeared during prompt construction — confirming training data memorization. GitGuardian's 2025 State of Secrets Sprawl report found repositories with Copilot active exhibit **6.4% secret leakage vs. 4.6% without** — a 40% increase. In 2024, **12.8 million secrets leaked** on public GitHub, a 28% year-over-year increase.

---

## 4. Recommended security documentation set

Based on cross-referencing SOC 2, GDPR, HIPAA, ISO 27001, and NIST CSF 2.0 requirements, the following documents form the minimum viable set for a framework-governed development team. Each document is justified by which compliance frameworks require it.

### Tier 1: must-have documents (implement immediately)

**Security Policy (Master)** — Establishes the security program, defines CIA objectives, assigns authority. Required by SOC 2 (CC1), ISO 27001 (Clause 5.2), HIPAA (§164.308). Update annually.

**Access Control Policy** — Defines least privilege, RBAC, MFA requirements, access reviews. Required by all major frameworks. Review quarterly; update annually.

**Incident Response Plan** — Four-phase NIST SP 800-61r3 lifecycle: Preparation → Detection & Analysis → Containment/Eradication/Recovery → Post-Incident Activity. Must include severity classification (P1–P4), escalation paths, communication templates (internal, executive, customer, regulatory), and evidence handling procedures. Required by SOC 2 (CC7.4), GDPR Article 33 (72-hour notification), HIPAA (§164.308). Update annually plus after every major incident.

**Threat Model Documentation** — Use **STRIDE** (the clear winner for small teams): create data flow diagrams, map each component to STRIDE categories, identify threats, prioritize mitigations. Tools: OWASP Threat Dragon (free, cross-platform) or Microsoft's "4 Questions" framework for rapid sessions. Update with each major architectural change or new feature.

**Secrets Management Policy** — Defines secret types, rotation schedules, vault requirements, scanning tools, cleanup procedures. See Section 5 below for full lifecycle. Required by PCI DSS 4.0, SOC 2, ISO 27001 A.9/A.10.

### Tier 2: build within first quarter

**AI Code Security Policy** — Unique to AI-assisted development. Defines: mandatory review requirements for AI-generated code, approved AI tools, prompt security guidelines (preventing context leakage), prohibited patterns (hardcoded credentials, wildcard CORS, disabled security features), SAST gate requirements for AI-generated PRs. Reference NIST SP 800-218A and OWASP Top 10 for LLM Applications.

**Data Classification Policy** — Defines levels (Public, Internal, Confidential, Restricted) and handling requirements per level. Required by SOC 2, GDPR (special categories), HIPAA (PHI/ePHI).

**Change Management Policy** — Governs how changes are proposed, approved, tested, and deployed. Required by SOC 2 (CC8.1), ISO 27001 (A.8.32).

**SBOM Generation Policy** — Use **CycloneDX** format (security-focused, VEX-native, ECMA-424 standard) for DevSecOps workflows; use SPDX (ISO/IEC 5962:2021) when license compliance is primary concern. Generate with cdxgen or Syft per release. Must meet NTIA minimum elements: supplier name, component name, version, unique identifiers, dependency relationships, SBOM author, timestamp.

### Tier 3: build within first six months

**Vendor/Third-Party Management Policy**, **Business Continuity & Disaster Recovery Plan**, **Privacy Policy with DPIA procedures** (mandatory for GDPR), **Security Awareness Training Policy**, **Data Retention & Disposal Policy**. These complete the overlapping requirements across SOC 2, GDPR, and HIPAA.

### Security requirements as testable criteria

Embed security acceptance criteria directly into user stories using Given/When/Then format:

```gherkin
Given a user submits a form with SQL injection payload
When the input is processed
Then the system rejects the input, returns a generic error, and logs the attempt

Given an authenticated user with "viewer" role
When they attempt to access an admin-only endpoint
Then the system returns 403 Forbidden and logs the unauthorized access attempt
```

Add evil user stories for security-relevant features: *"As an attacker, I want to manipulate object IDs to access sensitive data of other users."* These derive attack scenarios, security test cases, and development checklists. Use triggers during backlog refinement to flag security-relevant stories — not during sprint planning where all time is needed for estimation.

---

## 5. Recommended secrets management lifecycle

### Phase 1: inventory

Track every secret with a machine-readable inventory (JSON/YAML) containing these fields:

| Field | Example |
|-------|---------|
| `secret_id` | `sec-db-prod-001` |
| `secret_type` | `database_credential`, `api_key`, `jwt_signing`, `ssh_key`, `tls_cert`, `encryption_key` |
| `owner` | `platform-team` |
| `associated_service` | `user-service` |
| `environment` | `production` |
| `vault_location` | `vault:secret/data/prod/db-password` |
| `rotation_frequency` | `90_days` |
| `last_rotated` / `next_rotation_due` | ISO 8601 timestamps |
| `rotation_method` | `automated_vault`, `manual`, `dynamic` |
| `compliance_requirement` | `PCI-DSS`, `SOC2` |
| `classification` | `critical`, `high`, `medium` |

PCI DSS 4.0 explicitly requires maintaining an inventory of all trusted keys and certificates.

### Phase 2: rotation by secret type

| Secret Type | Rotation Frequency | Notes |
|-------------|-------------------|-------|
| API keys (general) | 30–90 days; high-privilege weekly | Automate with dual-key overlap for zero downtime |
| Database credentials | 30–90 days; prefer dynamic/ephemeral | Use Vault/AWS dynamic secrets for per-session credentials |
| JWT signing secrets | 90 days (symmetric); 6–12 months (asymmetric) | Publish updated public keys via JWKS; maintain grace period |
| OAuth tokens | Access tokens: 15 min–1 hr; refresh tokens: 30–90 days; client secrets: 90–180 days | Short-lived tokens are the primary defense |
| Encryption keys (symmetric) | Quarterly for data-at-rest | Use key versioning to avoid re-encrypting all data |
| Encryption keys (asymmetric) | 1–2 years | Per NIST SP 800-57 cryptoperiods |
| SSH keys | 6–12 months | Prefer certificate-based with short TTLs (Vault SSH engine) |
| TLS/SSL certificates | 90 days (industry trend) | Let's Encrypt defaults to 90 days; Apple/Google pushing toward 45–90 days |

**Critical rule**: Rotate immediately upon any suspected compromise, employee departure, or detected exposure — regardless of schedule.

### Phase 3: scanning (layered detection)

Deploy three layers of secret detection:

**Layer 1 — Pre-commit hook (Gitleaks):** Catches secrets before they enter local git history. Millisecond scans on staged changes. Configure via `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.1
    hooks:
      - id: gitleaks
        args: ["protect", "--staged"]
```

**Layer 2 — CI/CD pipeline (TruffleHog):** Runs on every push with live credential verification (key differentiator — confirms whether detected secrets are actually active). Use `--results=verified` to minimize actionable false positives.

**Layer 3 — Continuous monitoring (GitGuardian or GitHub Advanced Security):** Server-side scanning that cannot be bypassed with `--no-verify`. Provides dashboards, alerting, and historical scanning.

**Quarterly full-history scans** of all repositories catch anything missed by the above layers.

Research shows no single tool catches everything. Academic comparison found Gitleaks achieves 0.87 precision and TruffleHog 0.85 — using both together yields the best coverage.

### Phase 4: cleanup when secrets are committed

**Step 1: Rotate the secret immediately.** This is the most critical step. Treat any committed secret as permanently compromised.

**Step 2: Remove from history** using **git-filter-repo** (recommended by the Git project, fast, flexible) or **BFG Repo-Cleaner** (simpler for text replacement). Never use the deprecated `git filter-branch`.

**Step 3: Post-cleanup actions** — Force push all branches and tags. Notify all team members to delete local clones and re-clone. Contact GitHub Support to clear cached views on public repos. Implement pre-commit hooks to prevent recurrence. Verify cleanup by searching new history for the removed pattern.

### Vault selection for different team sizes

- **Solo/small team (≤5) already using 1Password**: 1Password Developer features — minimal overhead, `op://` secret references
- **Small team (≤10), developer-first**: **Doppler** — fastest onboarding, free tier for ≤3 users, excellent CLI
- **Single cloud (AWS/Azure/GCP)**: Use the native secrets manager (AWS Secrets Manager, Azure Key Vault, GCP Secret Manager) for lowest operational overhead
- **Enterprise, multi-cloud**: **HashiCorp Vault** — dynamic secrets, encryption-as-a-service, broadest integration ecosystem

### .env file discipline

Never commit `.env` files. Always maintain `.env.example` with variable names and non-sensitive defaults only. Set `chmod 600 .env`. Use a global gitignore (`git config --global core.excludesfile ~/.gitignore_global`) covering `.env`, `.env.*`, `*.pem`, `*.key`, `.secret`. In production, inject secrets at runtime from a vault — never use `.env` files. For encrypted `.env` sharing during development, use SOPS (Mozilla) with age encryption or dotenvx.

---

## 6. AI-specific security checklist, ranked by frequency and severity

This checklist is ordered by a composite score of how frequently the risk appears in AI-generated code and how severe the consequences are when it does.

### Critical priority (enforce via automated gates)

1. **Hardcoded credentials (CWE-798/259)** — Detected in code from ALL five evaluated LLMs. Copilot-active repos show 40% higher secret leakage. *Mitigation*: Pre-commit Gitleaks hook + CI TruffleHog scan. Block PR on any detection.

2. **Injection vulnerabilities (CWE-79, 89, 78, 94)** — XSS appears in 86% of AI-generated samples; SQL injection in 20%. *Mitigation*: SAST (Semgrep) on every PR with rules targeting input handling. Block PR on Critical/High findings.

3. **Package hallucination / slopsquatting** — 19.7% of AI-recommended packages don't exist; 5.2% for commercial models. *Mitigation*: Verify every AI-suggested dependency exists before adding. Implement lockfile integrity checks. Use Socket for malicious package behavioral analysis.

4. **Over-permissive configurations** — CORS wildcards, disabled security features, missing authentication middleware, excessive permissions (322% increase in privilege escalation paths). *Mitigation*: Custom Semgrep rules detecting `Access-Control-Allow-Origin: *`, missing auth middleware, and overly broad IAM policies.

### High priority (enforce via code review + tooling)

5. **Cryptographic failures (CWE-327)** — 14% insecurity rate; MD5/SHA1 usage, missing salts, insufficient key lengths. *Mitigation*: Semgrep/CodeQL rules banning deprecated algorithms. Provide framework-approved crypto wrappers in templates.

6. **Prompt injection via code comments** — 84% success rate in research. Rules File Backdoor and CopyPasta virus demonstrated real-world exploitation. *Mitigation*: Scan for hidden Unicode characters in configuration files. Restrict AI tool permissions to read-only where possible. Review all `.cursor/`, `.claude/`, and similar AI config files.

7. **Missing input validation (CWE-20)** — AI generates endpoints without server-side validation. *Mitigation*: Require ASVS V5 controls in acceptance criteria. Framework templates should include validation middleware by default.

8. **Insecure authentication patterns (CWE-287, 306)** — Missing MFA, weak session management, credential stuffing exposure. *Mitigation*: Provide pre-built auth modules in framework templates. Never let AI generate authentication from scratch.

### Medium priority (track and remediate)

9. **Excessive AI agency** — AI tools with terminal access, file write, and PR capabilities expanding attack surface. *Mitigation*: Principle of least privilege for AI tool permissions. Review MCP configurations. Limit AI to sandboxed environments.

10. **Dependency confusion / typosquatting** — AI recommending packages with similar names to legitimate ones. *Mitigation*: Pin dependencies. Use lockfiles. Configure registries to prevent public fallback in private package scenarios.

11. **Training data memorization** — AI reproducing real secrets, proprietary code, or PII from training data. *Mitigation*: Never trust AI-generated values for secrets, tokens, or keys — always generate fresh. Scan AI output for known secret patterns.

12. **False confidence effect** — Developers using AI believe their code is more secure than it is (Stanford study). *Mitigation*: Mandatory security review for AI-generated code regardless of developer confidence. Automated scanning provides objective assessment.

---

## 7. Tool recommendations by language ecosystem

### Recommended minimal security pipeline (all languages)

```
PR Created →
  1. Secrets scan (Gitleaks) — hard block on any found
  2. SAST (Semgrep, ~10s) — hard block on Critical/High
  3. Dependency scan (ecosystem-specific) — hard block on Critical/High
  4. Linting (language-specific security rules) — block on security rules

Nightly/Weekly →
  5. Deep SAST (CodeQL) — track all findings
  6. Container scan (Trivy --severity CRITICAL,HIGH) — block deployment
  7. DAST (ZAP/Nuclei against staging) — track findings

Release Gate →
  8. Full vulnerability report review
  9. SBOM generation (Syft or cdxgen)
```

### Python

| Category | Tools |
|----------|-------|
| SAST | **Semgrep** (710+ Pro rules, best Python support) + **Bandit** (free, Python-focused) |
| Dependencies | Dependabot + **pip-audit** + safety |
| Secrets | Gitleaks (pre-commit) + TruffleHog (CI) |
| Linting | **Ruff** (fast) + pylint |
| Container base | `python:3.x-slim` or `gcr.io/distroless/python3` |

### JavaScript / TypeScript

| Category | Tools |
|----------|-------|
| SAST | **Semgrep** (250+ Pro rules) + CodeQL |
| Dependencies | Dependabot + npm audit + **Socket** (malicious package detection) |
| Secrets | Gitleaks + GitHub Secret Scanning |
| Linting | ESLint + **eslint-plugin-security** + typescript-eslint |
| Container base | `node:lts-slim` or `gcr.io/distroless/nodejs22-debian12` |

### Rust

| Category | Tools |
|----------|-------|
| SAST | Semgrep (cross-function) + CodeQL (public preview, July 2025) |
| Dependencies | Renovate + **cargo-audit** (RustSec DB) + **cargo-deny** (licenses + bans) |
| Secrets | Gitleaks + TruffleHog |
| Safety | cargo-auditable + clippy |
| Container base | `gcr.io/distroless/static-debian12` (~2 MiB for static binaries) |

### Go

| Category | Tools |
|----------|-------|
| SAST | Semgrep + **gosec** (Go AST scanner) |
| Dependencies | Dependabot + **govulncheck** (official Go vulnerability tool) |
| Linting | **golangci-lint** (aggregates 60+ linters including gosec) |
| Container base | `gcr.io/distroless/static-debian12` |

### Java

| Category | Tools |
|----------|-------|
| SAST | **CodeQL** (highest benchmark F1: 74.4%) + Semgrep (190+ Pro rules) |
| Dependencies | Dependabot + **OWASP Dependency-Check** + Snyk (reachability analysis) |
| Linting | **SpotBugs + Find Security Bugs** plugin |
| Container base | `gcr.io/distroless/java21-debian12` |

### Swift

| Category | Tools |
|----------|-------|
| SAST | Semgrep + **MobSF/mobsfscan** (OWASP MSTG rules) |
| Dependencies | Dependabot (CocoaPods, SPM) + OWASP Dependency-Check |
| Linting | SwiftLint |
| Mobile security | MobSF (full framework, Docker-deployable) |

### SAST benchmark data (OWASP Benchmark v1.2, 2,740 Java test cases)

CodeQL achieved the highest F1 score at **74.4%** (65.5% accuracy, 97% recall). Semgrep CE scored 69.4% F1 (58.9% accuracy, 90.4% recall). However, a critical 2024 finding showed that **custom Semgrep rules improved detection from 17.1% to 44.7%** — a 181% improvement that outperformed all four benchmarked tools combined (38.8%). Rule coverage, not engine sophistication, is the primary lever for detection quality.

**Recommended approach**: Run both Semgrep (every PR, ~10 seconds) and CodeQL (nightly/weekly, deep semantic analysis). Both cost $30/committer/month for advanced features. Invest heavily in custom rule development.

### PR blocking criteria

| Severity | CVSS | Action |
|----------|------|--------|
| Critical | 9.0–10.0 | **Hard block** — must fix before merge |
| High | 7.0–8.9 | **Hard block** — must fix before merge |
| Medium | 4.0–6.9 | **Soft gate** — warn, allow merge with justification |
| Low | 0.1–3.9 | Informational — track, no block |

Block only on **new findings introduced by the PR**, not pre-existing issues. This prevents "boiling the ocean." Both Semgrep and CodeQL support diff-aware scanning. Integrate EPSS (Exploit Prediction Scoring System) to prioritize by actual exploitation likelihood alongside theoretical CVSS scores.

For false positive management: track `FP Rate = (confirmed FPs / total triaged) × 100`. Untuned SAST tools run 30–60% FP. Well-tuned tools achieve 10–20%. Maintain quarterly suppression audits and identify the 5 noisiest rules, which typically account for the majority of FPs.

---

## 8. Security culture that actually works

### The security champions model scales security knowledge

A Security Champions program embeds security-passionate developers within each team as a bridge to the central security team. The OWASP Security Champions Manifesto identifies ten guiding principles, led by "Be passionate about security" — self-selection outperforms arbitrary assignment. The recommended ratio is **1 champion per 10–20 developers**, with ~20% of work time dedicated to security activities.

Champions evangelize security, conduct code reviews, build threat models, investigate bounty reports, and serve as liaison to AppSec. Effective incentives include conference attendance, certification funding, career advancement pathways, and public recognition. Success metrics include reduction in vulnerability backlog, increased participation in security events, and whether champion recommendations are being implemented.

### Developer education must be hands-on and just-in-time

Hands-on practice with relevant technology stacks changes behavior; annual compliance training does not. Just-in-time learning triggered by real findings (via Snyk Learn, Secure Code Warrior) dramatically outperforms annual modules. Internal CTF competitions build attacker-perspective thinking — JFrog's custom CTF achieved "a high level of engagement across the entire organization." Amazon's Jet Anderson observes: "The gap between developers and security engineers isn't developer apathy — it's a lack of mutual understanding."

### Paved roads make security the path of least resistance

Netflix's "Paved Road" and Spotify's "Golden Path" (powered by Backstage) demonstrate that providing secure-by-default templates, pipelines, and building blocks achieves better security outcomes than telling developers what not to do. The JD-LLM Framework's template layer maps directly to this pattern — every template should include authentication middleware, input validation, security headers, and secrets management by default.

### Metrics that reveal actual security posture

**Mean Time to Remediate (MTTR)** is the single most important DevSecOps metric — segment by severity: Critical <7 days, High <30 days, Medium <90 days. **Vulnerability Escape Rate** (proportion discovered in production vs. pre-production) directly measures shift-left ROI; target under 10%. **Security Debt** as a weighted score: `(Critical × 10) + (High × 3) + (Medium × 1) + (Low × 0.1)`.

Track **leading indicators** (security requirement completion rate, threat model coverage, developer tool adoption) alongside lagging indicators (vulnerability count, incidents). DORA research demonstrates that elite delivery performers are also better security performers — speed and stability are correlated, not opposed.

### The cost-of-fixing claim deserves epistemic honesty

The widely cited "100× cost multiplier" for fixing bugs in production (attributed to IBM Systems Sciences Institute) has been seriously questioned. Laurent Bossavit investigated and found the study may not exist as formal research — it appears to originate from internal IBM training notes from ~1981. The directional claim — that bugs are more expensive to fix later — is logically sound and supported by practitioner experience. A more conservative estimate from DZone suggests **~30× higher costs** in production, not 100×. Use the directional argument, not specific multiplier claims, when making the business case for shift-left investment.

---

## 9. Knowledge gaps and rapidly evolving areas

**Agentic AI security is largely uncharted.** As coding agents gain autonomous privileges (terminal access, file write, PR management), the attack surface expands dramatically. CVE-2025-54135 and CVE-2025-54136 in Cursor demonstrate the risks but formal security frameworks for agentic AI development don't yet exist. The MCP (Model Context Protocol) permission model is still evolving.

**AI-generated code vulnerability benchmarks lack standardization.** Studies use different prompts, languages, and evaluation criteria, making cross-study comparison unreliable. The 40% (NYU) vs. 45% (Veracode) vs. 12.1% (Schreiber & Tippe) vulnerability rates reflect methodological differences, not conflicting findings. A standardized benchmark akin to OWASP Benchmark for SAST tools is needed.

**SBOM tooling accuracy is imperfect.** Academic research shows accuracy gaps across all SBOM generation tools — they miss dependencies declared without exact versions, optional/dev dependencies in some ecosystems, and binaries installed without package managers. Cross-validation with multiple tools is recommended for high-assurance use cases.

**Slopsquatting defenses are nascent.** No major package registry has implemented AI-hallucination-specific protections. Fine-tuning can reduce hallucination rates below 3% per the USENIX study, but registry-side defenses (like preemptive reservation of commonly hallucinated names) remain proposals, not implementations.

**Security culture metrics lack rigorous evidence.** While the security champions model is widely adopted and practitioner-endorsed, published controlled studies measuring its effectiveness against a control group are scarce. Most evidence is case-study and survey-based.

**Prompt injection defense is immature.** No comprehensive, framework-level defense against indirect prompt injection through code comments and configuration files exists. Current mitigations are reactive (scanning for Unicode anomalies, restricting AI permissions) rather than architecturally preventive. This is an active area of research where the JD-LLM Framework's hook layer could provide meaningful defense-in-depth by intercepting and validating AI context before code generation.

**Regulatory landscape is in flux.** The EU Cyber Resilience Act, EU AI Act, and evolving US Executive Orders (14028 on software supply chain, 14110 on AI safety) create compliance requirements that are still being operationalized. Organizations should monitor NIST SP 800-218A updates, CISA SBOM guidance revisions, and ISO/IEC 42001 adoption closely. By mid-2026, several of these requirements will move from recommendation to enforcement.