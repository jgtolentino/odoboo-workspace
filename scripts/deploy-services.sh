#!/usr/bin/env bash
# Production deployment script for all 3 services
set -euo pipefail

DROPLET_IP="188.166.237.231"
DROPLET_USER="root"
ODOO_DB="insightpulse_prod"

echo "==================================="
echo "Multi-Service Production Deployment"
echo "==================================="

# Step 1: Verify DNS records
echo ""
echo "Step 1/8: Verifying DNS records..."
for domain in "insightpulseai.net" "ocr.insightpulseai.net" "agents.insightpulseai.net"; do
    IP=$(dig +short "$domain" | head -1)
    if [ "$IP" = "$DROPLET_IP" ]; then
        echo "✓ $domain → $IP"
    else
        echo "⚠ WARNING: $domain → $IP (expected $DROPLET_IP)"
    fi
done

# Step 2: Copy production files to droplet
echo ""
echo "Step 2/8: Copying deployment files..."
scp docker-compose.production.yml "${DROPLET_USER}@${DROPLET_IP}:/opt/fin-workspace/"
scp nginx/production.conf "${DROPLET_USER}@${DROPLET_IP}:/opt/fin-workspace/nginx/"
scp .env "${DROPLET_USER}@${DROPLET_IP}:/opt/fin-workspace/"

# Step 3: Pull latest images from ghcr.io
echo ""
echo "Step 3/8: Pulling latest container images..."
ssh "${DROPLET_USER}@${DROPLET_IP}" << 'EOF'
cd /opt/fin-workspace
docker compose -f docker-compose.production.yml pull
EOF

# Step 4: Install OCA queue module
echo ""
echo "Step 4/8: Installing OCA queue_job module..."
ssh "${DROPLET_USER}@${DROPLET_IP}" << EOF
cd /opt/fin-workspace
mkdir -p oca
cd oca
[ -d queue ] || git clone --depth=1 -b 18.0 https://github.com/OCA/queue.git
chown -R 1000:1000 /opt/fin-workspace/oca
EOF

# Step 5: Update Odoo configuration for workers
echo ""
echo "Step 5/8: Configuring Odoo workers..."
ssh "${DROPLET_USER}@${DROPLET_IP}" << 'EOF'
CONFIG="/opt/fin-workspace/config/odoo.conf"
if ! grep -q "^workers" "$CONFIG" 2>/dev/null; then
    echo "workers = 4" >> "$CONFIG"
    echo "max_cron_threads = 2" >> "$CONFIG"
fi
if ! grep -q "/mnt/oca" "$CONFIG" 2>/dev/null; then
    sed -i 's|addons_path = |addons_path = /mnt/oca,|' "$CONFIG"
fi
EOF

# Step 6: Deploy services
echo ""
echo "Step 6/8: Starting services..."
ssh "${DROPLET_USER}@${DROPLET_IP}" << 'EOF'
cd /opt/fin-workspace
docker compose -f docker-compose.production.yml up -d
EOF

# Step 7: Install queue_job module in Odoo
echo ""
echo "Step 7/8: Installing queue_job in Odoo..."
sleep 10  # Wait for Odoo to start
ssh "${DROPLET_USER}@${DROPLET_IP}" << EOF
docker exec -t odoo18 odoo -d "${ODOO_DB}" \
  --db_host=odoo-db --db_user=odoo --db_password=odoo \
  --stop-after-init -i queue_job || true
docker restart odoo18
EOF

# Step 8: Configure SSL certificates
echo ""
echo "Step 8/8: Configuring SSL certificates..."
ssh "${DROPLET_USER}@${DROPLET_IP}" << 'EOF'
# Install certbot if not present
if ! command -v certbot &> /dev/null; then
    apt-get update && apt-get install -y certbot
fi

# Issue certificates (will skip if already exist)
certbot certonly --standalone --non-interactive --agree-tos \
  -m admin@insightpulseai.net \
  -d insightpulseai.net \
  -d ocr.insightpulseai.net \
  -d agents.insightpulseai.net \
  --pre-hook "docker stop fin-nginx" \
  --post-hook "docker start fin-nginx" || true

# Restart nginx to load certs
docker restart fin-nginx
EOF

# Step 9: Health checks
echo ""
echo "==================================="
echo "Health Checks"
echo "==================================="
sleep 5

for url in "https://insightpulseai.net/web/health" \
           "https://ocr.insightpulseai.net/health" \
           "https://agents.insightpulseai.net/health"; do
    if curl -sfk "$url" > /dev/null 2>&1; then
        echo "✓ $url"
    else
        echo "✗ $url (check logs)"
    fi
done

echo ""
echo "==================================="
echo "Deployment Complete!"
echo "==================================="
echo ""
echo "Service URLs:"
echo "  Odoo:   https://insightpulseai.net"
echo "  OCR:    https://ocr.insightpulseai.net"
echo "  Agents: https://agents.insightpulseai.net"
echo ""
echo "Next steps:"
echo "1. Test OCR: curl -F 'file=@receipt.jpg' https://ocr.insightpulseai.net/extract/receipt"
echo "2. Test Agents: curl https://agents.insightpulseai.net/health"
echo "3. Configure Odoo system parameters for API URLs"
