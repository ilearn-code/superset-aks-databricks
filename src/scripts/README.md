# PowerShell Scripts for Apache Superset on AKS

This directory contains PowerShell scripts for managing your Superset deployment on AKS.

## Scripts Overview

### 1. `init-db.ps1` - Initialize Superset Database

Initializes the Superset database with migrations, roles, and admin user.

**Usage:**
```powershell
.\init-db.ps1 -Environment dev
```

**Features:**
- Runs database migrations
- Initializes Superset
- Creates admin user (interactive)
- Optionally loads example data

### 2. `backup.ps1` - Backup Database

Creates database backups and optionally uploads to Azure Blob Storage.

**Usage:**
```powershell
# Local backup only
.\backup.ps1 -Environment dev -BackupLocation local

# Backup and upload to Azure
.\backup.ps1 -Environment prod -BackupLocation azure
```

**Features:**
- PostgreSQL database backup using pg_dump
- Azure Blob Storage integration
- Automatic retention policy (30 days in Azure, 7 days local)
- Retrieves credentials from Azure Key Vault
- Metadata tagging for Azure blobs

### 3. `restore.ps1` - Restore Database

Restores database from a backup file.

**Usage:**
```powershell
# Restore from Azure Blob Storage
.\restore.ps1 -Environment dev -BackupFile superset_backup_20251028120000.sql -BackupSource azure

# Restore from local file
.\restore.ps1 -Environment dev -BackupFile superset_backup_20251028120000.sql -BackupSource local
```

**Features:**
- Downloads backup from Azure Blob Storage
- Creates pre-restore backup automatically
- Scales down application during restore
- Terminates active database connections
- Runs database migrations after restore
- Provides rollback instructions

**⚠️ Warning:** This will replace all current data!

## Prerequisites

### Required Tools
- PowerShell 7+ (recommended)
- Azure CLI
- kubectl
- PostgreSQL client tools (pg_dump, pg_restore, psql)
- Docker (for image builds)

### Installation (Windows)

```powershell
# Install Azure CLI
winget install Microsoft.AzureCLI

# Install kubectl
az aks install-cli

# Install Helm
choco install kubernetes-helm

# Install PostgreSQL client tools
choco install postgresql

# Or download from: https://www.postgresql.org/download/windows/
```

## Common Workflows

### Initial Setup

```powershell
# 1. Initialize database
.\init-db.ps1 -Environment dev

# 2. Verify deployment
kubectl get pods -n superset
kubectl logs -f deployment/superset -n superset
```

### Backup Schedule

```powershell
# Create daily backup
.\backup.ps1 -Environment prod -BackupLocation azure

# Schedule with Windows Task Scheduler:
# Task Scheduler → Create Basic Task
# Action: Start a program
# Program: powershell.exe
# Arguments: -File "C:\path\to\backup.ps1" -Environment prod -BackupLocation azure
```

### Disaster Recovery

```powershell
# 1. List available backups
az storage blob list `
    --account-name stflashsupersetbackups `
    --container-name superset-backups `
    --prefix prod/ `
    --output table

# 2. Restore from backup
.\restore.ps1 `
    -Environment prod `
    -BackupFile superset_backup_20251028120000.sql `
    -BackupSource azure

# 3. Verify application
kubectl get pods -n superset
kubectl port-forward -n superset svc/superset 8088:8088
# Access http://localhost:8088
```

## Environment Configuration

Each script accepts an `-Environment` parameter:

- **dev**: Development environment (`rg-flash-superset-nonprod`, `aks-flash-superset-dev`)
- **staging**: Staging environment (`rg-flash-superset-staging`, `aks-flash-superset-staging`)
- **prod**: Production environment (`rg-flash-superset-prod`, `aks-flash-superset-prod`)

## Azure Key Vault Integration

Scripts automatically retrieve database credentials from Azure Key Vault:

- **dev**: `kv-flash-superset-dev`
- **staging**: `kv-flash-superset-stg`
- **prod**: `kv-flash-superset-prod`

**Required secrets:**
- `db-password`: PostgreSQL password
- `secret-key`: Superset secret key
- `databricks-token`: Databricks PAT (optional)
- `azure-client-secret`: Azure AD client secret (optional)

## Troubleshooting

### Script Execution Policy

If you get an execution policy error:

```powershell
# Check current policy
Get-ExecutionPolicy

# Allow script execution (run as Administrator)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Database Connection Issues

```powershell
# Test database connectivity
$POD_NAME = kubectl get pod -n superset -l app=superset -o jsonpath='{.items[0].metadata.name}'
kubectl exec -n superset $POD_NAME -- psql -h superset-postgresql -U superset -d superset -c "SELECT version();"
```

### Azure CLI Authentication

```powershell
# Re-authenticate with Azure
az login
az account set --subscription <YOUR-SUBSCRIPTION-ID>

# Check current subscription
az account show
```

### PostgreSQL Tools Not Found

```powershell
# Add PostgreSQL to PATH
$env:PATH += ";C:\Program Files\PostgreSQL\15\bin"

# Or install via Chocolatey
choco install postgresql --params '/Password:postgres'
```

## Advanced Usage

### Automated Backup with Retention

```powershell
# Create backup script with custom retention
param([int]$RetentionDays = 30)

.\backup.ps1 -Environment prod -BackupLocation azure

# Custom cleanup
$cutoffDate = (Get-Date).AddDays(-$RetentionDays)
az storage blob delete-batch `
    --account-name stflashsupersetbackups `
    --source superset-backups `
    --pattern "prod/*" `
    --if-unmodified-since $cutoffDate.ToString("yyyy-MM-ddTHH:mm:ssZ")
```

### Backup Verification

```powershell
# Download and verify backup
$BackupFile = "superset_backup_20251028120000.sql"
$LocalPath = "C:\temp\verify-backup.sql"

az storage blob download `
    --account-name stflashsupersetbackups `
    --container-name superset-backups `
    --name "prod/$BackupFile" `
    --file $LocalPath

# Check file size and integrity
Get-FileHash $LocalPath
Get-Item $LocalPath | Select-Object Name, Length, LastWriteTime
```

## Script Parameters Reference

### backup.ps1
- `-Environment` (string): Target environment (dev/staging/prod)
- `-BackupLocation` (string): Where to store backup (local/azure)

### restore.ps1
- `-Environment` (string): Target environment (required)
- `-BackupFile` (string): Backup filename (required)
- `-BackupSource` (string): Source location (local/azure)

### init-db.ps1
- `-Environment` (string): Target environment (dev/staging/prod)

## Best Practices

1. **Always test in dev first** before running in production
2. **Verify backups regularly** by testing restores in dev
3. **Monitor backup size** and adjust retention policies
4. **Use Azure Key Vault** for all credentials
5. **Document recovery procedures** for your team
6. **Schedule automated backups** for production
7. **Keep pre-restore backups** for at least 30 days

## Support

For issues or questions:
- Check logs: `kubectl logs -f deployment/superset -n superset`
- Review [docs/troubleshooting.md](../../docs/troubleshooting.md)
- Contact: your-team@your-domain.com

## Related Documentation

- [DEPLOYMENT.md](../../DEPLOYMENT.md) - Complete deployment guide
- [azure-devops-setup.md](../../docs/azure-devops-setup.md) - CI/CD setup
- [troubleshooting.md](../../docs/troubleshooting.md) - Common issues
