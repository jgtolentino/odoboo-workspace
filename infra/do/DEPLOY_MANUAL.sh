#!/bin/bash
set -e

# ============================================================================
# MANUAL OCR SERVICE DEPLOYMENT (Quick Commands)
# ============================================================================
# Streamlined deployment matching user's exact specifications
# ============================================================================

DROPLET_IP="188.166.237.231"
REGISTRY="registry.digitalocean.com/fin-workspace"
GIT_SHA=$(git rev-parse --short HEAD)

echo "🚀 OCR SERVICE MANUAL DEPLOYMENT"
echo "================================"
echo ""

# ============================================================================
# Step 1: Tag and Push (Pre-push sanity)
# ============================================================================

echo "📦 Step 1: Tag and Push AMD64 Image"
echo "------------------------------------"

cd services/ocr-service

# Tag
docker tag ocr-service:amd64 $REGISTRY/ocr-service:prod
docker tag ocr-service:amd64 $REGISTRY/ocr-service:sha-$GIT_SHA

echo "✓ Tagged: :prod and :sha-$GIT_SHA"

# Login and push
doctl registry login
docker push $REGISTRY/ocr-service:prod
docker push $REGISTRY/ocr-service:sha-$GIT_SHA

echo "✓ Pushed both tags"

# Verify architecture
echo "Verifying AMD64 architecture..."
docker buildx imagetools inspect $REGISTRY/ocr-service:prod | grep linux/amd64

if [ $? -eq 0 ]; then
    echo "✓ AMD64 architecture verified"
else
    echo "❌ ERROR: AMD64 not found!"
    exit 1
fi

cd ../../

# ============================================================================
# Step 2: Deploy on Droplet
# ============================================================================

echo ""
echo "🚀 Step 2: Deploy on Droplet"
echo "-----------------------------"

# Upload docker-compose file
scp -F /dev/null -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  -i ~/.ssh/id_ed25519 \
  infra/do/docker-compose-droplet.yml \
  root@$DROPLET_IP:/opt/ocr/docker-compose.yml

# Deploy
ssh -F /dev/null -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  -i ~/.ssh/id_ed25519 root@$DROPLET_IP << 'EOF'

# Create directory
mkdir -p /opt/ocr
cd /opt/ocr

# Login and pull
doctl registry login
docker compose -f docker-compose.yml pull
docker compose -f docker-compose.yml up -d

# Wait and test
sleep 10
curl -f http://localhost:8000/health

EOF

echo "✓ Service deployed and health check passed"

# ============================================================================
# Step 3: Lock Down Firewall
# ============================================================================

echo ""
echo "🔒 Step 3: Lock Down Firewall"
echo "------------------------------"

ssh -F /dev/null -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  -i ~/.ssh/id_ed25519 root@$DROPLET_IP << 'EOF'

# Allow HTTP/HTTPS
ufw allow 80,443/tcp

# Deny port 8000 externally
ufw deny 8000/tcp

# Enable firewall (if not already)
echo "y" | ufw enable 2>/dev/null || true

# Show status
ufw status

EOF

echo "✓ Firewall configured (port 8000 internal only)"

# ============================================================================
# Step 4: Summary
# ============================================================================

echo ""
echo "✅ DEPLOYMENT COMPLETE!"
echo "======================="
echo ""
echo "📊 Configuration:"
echo "  Droplet IP: $DROPLET_IP"
echo "  Image: $REGISTRY/ocr-service:prod"
echo "  SHA Tag: :sha-$GIT_SHA"
echo "  Service Port: 8000 (INTERNAL ONLY)"
echo ""
echo "📋 Next Steps:"
echo ""
echo "  1. Configure Odoo system parameter:"
echo "     Settings → Technical → System Parameters"
echo "     Key: hr_expense_ocr_audit.ocr_api_url"
echo "     Value: http://$DROPLET_IP:8000/ocr"
echo ""
echo "  2. (Optional) Setup DNS + TLS:"
echo "     - Add DNS A record: ocr.insightpulseai.net → $DROPLET_IP"
echo "     - Run: ./infra/do/DEPLOY_WITH_TLS.sh (from Step 5)"
echo ""
echo "  3. Test OCR endpoint:"
echo "     ssh root@$DROPLET_IP"
echo "     curl -F file=@sample.jpg http://localhost:8000/ocr | jq"
echo ""
echo "🔒 Security Status:"
echo "  - Port 8000: DENIED (internal only)"
echo "  - Port 80/443: ALLOWED (ready for NGINX)"
echo ""
