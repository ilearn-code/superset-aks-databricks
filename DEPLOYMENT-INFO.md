# Superset Deployment Information

## Overview

This repository deploys Apache Superset to Azure Kubernetes Service using GitHub Actions for CI/CD, with Azure Key Vault handling runtime secrets.

## Current Deployment Snapshot

- Image: `acr<redacted>.azurecr.io/superset:<image-tag>`
- Commit: `<git-sha>`
- Environment: Development
- Namespace: `superset`
- Status: Running

## Access

- Application URL: `http://<external-ip>:8088`
- Health check: `http://<external-ip>:8088/health`

## Authentication

Do not store credentials in this file. Retrieve admin credentials from Azure Key Vault or your deployment pipeline secret store.

If you need to create a new admin user, use the standard Superset CLI:

```bash
kubectl exec -it deployment/superset -n superset -- superset fab create-admin \
  --username <username> \
  --firstname <firstname> \
  --lastname <lastname> \
  --email <email> \
  --password <password>
```

## Database and Cache

### PostgreSQL

- Host: `superset-postgresql`
- Port: `5432`
- Database: `superset`
- Username: `superset`
- Password: stored in Kubernetes secret or Key Vault

### Redis

- Host: `superset-redis`
- Port: `6379`
- Database: `0`

## Secrets Management

Sensitive values must remain outside source control.

Expected secret keys:

- `database-uri`
- `redis-uri`
- `secret-key`
- `guest-token-secret`
- `databricks-token`
- `postgres-password`

View only the key names, not the values:

```bash
kubectl get secret superset-secrets -n superset -o jsonpath='{.data}' | jq -r 'keys[]'
```

## CI/CD Flow

### GitHub Actions CI

Workflow: `.github/workflows/ci.yml`

Typical stages:

1. Lint and validate code
2. Validate Kubernetes and Helm manifests
3. Run tests
4. Build and push the container image
5. Publish build artifacts

### GitHub Actions CD

Workflow: `.github/workflows/cd-dev.yml`

Typical stages:

1. Authenticate with Azure
2. Fetch AKS credentials
3. Read secrets from Key Vault
4. Create Kubernetes secrets
5. Deploy with Helm
6. Run verification and smoke tests

## Common Commands

### View Deployment

```bash
./verify-deployment.sh
```

### View Logs

```bash
kubectl logs -f deployment/superset -n superset
```

### Enter the Pod

```bash
kubectl exec -it deployment/superset -n superset -- /bin/bash
```

### List Users

```bash
kubectl exec deployment/superset -n superset -- superset fab list-users
```

### Upgrade the Database

```bash
kubectl exec deployment/superset -n superset -- superset db upgrade
```

### Initialize Superset

```bash
kubectl exec deployment/superset -n superset -- superset init
```

## Verification

### Check the running image

```bash
kubectl get deployment superset -n superset -o jsonpath='{.spec.template.spec.containers[0].image}'
```

### Test database connectivity

```bash
kubectl exec deployment/superset -n superset -- \
  psql postgresql://superset:$(kubectl get secret superset-secrets -n superset -o jsonpath='{.data.postgres-password}' | base64 -d)@superset-postgresql:5432/superset -c '\dt'
```

### Check health

```bash
curl http://<external-ip>:8088/health
```

## Security Notes

1. Never commit real passwords, tokens, or connection strings.
2. Store production secrets in Azure Key Vault.
3. Prefer TLS, private networking, and network policies before publishing externally.
4. Rotate any secrets that were previously committed or shared.

## Next Steps

1. Log in to Superset using the current admin credentials from Key Vault.
2. Change the admin password immediately after first login.
3. Configure Databricks connectivity.
4. Add dashboards and alerts.
5. Enable SSL/TLS for public access.
6. Move all environment-specific values into Key Vault or pipeline variables.

## Metadata

- Last updated: 2026-06-12
- Deployment method: GitHub Actions CI/CD
- Environment: Development