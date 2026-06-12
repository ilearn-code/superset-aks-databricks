# Backup Script for Superset Database
# PowerShell version with Azure Blob Storage integration
# Usage: .\backup.ps1

param(
    [string]$Environment = "dev",
    [string]$BackupLocation = "azure" # or "local"
)

$ErrorActionPreference = "Stop"

# Configuration
$TIMESTAMP = Get-Date -Format "yyyyMMddHHmmss"
$LOCAL_BACKUP_DIR = "C:\backups\superset"
$BACKUP_FILE = "superset_backup_$TIMESTAMP.sql"

# Azure Storage Configuration
$STORAGE_ACCOUNT = "stflashsupersetbackups"
$CONTAINER_NAME = "superset-backups"
$RETENTION_DAYS = 30

Write-Host "`n============================================" -ForegroundColor Green
Write-Host "Superset Database Backup" -ForegroundColor Green
Write-Host "============================================`n" -ForegroundColor Green

# Get database credentials from environment or Key Vault
Write-Host "Retrieving database credentials..." -ForegroundColor Yellow

if ($Environment -eq "prod") {
    $KV_NAME = "kv-flash-superset-prod"
    $NAMESPACE = "superset"
} elseif ($Environment -eq "staging") {
    $KV_NAME = "kv-flash-superset-stg"
    $NAMESPACE = "superset"
} else {
    $KV_NAME = "kv-flash-superset-dev"
    $NAMESPACE = "superset"
}

# Get database password from Key Vault
try {
    $DB_PASSWORD = az keyvault secret show `
        --vault-name $KV_NAME `
        --name "db-password" `
        --query value -o tsv
    
    Write-Host "✓ Retrieved database credentials" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to retrieve credentials from Key Vault" -ForegroundColor Red
    Write-Host "Trying to get from Kubernetes secret..." -ForegroundColor Yellow
    
    $DB_PASSWORD = kubectl get secret superset-secrets `
        -n $NAMESPACE `
        -o jsonpath='{.data.postgres-password}' | `
        ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
}

# Database connection details
$DB_USER = "superset"
$DB_NAME = "superset"
$DB_HOST = "superset-postgresql.$NAMESPACE.svc.cluster.local"
$DB_PORT = "5432"

# Create local backup directory
if (-not (Test-Path $LOCAL_BACKUP_DIR)) {
    New-Item -ItemType Directory -Path $LOCAL_BACKUP_DIR | Out-Null
    Write-Host "✓ Created backup directory: $LOCAL_BACKUP_DIR" -ForegroundColor Green
}

$LOCAL_BACKUP_PATH = Join-Path $LOCAL_BACKUP_DIR $BACKUP_FILE

# Perform backup
Write-Host "`nPerforming database backup..." -ForegroundColor Yellow

# Set password environment variable for pg_dump
$env:PGPASSWORD = $DB_PASSWORD

try {
    # Use pg_dump to backup database
    pg_dump `
        -h $DB_HOST `
        -p $DB_PORT `
        -U $DB_USER `
        -d $DB_NAME `
        -F c `
        -f $LOCAL_BACKUP_PATH
    
    if ($LASTEXITCODE -eq 0) {
        $fileSize = (Get-Item $LOCAL_BACKUP_PATH).Length / 1MB
        Write-Host "✓ Backup successful: $LOCAL_BACKUP_PATH" -ForegroundColor Green
        Write-Host "  Size: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Cyan
    } else {
        throw "pg_dump failed with exit code $LASTEXITCODE"
    }
} catch {
    Write-Host "✗ Backup failed: $_" -ForegroundColor Red
    exit 1
} finally {
    # Clear password from environment
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
}

# Upload to Azure Blob Storage
if ($BackupLocation -eq "azure") {
    Write-Host "`nUploading backup to Azure Blob Storage..." -ForegroundColor Yellow
    
    try {
        # Get storage account key
        $RESOURCE_GROUP = if ($Environment -eq "prod") { "rg-flash-superset-prod" } else { "rg-flash-superset-nonprod" }
        
        $ACCOUNT_KEY = az storage account keys list `
            --resource-group $RESOURCE_GROUP `
            --account-name $STORAGE_ACCOUNT `
            --query '[0].value' -o tsv
        
        # Upload to blob storage
        az storage blob upload `
            --account-name $STORAGE_ACCOUNT `
            --account-key $ACCOUNT_KEY `
            --container-name $CONTAINER_NAME `
            --name "$Environment/$BACKUP_FILE" `
            --file $LOCAL_BACKUP_PATH `
            --overwrite
        
        Write-Host "✓ Backup uploaded to Azure Blob Storage" -ForegroundColor Green
        Write-Host "  Location: $STORAGE_ACCOUNT/$CONTAINER_NAME/$Environment/$BACKUP_FILE" -ForegroundColor Cyan
        
        # Add metadata
        az storage blob metadata update `
            --account-name $STORAGE_ACCOUNT `
            --account-key $ACCOUNT_KEY `
            --container-name $CONTAINER_NAME `
            --name "$Environment/$BACKUP_FILE" `
            --metadata "environment=$Environment" "timestamp=$TIMESTAMP" "type=database"
        
        Write-Host "✓ Metadata added to blob" -ForegroundColor Green
        
    } catch {
        Write-Host "✗ Failed to upload to Azure: $_" -ForegroundColor Red
        Write-Host "  Backup is still available locally at: $LOCAL_BACKUP_PATH" -ForegroundColor Yellow
    }
}

# Cleanup old backups
Write-Host "`nCleaning up old backups..." -ForegroundColor Yellow

# Local cleanup
$oldLocalBackups = Get-ChildItem -Path $LOCAL_BACKUP_DIR -Filter "*.sql" | 
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }

if ($oldLocalBackups) {
    $oldLocalBackups | Remove-Item -Force
    Write-Host "✓ Removed $($oldLocalBackups.Count) old local backup(s)" -ForegroundColor Green
}

# Azure cleanup
if ($BackupLocation -eq "azure") {
    try {
        $cutoffDate = (Get-Date).AddDays(-$RETENTION_DAYS).ToString("yyyy-MM-ddTHH:mm:ssZ")
        
        az storage blob delete-batch `
            --account-name $STORAGE_ACCOUNT `
            --account-key $ACCOUNT_KEY `
            --source $CONTAINER_NAME `
            --pattern "$Environment/*" `
            --if-unmodified-since $cutoffDate 2>$null
        
        Write-Host "✓ Cleaned up old Azure backups (older than $RETENTION_DAYS days)" -ForegroundColor Green
    } catch {
        Write-Host "! Azure cleanup warning: $_" -ForegroundColor Yellow
    }
}

# Summary
Write-Host "`n============================================" -ForegroundColor Green
Write-Host "Backup Complete!" -ForegroundColor Green
Write-Host "============================================`n" -ForegroundColor Green

Write-Host "Environment: $Environment" -ForegroundColor Cyan
Write-Host "Backup File: $BACKUP_FILE" -ForegroundColor Cyan
Write-Host "Local Path: $LOCAL_BACKUP_PATH" -ForegroundColor Cyan

if ($BackupLocation -eq "azure") {
    Write-Host "Azure Path: $STORAGE_ACCOUNT/$CONTAINER_NAME/$Environment/$BACKUP_FILE" -ForegroundColor Cyan
}

Write-Host "`nTo restore this backup, run:" -ForegroundColor Yellow
Write-Host "  .\restore.ps1 -Environment $Environment -BackupFile $BACKUP_FILE`n" -ForegroundColor White
