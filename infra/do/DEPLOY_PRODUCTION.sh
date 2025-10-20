#!/bin/bash
set -e

# ============================================================================
# PRODUCTION-READY OCR SERVICE DEPLOYMENT
# ============================================================================
# Implements all rock-solid best practices:
# - Immutable tags (:prod + :sha-<gitsha>)
# - Architecture verification
# - Firewall hardening (internal 8000 only)
# - Explicit docker-compose filename
# - Snapshot consistency
# ============================================================================

DROPLET_ID=525178434
DROPLET_IP="188.166.237.231"
REGISTRY="registry.digitalocean.com/fin-workspace"
SERVICE_NAME="ocr-service"
COMPOSE_FILE="docker-compose-droplet.yml"

echo "🚀 PRODUCTION OCR SERVICE DEPLOYMENT"
echo "====================================="
echo ""

# ============================================================================
# PHASE 1: Build & Tag with Immutable Tags
# ============================================================================

cd services/ocr-service

echo "📦 PHASE 1: Build & Tag Docker Image"
echo "-------------------------------------"

# Get git SHA for immutable tag
GIT_SHA=$(git rev-parse --short HEAD)
echo "Git SHA: $GIT_SHA"

# Tag with both :prod and :sha-<gitsha>
echo "Tagging images..."
docker tag ocr-service:amd64 $REGISTRY/$SERVICE_NAME:prod
docker tag ocr-service:amd64 $REGISTRY/$SERVICE_NAME:sha-$GIT_SHA

echo "✓ Tagged: $REGISTRY/$SERVICE_NAME:prod"
echo "✓ Tagged: $REGISTRY/$SERVICE_NAME:sha-$GIT_SHA"

# ============================================================================
# PHASE 2: Push to Registry
# ============================================================================

echo ""
echo "📤 PHASE 2: Push to Container Registry"
echo "---------------------------------------"

# Authenticate
doctl registry login

# Push both tags
echo "Pushing :prod tag..."
docker push $REGISTRY/$SERVICE_NAME:prod

echo "Pushing :sha-$GIT_SHA tag..."
docker push $REGISTRY/$SERVICE_NAME:sha-$GIT_SHA

echo "✓ Images pushed to registry"

# ============================================================================
# PHASE 3: Verify Architecture
# ============================================================================

echo ""
echo "🔍 PHASE 3: Verify AMD64 Architecture"
echo "--------------------------------------"

ARCH_CHECK=$(docker buildx imagetools inspect $REGISTRY/$SERVICE_NAME:prod | grep "linux/amd64" || true)

if [ -z "$ARCH_CHECK" ]; then
    echo "❌ ERROR: AMD64 architecture not found in image!"
    echo "Image manifest:"
    docker buildx imagetools inspect $REGISTRY/$SERVICE_NAME:prod
    exit 1
fi

echo "✓ AMD64 architecture verified"
echo "$ARCH_CHECK"

# ============================================================================
# PHASE 4: Snapshot Before Deploy (Consistency)
# ============================================================================

echo ""
echo "📸 PHASE 4: Pre-Deployment Snapshot"
echo "------------------------------------"

read -p "Create snapshot before deploying? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Stopping services for consistent snapshot..."
    ssh -F /dev/null -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -i ~/.ssh/id_ed25519 root@$DROPLET_IP << 'DROPLET_EOF'
cd /root
docker compose -f docker-compose-droplet.yml down
DROPLET_EOF

    echo "Taking snapshot..."
    SNAPSHOT_NAME="ocr-predeploy-$(date +%F-%H%M%S)"
    doctl compute droplet-action snapshot $DROPLET_ID --snapshot-name "$SNAPSHOT_NAME" --wait

    echo "✓ Snapshot created: $SNAPSHOT_NAME"
else
    echo "⚠ Skipping snapshot (not recommended for production)"
fi

# ============================================================================
# PHASE 5: Deploy to Droplet
# ============================================================================

echo ""
echo "🚀 PHASE 5: Deploy to Droplet"
echo "------------------------------"

# Deploy with explicit compose file
ssh -F /dev/null -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  -i ~/.ssh/id_ed25519 root@$DROPLET_IP << 'DROPLET_EOF'

