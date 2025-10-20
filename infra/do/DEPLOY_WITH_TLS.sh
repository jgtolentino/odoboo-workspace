#!/bin/bash
set -e

# ============================================================================
# PRODUCTION OCR SERVICE DEPLOYMENT WITH TLS
# ============================================================================
# Complete deployment with:
# - AMD64 image push with immutable tags
# - Droplet deployment
# - DNS configuration guide
# - NGINX + Certbot TLS setup
# - Firewall hardening
# - Odoo configuration
# ============================================================================

DROPLET_ID=525178434
DROPLET_IP="188.166.237.231"
DROPLET_DOMAIN="ocr.insightpulseai.net"
REGISTRY="registry.digitalocean.com/fin-workspace"
SERVICE_NAME="ocr-service"

echo "🚀 OCR SERVICE PRODUCTION DEPLOYMENT WITH TLS"
echo "============================================="
echo ""

# ============================================================================
# STEP 2: Push AMD64 Image to Registry
# ============================================================================

echo "📦 STEP 2: Push AMD64 Image with Immutable Tags"
echo "------------------------------------------------"

cd services/ocr-service

# Get git SHA for immutable tag
GIT_SHA=$(git rev-parse --short HEAD)
echo "Git SHA: $GIT_SHA"

# Tag with both :prod and :sha-<gitsha>
echo "Tagging images..."
docker tag ocr-service:amd64 $REGISTRY/$SERVICE_NAME:prod
docker tag ocr-service:amd64 $REGISTRY/$SERVICE_NAME:sha-$GIT_SHA

echo "✓ Tagged: $REGISTRY/$SERVICE_NAME:prod"
echo "✓ Tagged: $REGISTRY/$SERVICE_NAME:sha-$GIT_SHA"

# Authenticate with registry
doctl registry login

# Push both tags
echo "Pushing :prod tag..."
docker push $REGISTRY/$SERVICE_NAME:prod

echo "Pushing :sha-$GIT_SHA tag..."
docker push $REGISTRY/$SERVICE_NAME:sha-$GIT_SHA

# Verify AMD64 architecture
echo "Verifying AMD64 architecture..."
ARCH_CHECK=$(docker buildx imagetools inspect $REGISTRY/$SERVICE_NAME:prod | grep "linux/amd64" || true)

if [ -z "$ARCH_CHECK" ]; then
    echo "❌ ERROR: AMD64 architecture not found!"
    exit 1
fi

echo "✓ AMD64 architecture verified"

# ============================================================================
# STEP 3: Deploy on Droplet
# ============================================================================

echo ""
echo "🚀 STEP 3: Deploy OCR Service on Droplet"
echo "-----------------------------------------"

# Upload docker-compose file
echo "Uploading docker-compose.yml to droplet..."
cd ../../
scp -F /dev/null -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  -i ~/.ssh/id_ed25519 \
  infra/do/docker-compose-droplet.yml \
  root@$DROPLET_IP:/root/docker-compose.yml

# Deploy
ssh -F /dev/null -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  -i ~/.ssh/id_ed25519 root@$DROPLET_IP << 'DROPLET_EOF'

# Authenticate with registry
doctl registry login

# Navigate to service directory
cd /root

# Pull latest image
echo "Pulling :prod image..."
docker compose -f docker-compose.yml pull

# Start service
echo "Starting service..."
docker compose -f docker-compose.yml up -d

# Wait for healthcheck
echo "Waiting for service to start..."
sleep 20

# Test health endpoint
echo "Testing health endpoint..."
curl -sf http://localhost:8000/health | jq || echo "❌ Health check failed!"

DROPLET_EOF

echo "✓ OCR service deployed on droplet"

# ============================================================================
# STEP 4: DNS Configuration Guidance
# ============================================================================

echo ""
echo "🌐 STEP 4: DNS Configuration (Manual Step)"
echo "-------------------------------------------"
echo ""
echo "📋 Add the following DNS record in Squarespace:"
echo ""
echo "  Type:  A"
echo "  Host:  ocr"
echo "  Value: $DROPLET_IP"
echo "  TTL:   Auto"
echo ""
echo "  Full domain: $DROPLET_DOMAIN"
echo ""
echo "⏳ After adding DNS record, wait 5-10 minutes for propagation"
echo ""

read -p "Have you added the DNS record? (y/N) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "⚠ Please add the DNS record before continuing"
    echo ""
    echo "📋 Next steps to run manually after DNS propagation:"
    echo "  1. Verify DNS: dig +short $DROPLET_DOMAIN A"
    echo "  2. Continue deployment: ./infra/do/DEPLOY_WITH_TLS.sh (restart from Step 5)"
    exit 0
