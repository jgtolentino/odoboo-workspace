#!/bin/bash

# setup-ssl.sh - Configure SSL/TLS for insightpulseai.net
# Usage: ./scripts/setup-ssl.sh [DROPLET_IP] [EMAIL]

set -e

DROPLET_IP="${1:-188.166.237.231}"
DROPLET_USER="root"
DOMAIN="insightpulseai.net"
EMAIL="${2:-admin@insightpulseai.net}"

echo "🔒 Setting up SSL/TLS for $DOMAIN"

# Step 1: Verify DNS configuration
echo "📍 Step 1: Verifying DNS configuration..."
echo ""
echo "Please ensure your DNS records are configured:"
echo "  A     insightpulseai.net     → $DROPLET_IP"
echo "  A     www.insightpulseai.net → $DROPLET_IP"
echo ""
read -p "Press Enter once DNS is configured and propagated (check with 'dig +short insightpulseai.net')..."

# Verify DNS resolution
RESOLVED_IP=$(dig +short $DOMAIN | tail -1)
if [ "$RESOLVED_IP" != "$DROPLET_IP" ]; then
    echo "⚠️  Warning: DNS not propagated yet"
    echo "   Domain resolves to: $RESOLVED_IP"
    echo "   Expected: $DROPLET_IP"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Step 2: Install Certbot
echo "📦 Step 2: Installing Certbot..."
ssh ${DROPLET_USER}@${DROPLET_IP} << 'EOF'
# Update package list
apt update

# Install Certbot
apt install -y certbot

# Create webroot directory for ACME challenge
mkdir -p /var/www/certbot

# Verify Certbot installation
certbot --version
EOF

# Step 3: Get SSL certificate
echo "🔐 Step 3: Obtaining SSL certificate..."
ssh ${DROPLET_USER}@${DROPLET_IP} << EOF
# Stop nginx temporarily to allow Certbot to bind to port 80
cd /opt/services
docker-compose stop nginx

# Get certificate using standalone mode
certbot certonly --standalone \
    --non-interactive \
    --agree-tos \
    --email $EMAIL \
    -d $DOMAIN \
    -d www.$DOMAIN

# Restart nginx
docker-compose start nginx

# Verify certificate
ls -la /etc/letsencrypt/live/$DOMAIN/
EOF

# Step 4: Configure auto-renewal
echo "🔄 Step 4: Configuring auto-renewal..."
ssh ${DROPLET_USER}@${DROPLET_IP} << 'EOF'
# Create renewal script
cat > /opt/services/renew-ssl.sh << 'RENEWAL_SCRIPT'
#!/bin/bash
cd /opt/services
docker-compose stop nginx
certbot renew --standalone --quiet
docker-compose start nginx
RENEWAL_SCRIPT

chmod +x /opt/services/renew-ssl.sh

# Add to crontab (daily at 3 AM)
(crontab -l 2>/dev/null; echo "0 3 * * * /opt/services/renew-ssl.sh >> /var/log/certbot-renew.log 2>&1") | crontab -

# Verify crontab
echo "Crontab configured:"
crontab -l | grep certbot || echo "No certbot cron jobs found"
EOF

# Step 5: Test SSL configuration
echo "✅ Step 5: Testing SSL configuration..."
sleep 5

# Test HTTPS endpoint
if curl -sf https://$DOMAIN/health > /dev/null; then
    echo "✅ HTTPS is working!"
else
    echo "❌ HTTPS test failed"
    echo "   Check logs: ssh $DROPLET_USER@$DROPLET_IP 'docker-compose logs nginx'"
fi

# Step 6: Display summary
echo ""
echo "🎉 SSL/TLS setup complete!"
echo ""
echo "📍 Your services are now available at:"
echo "  - Main: https://$DOMAIN/"
echo "  - OCR Service: https://$DOMAIN/ocr/"
echo "  - Agent Service: https://$DOMAIN/agent/"
echo ""
echo "🔐 SSL Certificate Details:"
ssh ${DROPLET_USER}@${DROPLET_IP} "certbot certificates"
echo ""
echo "🔄 Auto-renewal:"
echo "  - Certificate will auto-renew daily at 3 AM"
echo "  - Check renewal logs: ssh $DROPLET_USER@$DROPLET_IP 'tail -f /var/log/certbot-renew.log'"
echo ""
echo "🧪 Test SSL grade:"
echo "  https://www.ssllabs.com/ssltest/analyze.html?d=$DOMAIN"
echo ""
