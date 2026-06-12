# Restore Script for Superset Database
# PowerShell version with Azure Blob Storage integration
# Usage: .\restore.ps1 -Environment dev -BackupFile superset_backup_20251028120000.sql

param(
    [Parameter(Mandatory=$true)]
    [string]$Environment,
    
    [Parameter(Mandatory=$true)]
    [string]$BackupFile,
    
    [string]$BackupSource = "azure" # or "local"
)

$ErrorActionPreference = "Stop"

# Configuration
$LOCAL_BACKUP_DIR = "C:\backups\superset"
$STORAGE_ACCOUNT = "stflashsupersetbackups"
$CONTAINER_NAME = "superset-backups"

Write-Host "`n============================================" -ForegroundColor Green
Write-Host "Superset Database Restore" -ForegroundColor Green
Write-Host "============================================`n" -ForegroundColor Green

Write-Host "⚠️  WARNING: This will restore the database to a previous state!" -ForegroundColor Red
Write-Host "   All current data will be replaced with the backup data." -ForegroundColor Red
$confirmation = Read-Host "`nAre you sure you want to continue? (yes/no)"

if ($confirmation -ne "yes") {
    Write-Host "`nRestore cancelled." -ForegroundColor Yellow
    exit 0
}

# Get database credentials
Write-Host "`nRetrieving database credentials..." -ForegroundColor Yellow

if ($Environment -eq "prod") {
    $KV_NAME = "kv-flash-superset-prod"
    $NAMESPACE = "superset"
    $RESOURCE_GROUP = "rg-flash-superset-prod"
} elseif ($Environment -eq "staging") {
    $KV_NAME = "kv-flash-superset-stg"
    $NAMESPACE = "superset"
    $RESOURCE_GROUP = "rg-flash-superset-staging"
} else {
    $KV_NAME = "kv-flash-superset-dev"
    $NAMESPACE = "superset"
    $RESOURCE_GROUP = "rg-flash-superset-nonprod"
}

