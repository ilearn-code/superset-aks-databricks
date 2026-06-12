# Initialize Superset Database
# PowerShell version for Windows
# Usage: .\init-db.ps1

param(
    [string]$Environment = "dev"
)

$ErrorActionPreference = "Stop"

Write-Host "`n============================================" -ForegroundColor Green
Write-Host "Superset Database Initialization" -ForegroundColor Green
Write-Host "============================================`n" -ForegroundColor Green

# Set namespace based on environment
$NAMESPACE = "superset"

Write-Host "Environment: $Environment" -ForegroundColor Cyan
Write-Host "Namespace: $NAMESPACE`n" -ForegroundColor Cyan

# Get Superset pod name
Write-Host "Finding Superset pod..." -ForegroundColor Yellow
$POD_NAME = kubectl get pod -n $NAMESPACE -l app=superset -o jsonpath='{.items[0].metadata.name}' 2>$null

if (-not $POD_NAME) {
    Write-Host "✗ No Superset pods found. Please deploy the application first." -ForegroundColor Red
    exit 1
}

Write-Host "✓ Found pod: $POD_NAME`n" -ForegroundColor Green

# Initialize database
Write-Host "Running database migrations..." -ForegroundColor Yellow
try {
    kubectl exec -n $NAMESPACE $POD_NAME -- superset db upgrade
    Write-Host "✓ Database migrations completed" -ForegroundColor Green
} catch {
    Write-Host "✗ Database migrations failed: $_" -ForegroundColor Red
    exit 1
}

# Initialize Superset
Write-Host "`nInitializing Superset..." -ForegroundColor Yellow
try {
    kubectl exec -n $NAMESPACE $POD_NAME -- superset init
    Write-Host "✓ Superset initialized" -ForegroundColor Green
} catch {
    Write-Host "✗ Superset initialization failed: $_" -ForegroundColor Red
    exit 1
}

# Create admin user
Write-Host "`nCreating admin user..." -ForegroundColor Yellow
Write-Host "Please provide admin user details:" -ForegroundColor Cyan

$adminUsername = Read-Host "Username (default: admin)"
if (-not $adminUsername) { $adminUsername = "admin" }

$adminFirstname = Read-Host "First Name (default: Admin)"
if (-not $adminFirstname) { $adminFirstname = "Admin" }

$adminLastname = Read-Host "Last Name (default: User)"
if (-not $adminLastname) { $adminLastname = "User" }

$adminEmail = Read-Host "Email (default: admin@gmail.com)"
if (-not $adminEmail) { $adminEmail = "admin@gmail.com" }

$adminPassword = Read-Host "Password" -AsSecureString
$adminPasswordText = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($adminPassword)
)

try {
    $createAdminCmd = @"
superset fab create-admin \
    --username $adminUsername \
    --firstname $adminFirstname \
    --lastname $adminLastname \
    --email $adminEmail \
    --password $adminPasswordText
"@
    
    kubectl exec -n $NAMESPACE $POD_NAME -- sh -c $createAdminCmd
    Write-Host "✓ Admin user created successfully" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Admin user may already exist or creation failed" -ForegroundColor Yellow
}

# Load examples (optional)
Write-Host "`n" -NoNewline
$loadExamples = Read-Host "Do you want to load example data? (y/n)"

if ($loadExamples -eq "y") {
    Write-Host "Loading example data..." -ForegroundColor Yellow
    try {
        kubectl exec -n $NAMESPACE $POD_NAME -- superset load_examples
        Write-Host "✓ Example data loaded" -ForegroundColor Green
    } catch {
        Write-Host "✗ Failed to load examples: $_" -ForegroundColor Red
    }
}

# Summary
Write-Host "`n============================================" -ForegroundColor Green
Write-Host "Initialization Complete!" -ForegroundColor Green
Write-Host "============================================`n" -ForegroundColor Green

Write-Host "Admin Credentials:" -ForegroundColor Cyan
Write-Host "  Username: $adminUsername" -ForegroundColor White
Write-Host "  Email: $adminEmail" -ForegroundColor White

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Port forward to access Superset:"
Write-Host "   kubectl port-forward -n $NAMESPACE svc/superset 8088:8088"
Write-Host ""
Write-Host "2. Access Superset UI:"
Write-Host "   http://localhost:8088"
Write-Host ""
Write-Host "3. Login with the admin credentials above"
Write-Host ""
Write-Host "4. Configure Databricks connection:"
Write-Host "   Data → Databases → + Database"
Write-Host "   Connection: databricks+connector://token:<YOUR_TOKEN>@<HOST>:443/default"
Write-Host ""
