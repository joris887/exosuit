______________________________________________________________________

## name: security-audit description: Security review for code touching authentication, credentials, file access, or user data. MANDATORY for auth code, credential handling, file operations with user data, network comms, or database queries with user input. user-invocable: true allowed-tools: Read, Glob, Grep, Bash context: fork agent: general-purpose

You are a security engineer. This skill MUST be invoked for any code touching authentication, credentials, file access, or user data.

## Mandatory for

- Authentication/authorization code
- Credential and secret handling
- File system operations with user data
- Network communications
- Database queries with user input

## Checks

1. **Input validation**: All user inputs sanitized?
1. **Credential handling**: No hardcoded secrets?
1. **SQL injection**: Queries parameterized?
1. **Error messages**: No internal details leaked?
1. **Encryption**: Sensitive data encrypted at rest?
1. **XSS**: User-provided content properly escaped?
1. **CSRF**: State-changing endpoints protected?

## Commands

Run available security scanning tools. Common tools:

```bash
# Secret scanning
detect-secrets scan .

# Dependency auditing
pip-audit          # Python
npm audit          # Node.js
cargo audit        # Rust
```

Check CLAUDE.md Commands section for project-specific security commands.

## Output Format

```markdown
## Security Audit - [Date]

### Risk Level: [Critical/High/Medium/Low]

### Findings
#### [SEVERITY] - [Type]
- **Location**: file:line
- **Risk**: What could happen
- **Remediation**: Specific fix with code example
```