try {
    $DB_PASSWORD = az keyvault secret show `
        --vault-name $KV_NAME `
        --name "db-password" `
        --query value -o tsv
    
    Write-Host "✓ Retrieved database credentials" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to retrieve credentials from Key Vault" -ForegroundColor Red
    exit 1
}

# Database connection details
$DB_USER = "superset"
$DB_NAME = "superset"
$DB_HOST = "superset-postgresql.$NAMESPACE.svc.cluster.local"
$DB_PORT = "5432"

# Download backup from Azure if needed
$LOCAL_BACKUP_PATH = Join-Path $LOCAL_BACKUP_DIR $BackupFile

if ($BackupSource -eq "azure") {
    Write-Host "`nDownloading backup from Azure Blob Storage..." -ForegroundColor Yellow
    
    # Ensure local directory exists
    if (-not (Test-Path $LOCAL_BACKUP_DIR)) {
        New-Item -ItemType Directory -Path $LOCAL_BACKUP_DIR | Out-Null
    }
    
    try {
        $ACCOUNT_KEY = az storage account keys list `
            --resource-group $RESOURCE_GROUP `
            --account-name $STORAGE_ACCOUNT `
            --query '[0].value' -o tsv
        
        az storage blob download `
            --account-name $STORAGE_ACCOUNT `
            --account-key $ACCOUNT_KEY `
            --container-name $CONTAINER_NAME `
            --name "$Environment/$BackupFile" `
            --file $LOCAL_BACKUP_PATH `
            --overwrite
        
        Write-Host "✓ Backup downloaded from Azure" -ForegroundColor Green
    } catch {
        Write-Host "✗ Failed to download from Azure: $_" -ForegroundColor Red
        exit 1
    }
} else {
    # Check if local backup exists
    if (-not (Test-Path $LOCAL_BACKUP_PATH)) {
        Write-Host "✗ Backup file not found: $LOCAL_BACKUP_PATH" -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ Using local backup file" -ForegroundColor Green
}

# Create a pre-restore backup
Write-Host "`nCreating pre-restore backup..." -ForegroundColor Yellow
$TIMESTAMP = Get-Date -Format "yyyyMMddHHmmss"
$PRE_RESTORE_BACKUP = "superset_pre_restore_$TIMESTAMP.sql"
$PRE_RESTORE_PATH = Join-Path $LOCAL_BACKUP_DIR $PRE_RESTORE_BACKUP

$env:PGPASSWORD = $DB_PASSWORD

try {
    pg_dump `
        -h $DB_HOST `
        -p $DB_PORT `
        -U $DB_USER `
        -d $DB_NAME `
        -F c `
        -f $PRE_RESTORE_PATH
    
    Write-Host "✓ Pre-restore backup created: $PRE_RESTORE_BACKUP" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Warning: Pre-restore backup failed. Continuing anyway..." -ForegroundColor Yellow
}

# Scale down Superset pods
Write-Host "`nScaling down Superset application..." -ForegroundColor Yellow
kubectl scale deployment superset -n $NAMESPACE --replicas=0
Start-Sleep -Seconds 10
Write-Host "✓ Superset pods scaled down" -ForegroundColor Green

# Drop and recreate database
Write-Host "`nPreparing database for restore..." -ForegroundColor Yellow

try {
    # Terminate active connections
    $terminateQuery = @"
    SELECT pg_terminate_backend(pg_stat_activity.pid)
    FROM pg_stat_activity
    WHERE pg_stat_activity.datname = '$DB_NAME'
    AND pid <> pg_backend_pid();
"@
    
    $env:PGPASSWORD = $DB_PASSWORD
    $terminateQuery | psql -h $DB_HOST -p $DB_PORT -U postgres -d postgres
    
    Write-Host "✓ Terminated active connections" -ForegroundColor Green
} catch {
    Write-Host "! Could not terminate connections" -ForegroundColor Yellow
}

# Restore database
Write-Host "`nRestoring database..." -ForegroundColor Yellow

try {
    pg_restore `
        -h $DB_HOST `
        -p $DB_PORT `
        -U $DB_USER `
        -d $DB_NAME `
        --clean `
        --if-exists `
        --no-owner `
        --no-privileges `
        $LOCAL_BACKUP_PATH
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Database restored successfully" -ForegroundColor Green
    } else {
        throw "pg_restore failed with exit code $LASTEXITCODE"
    }
} catch {
    Write-Host "✗ Restore failed: $_" -ForegroundColor Red
    Write-Host "`n⚠️  IMPORTANT: Database may be in an inconsistent state!" -ForegroundColor Red
    Write-Host "   Consider restoring the pre-restore backup: $PRE_RESTORE_BACKUP" -ForegroundColor Yellow
    exit 1
} finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
}

# Scale up Superset pods
Write-Host "`nScaling up Superset application..." -ForegroundColor Yellow
kubectl scale deployment superset -n $NAMESPACE --replicas=3
Start-Sleep -Seconds 15

# Wait for pods to be ready
Write-Host "Waiting for pods to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app=superset -n $NAMESPACE --timeout=300s

Write-Host "✓ Superset pods are running" -ForegroundColor Green

# Run database migrations
Write-Host "`nRunning database migrations..." -ForegroundColor Yellow
$POD_NAME = kubectl get pod -n $NAMESPACE -l app=superset -o jsonpath='{.items[0].metadata.name}'

try {
    kubectl exec -n $NAMESPACE $POD_NAME -- superset db upgrade
    Write-Host "✓ Database migrations completed" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Warning: Database migrations may have failed" -ForegroundColor Yellow
}

# Summary
Write-Host "`n============================================" -ForegroundColor Green
Write-Host "Restore Complete!" -ForegroundColor Green
Write-Host "============================================`n" -ForegroundColor Green

Write-Host "Environment: $Environment" -ForegroundColor Cyan
Write-Host "Restored From: $BackupFile" -ForegroundColor Cyan
Write-Host "Pre-restore Backup: $PRE_RESTORE_BACKUP" -ForegroundColor Cyan

Write-Host "`nVerification Steps:" -ForegroundColor Yellow
Write-Host "1. Check application logs: kubectl logs -f deployment/superset -n $NAMESPACE"
Write-Host "2. Access Superset UI and verify data"
Write-Host "3. Test Databricks connections"
Write-Host "4. Verify user accounts"

Write-Host "`nIf there are issues, you can rollback using:" -ForegroundColor Yellow
Write-Host "  .\restore.ps1 -Environment $Environment -BackupFile $PRE_RESTORE_BACKUP -BackupSource local`n" -ForegroundColor White
