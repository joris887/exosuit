# Secrets Inventory

Track all secrets, credentials, and API keys used by the project. This file helps with rotation planning and access auditing.

**IMPORTANT:** This file tracks secret NAMES and metadata, NEVER secret VALUES.

## Active Secrets

| Name | Type | Storage | Last Rotated | Rotation Procedure | Owner |
|------|------|---------|-------------|-------------------|-------|
<!-- Example:
| DATABASE_URL | Connection string | .env | 2026-01-15 | Regenerate in cloud console, update .env | DevOps |
| STRIPE_SECRET_KEY | API key | Vault | 2026-02-01 | Rotate in Stripe dashboard | Payments team |
-->

## Rotation Schedule

| Frequency | Secrets |
|-----------|---------|
| Monthly | API keys for external services |
| Quarterly | Database credentials, SSH keys |
| On incident | Any potentially compromised secret |

## Rotation Procedure

1. Generate new credential in the source system
2. Update all environments (dev, staging, production)
3. Verify application works with new credential
4. Revoke old credential
5. Update "Last Rotated" in this inventory