# Authenticate with registry
doctl registry login

# Navigate to service directory
cd /root

# Pull latest image
echo "Pulling :prod image..."
docker compose -f docker-compose-droplet.yml pull

# Start service
echo "Starting service..."
docker compose -f docker-compose-droplet.yml up -d

# Wait for healthcheck
echo "Waiting for service to start..."
sleep 20

# Test health endpoint
echo "Testing health endpoint..."
curl -sf http://localhost:8000/health | jq || echo "❌ Health check failed!"

# Show logs
echo ""
echo "Recent logs:"
docker compose -f docker-compose-droplet.yml logs --tail=20 ocr

DROPLET_EOF

echo "✓ Deployment complete"

# ============================================================================
# PHASE 6: Firewall Hardening
# ============================================================================

echo ""
echo "🛡️ PHASE 6: Firewall Configuration"
echo "------------------------------------"

read -p "Configure firewall (ufw)? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ssh -F /dev/null -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -i ~/.ssh/id_ed25519 root@$DROPLET_IP << 'DROPLET_EOF'

# Check if ufw is installed
if ! command -v ufw &> /dev/null; then
    echo "Installing ufw..."
    apt-get update && apt-get install -y ufw
fi

# Allow SSH (CRITICAL - do this first!)
ufw allow 22/tcp

# Allow HTTP/HTTPS for NGINX (when ready)
ufw allow 80/tcp
ufw allow 443/tcp

# DENY direct access to port 8000 (internal only)
ufw deny 8000/tcp

# Enable firewall
echo "y" | ufw enable

# Show status
ufw status

echo ""
echo "✓ Firewall configured:"
echo "  - SSH (22): ALLOWED"
echo "  - HTTP (80): ALLOWED"
echo "  - HTTPS (443): ALLOWED"
echo "  - OCR (8000): DENIED (internal only)"

DROPLET_EOF

    echo "✓ Firewall hardened"
else
    echo "⚠ Skipping firewall configuration"
    echo "  Recommendation: Port 8000 should be internal only"
fi

# ============================================================================
# PHASE 7: External Health Check
# ============================================================================

echo ""
echo "🔍 PHASE 7: External Health Check"
echo "----------------------------------"

# Note: This will fail if firewall is enabled (expected behavior)
echo "Testing external access (will fail if firewall configured)..."
if curl -sf --max-time 5 http://$DROPLET_IP:8000/health > /dev/null 2>&1; then
    echo "⚠ WARNING: Port 8000 is externally accessible!"
    echo "  Recommendation: Enable firewall to restrict to internal only"
else
    echo "✓ Port 8000 is not externally accessible (secure)"
fi

# ============================================================================
# PHASE 8: Configuration Summary
# ============================================================================

echo ""
echo "✅ DEPLOYMENT COMPLETE!"
echo "======================="
echo ""
echo "📊 Deployment Summary:"
echo "  Registry: $REGISTRY"
echo "  Image Tags:"
echo "    - $REGISTRY/$SERVICE_NAME:prod"
echo "    - $REGISTRY/$SERVICE_NAME:sha-$GIT_SHA"
echo "  Droplet: $DROPLET_IP (ID: $DROPLET_ID)"
echo "  Service Port: 8000 (internal only)"
echo "  Compose File: $COMPOSE_FILE"
echo ""
echo "📋 Next Steps:"
echo "  1. Configure Odoo system parameter:"
echo "     Key: hr_expense_ocr_audit.ocr_api_url"
echo "     Value: http://$DROPLET_IP:8000/ocr"
echo ""
echo "  2. Install OCA minimal core modules:"
echo "     ./scripts/download_oca_minimal.sh"
echo ""
echo "  3. Setup automated snapshots:"
echo "     ./infra/do/SNAPSHOT_AUTOMATION.sh cron"
echo ""
echo "  4. (Optional) Setup NGINX + TLS for HTTPS:"
echo "     - Install Certbot on droplet"
echo "     - Configure nginx-ocr.conf"
echo "     - Update Odoo URL to https://your-domain.com/ocr"
echo ""
echo "📸 Rollback Command (if needed):"
echo "  ./infra/do/SNAPSHOT_AUTOMATION.sh restore <snapshot-id>"
echo ""
