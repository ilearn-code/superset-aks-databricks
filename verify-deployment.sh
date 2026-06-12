#!/bin/bash
# Superset Deployment Verification Script

echo "=================================================="
echo "SUPERSET DEPLOYMENT VERIFICATION"
echo "=================================================="
echo ""

# 1. Check Docker Image
echo "1. DOCKER IMAGE INFORMATION:"
echo "----------------------------"
IMAGE_INFO=$(kubectl get deployment superset -n superset -o jsonpath='{.spec.template.spec.containers[0].image}')
echo "✓ Image: $IMAGE_INFO"
echo ""

# Extract image tag
IMAGE_TAG=$(echo $IMAGE_INFO | cut -d':' -f2)
echo "✓ Image Tag (Git Commit): $IMAGE_TAG"
echo ""

# 2. Check Deployment Status
echo "2. DEPLOYMENT STATUS:"
echo "---------------------"
kubectl get deployment superset -n superset -o wide
echo ""

# 3. Check Pod Status
echo "3. POD STATUS:"
echo "--------------"
kubectl get pods -n superset -l app=superset -o wide
echo ""

# 4. Check Database Configuration
echo "4. DATABASE CONFIGURATION:"
echo "--------------------------"
DB_URI=$(kubectl get secret superset-secrets -n superset -o jsonpath='{.data.database-uri}' | base64 -d)
DB_HOST=$(echo $DB_URI | sed 's/.*@\(.*\):\([0-9]*\)\/\(.*\)/\1/')
DB_PORT=$(echo $DB_URI | sed 's/.*@\(.*\):\([0-9]*\)\/\(.*\)/\2/')
DB_NAME=$(echo $DB_URI | sed 's/.*@\(.*\):\([0-9]*\)\/\(.*\)/\3/')
echo "✓ Database Host: $DB_HOST"
echo "✓ Database Port: $DB_PORT"
echo "✓ Database Name: $DB_NAME"
echo ""

# 5. Check Redis Configuration
echo "5. REDIS CONFIGURATION:"
echo "-----------------------"
REDIS_URI=$(kubectl get secret superset-secrets -n superset -o jsonpath='{.data.redis-uri}' | base64 -d)
echo "✓ Redis URI: $REDIS_URI"
echo ""

# 6. Check Services
echo "6. SERVICES:"
echo "------------"
kubectl get services -n superset
echo ""

# 7. Get External Access URL
echo "7. EXTERNAL ACCESS:"
echo "-------------------"
EXTERNAL_IP=$(kubectl get service superset -n superset -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ -n "$EXTERNAL_IP" ]; then
  echo "✓ Superset URL: http://$EXTERNAL_IP:8088"
  echo ""
  echo "Testing connectivity..."
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$EXTERNAL_IP:8088/health --connect-timeout 5 || echo "000")
  if [ "$HTTP_STATUS" = "200" ]; then
    echo "✓ Health check: PASSED (HTTP $HTTP_STATUS)"
  else
    echo "⚠ Health check: FAILED (HTTP $HTTP_STATUS)"
  fi
else
  echo "⚠ No external IP assigned yet"
fi
echo ""

# 8. Check Database Migration Status
echo "8. DATABASE MIGRATION STATUS:"
echo "-----------------------------"
echo "Checking if database is initialized..."
kubectl exec -it deployment/superset -n superset -- superset db current 2>&1 | grep -E "(INFO|current|Revision|head)" || echo "Unable to check migration status"
echo ""

# 9. List Admin Users
echo "9. ADMIN USERS:"
echo "---------------"
echo "Attempting to list users..."
kubectl exec deployment/superset -n superset -- superset fab list-users 2>&1 | grep -A 20 "username" || echo "No users found or unable to retrieve"
echo ""

# 10. Check Recent Logs
echo "10. RECENT APPLICATION LOGS:"
echo "----------------------------"
kubectl logs deployment/superset -n superset --tail=10 2>&1 | grep -v "GET /static" | tail -5
echo ""

# 11. Resource Usage
echo "11. RESOURCE USAGE:"
echo "-------------------"
kubectl top pod -n superset -l app=superset 2>/dev/null || echo "Metrics not available (requires metrics-server)"
echo ""

# 12. Configuration Summary
echo "12. CONFIGURATION SUMMARY:"
echo "--------------------------"
echo "Environment: dev"
echo "Namespace: superset"
echo "Resource Group: rg-superset-test-ci"
echo "AKS Cluster: aks-superset-test-ci"
echo "ACR: acrflashsupersetdev.azurecr.io"
echo ""

# 13. Credentials Info
echo "13. CREDENTIALS:"
echo "-----------------"
echo "⚠ If this is a fresh installation, retrieve admin credentials from Key Vault or the deployment pipeline secret store."
echo ""

# 14. Quick Commands
echo "14. USEFUL COMMANDS:"
echo "--------------------"
echo "• View logs: kubectl logs -f deployment/superset -n superset"
echo "• Exec into pod: kubectl exec -it deployment/superset -n superset -- /bin/bash"
echo "• Create admin user: kubectl exec -it deployment/superset -n superset -- superset fab create-admin"
echo "• Database upgrade: kubectl exec -it deployment/superset -n superset -- superset db upgrade"
echo "• Init superset: kubectl exec -it deployment/superset -n superset -- superset init"
echo ""

echo "=================================================="
echo "Verification Complete!"
echo "=================================================="
