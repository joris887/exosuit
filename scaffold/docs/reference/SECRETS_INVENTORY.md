# Secrets Inventory

Track all secrets, credentials, and API keys used by the project. This file enables rotation planning, access auditing, and incident response.

**IMPORTANT:** This file tracks secret NAMES and metadata, NEVER secret VALUES.

## Active Secrets

| ID | Name | Type | Environment | Storage | Owner | Classification | Last Rotated | Next Due | Rotation Method |
|----|------|------|-------------|---------|-------|---------------|-------------|----------|-----------------|
<!-- Example:
| sec-db-001 | DATABASE_URL | database_credential | production | vault:prod/db | DevOps | critical | 2026-01-15 | 2026-04-15 | automated_vault |
| sec-stripe-001 | STRIPE_SECRET_KEY | api_key | production | vault:prod/stripe | Payments | critical | 2026-02-01 | 2026-05-01 | manual |
| sec-jwt-001 | JWT_SIGNING_KEY | jwt_signing | all | vault:shared/jwt | Platform | critical | 2026-01-01 | 2026-04-01 | automated_vault |
-->

## Rotation Schedule by Secret Type

| Secret Type | Frequency | Notes |
|-------------|-----------|-------|
| API keys (general) | 90 days | High-privilege keys: 30 days |
| Database credentials | 90 days | Prefer dynamic/ephemeral credentials (Vault, AWS IAM auth) |
| JWT signing keys | 90 days (symmetric) / 12 months (asymmetric) | Publish updated public keys via JWKS; maintain grace period |
| OAuth tokens | Access: 1 hour; Refresh: 90 days; Client secrets: 180 days | Short-lived access tokens are the primary defense |
| Encryption keys (symmetric) | Quarterly | Use key versioning — don't re-encrypt all data |
| Encryption keys (asymmetric) | 1–2 years | Per NIST SP 800-57 cryptoperiods |
| SSH keys | 12 months | Prefer certificate-based with short TTLs |
| TLS/SSL certificates | 90 days | Automate via Let's Encrypt or cloud provider |
| On incident | IMMEDIATELY | Any suspected compromise, employee departure, or detected exposure |

## Rotation Procedure

1. Generate new credential in the source system
2. Deploy new credential alongside old (dual-key overlap for zero downtime)
3. Update all environments (dev, staging, production)
4. Verify application works with new credential
5. Revoke old credential
6. Update this inventory: `Last Rotated` date, `Next Due` date
7. Log the rotation in the incident/change log

## Overdue Rotation Check

Run during `/weekly-maintenance`: scan the `Next Due` column for dates in the past.

- **≤7 days overdue:** Warning — schedule rotation this sprint
- **8–30 days overdue:** High priority — rotate within 48 hours
- **>30 days overdue:** Critical — rotate immediately and investigate why it was missed

## Incident Response for Exposed Secrets

If a secret is found committed to source control or exposed in logs:

1. **Rotate immediately** — treat as permanently compromised
2. **Remove from git history** — use `git-filter-repo` or BFG Repo-Cleaner (never `git filter-branch`)
3. **Force push** all branches and tags
4. **Notify team** — all members must delete local clones and re-clone
5. **Audit access logs** for the exposed credential's service
6. **Add to post-mortem** if the exposure was in production
7. **Update this inventory** with the new credential details