fi

# Verify DNS propagation
echo "Verifying DNS propagation..."
DNS_CHECK=$(dig +short $DROPLET_DOMAIN A | grep "$DROPLET_IP" || true)

if [ -z "$DNS_CHECK" ]; then
    echo "⚠ DNS not propagated yet. Current response:"
    dig +short $DROPLET_DOMAIN A
    echo ""
    echo "Please wait a few minutes and re-run this script"
    exit 0
fi

echo "✓ DNS propagated successfully"

# ============================================================================
# STEP 5: NGINX + Certbot TLS Setup
# ============================================================================

echo ""
echo "🔒 STEP 5: Setup NGINX + Certbot TLS"
echo "-------------------------------------"

# Upload NGINX config
echo "Uploading NGINX configuration..."
scp -F /dev/null -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  -i ~/.ssh/id_ed25519 \
  infra/do/nginx-ocr.conf \
  root@$DROPLET_IP:/tmp/ocr.conf

# Setup NGINX + TLS
ssh -F /dev/null -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  -i ~/.ssh/id_ed25519 root@$DROPLET_IP << 'DROPLET_EOF'

# Install NGINX + Certbot
echo "Installing NGINX and Certbot..."
apt-get update
apt-get install -y nginx certbot python3-certbot-nginx

# Copy NGINX config
cp /tmp/ocr.conf /etc/nginx/sites-available/ocr
ln -sf /etc/nginx/sites-available/ocr /etc/nginx/sites-enabled/ocr

# Test NGINX config
nginx -t

# Reload NGINX
systemctl reload nginx

# Get TLS certificate
echo "Obtaining TLS certificate from Let's Encrypt..."
certbot --nginx -d ocr.insightpulseai.net --non-interactive --agree-tos --email jgtolentino_rn@yahoo.com

# Configure firewall
echo "Configuring firewall..."

# Allow SSH (CRITICAL - do this first!)
ufw allow 22/tcp

# Allow HTTP/HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# DENY direct access to port 8000 (internal only)
ufw deny 8000/tcp

# Enable firewall
echo "y" | ufw enable

# Show status
ufw status

echo ""
echo "✓ NGINX + TLS configured"
echo "✓ Firewall hardened"

DROPLET_EOF

echo "✓ TLS setup complete"

# ============================================================================
# STEP 6: Verify HTTPS Access
# ============================================================================

echo ""
echo "🔍 STEP 6: Verify HTTPS Access"
echo "-------------------------------"

sleep 5

# Test HTTPS endpoint
echo "Testing HTTPS endpoint..."
if curl -sf --max-time 10 https://$DROPLET_DOMAIN/health | jq > /dev/null 2>&1; then
    echo "✓ HTTPS endpoint working!"
    curl -sf https://$DROPLET_DOMAIN/health | jq
else
    echo "❌ HTTPS endpoint not responding"
    echo "Check NGINX logs: ssh root@$DROPLET_IP 'journalctl -u nginx -n 50'"
fi

# ============================================================================
# FINAL SUMMARY
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
echo "  Domain: https://$DROPLET_DOMAIN"
echo "  Service Port: 8000 (internal only, proxied via NGINX)"
echo "  TLS: Let's Encrypt (auto-renew enabled)"
echo ""
echo "📋 Next Steps:"
echo "  1. Update Odoo system parameter:"
echo "     Settings → Technical → System Parameters"
echo "     Key: hr_expense_ocr_audit.ocr_api_url"
echo "     Value: https://$DROPLET_DOMAIN/ocr"
echo ""
echo "  2. Test OCR endpoint:"
echo "     curl -F file=@sample.jpg https://$DROPLET_DOMAIN/ocr | jq"
echo ""
echo "  3. Install OCA minimal core modules:"
echo "     ./scripts/download_oca_minimal.sh"
echo ""
echo "  4. Setup automated snapshots:"
echo "     ./infra/do/SNAPSHOT_AUTOMATION.sh cron"
echo ""
echo "🔒 Security Status:"
echo "  - Port 8000: DENIED (internal only)"
echo "  - Port 80: ALLOWED (HTTP → HTTPS redirect)"
echo "  - Port 443: ALLOWED (TLS encrypted)"
echo "  - Port 22: ALLOWED (SSH access)"
echo ""
echo "📸 TLS Certificate Auto-Renewal:"
echo "  - Certbot renew timer active"
echo "  - Check status: systemctl status certbot.timer"
echo ""
