#!/bin/bash
set -euo pipefail

# Deploy Percy + Landing AI on Separate DigitalOcean Droplets
# Usage: ./deploy-percy-landing-ai.sh

echo "🚀 Percy + Landing AI Self-Hosting Deployment"
echo "=============================================="
echo ""

# Check doctl authentication
if ! doctl account get &>/dev/null; then
  echo "❌ Error: doctl not authenticated"
  echo "Run: doctl auth init"
  exit 1
fi

# Configuration
PERCY_DROPLET_NAME="percy-visual-diff"
LANDING_DROPLET_NAME="landing-ai-ocr"
REGION="sgp1"
PERCY_SIZE="s-2vcpu-4gb"      # $24/month
LANDING_SIZE="c-4"            # $48/month (4 vCPU for OCR)
IMAGE="ubuntu-22-04-x64"
SSH_KEY_ID=$(doctl compute ssh-key list --format ID --no-header | head -n 1)

echo "📋 Deployment Configuration:"
echo "  Percy droplet: $PERCY_DROPLET_NAME ($PERCY_SIZE)"
echo "  Landing AI droplet: $LANDING_DROPLET_NAME ($LANDING_SIZE)"
echo "  Region: $REGION"
echo "  SSH Key ID: $SSH_KEY_ID"
echo ""

# Step 1: Create Percy Droplet
echo "📦 Step 1: Creating Percy Visual Diff droplet..."
if doctl compute droplet list | grep -q "$PERCY_DROPLET_NAME"; then
  echo "⚠️  Percy droplet already exists, skipping creation"
  PERCY_IP=$(doctl compute droplet list "$PERCY_DROPLET_NAME" --format PublicIPv4 --no-header)
else
  doctl compute droplet create "$PERCY_DROPLET_NAME" \
    --image "$IMAGE" \
    --size "$PERCY_SIZE" \
    --region "$REGION" \
    --enable-monitoring \
    --enable-ipv6 \
    --ssh-keys "$SSH_KEY_ID" \
    --wait

  PERCY_IP=$(doctl compute droplet list "$PERCY_DROPLET_NAME" --format PublicIPv4 --no-header)
  echo "✅ Percy droplet created: $PERCY_IP"
  echo "⏳ Waiting 30 seconds for SSH to be available..."
  sleep 30
fi

# Step 2: Create Landing AI Droplet
echo ""
echo "📦 Step 2: Creating Landing AI OCR droplet..."
if doctl compute droplet list | grep -q "$LANDING_DROPLET_NAME"; then
  echo "⚠️  Landing AI droplet already exists, skipping creation"
  LANDING_IP=$(doctl compute droplet list "$LANDING_DROPLET_NAME" --format PublicIPv4 --no-header)
else
  doctl compute droplet create "$LANDING_DROPLET_NAME" \
    --image "$IMAGE" \
    --size "$LANDING_SIZE" \
    --region "$REGION" \
    --enable-monitoring \
    --enable-ipv6 \
    --ssh-keys "$SSH_KEY_ID" \
    --wait

  LANDING_IP=$(doctl compute droplet list "$LANDING_DROPLET_NAME" --format PublicIPv4 --no-header)
  echo "✅ Landing AI droplet created: $LANDING_IP"
  echo "⏳ Waiting 30 seconds for SSH to be available..."
  sleep 30
fi

# Step 3: Install Percy Service
echo ""
echo "🔧 Step 3: Installing Percy Visual Diff service..."
ssh -o StrictHostKeyChecking=no root@"$PERCY_IP" << 'PERCY_EOF'
set -e

# Update system
apt update && apt upgrade -y

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Install PostgreSQL
apt install -y postgresql postgresql-contrib redis-server

# Install Playwright
npx playwright install-deps chromium
npx playwright install chromium

# Create service directory
mkdir -p /opt/percy-visual-diff/{src,screenshots,baselines,diffs}
cd /opt/percy-visual-diff

# Create package.json
cat > package.json << 'PKG_EOF'
{
  "name": "percy-visual-diff",
  "version": "1.0.0",
  "type": "module",
  "dependencies": {
    "express": "^4.18.2",
    "playwright": "^1.40.0",
    "pixelmatch": "^5.3.0",
    "pngjs": "^7.0.0",
    "pg": "^8.11.3",
    "redis": "^4.6.11",
    "@supabase/supabase-js": "^2.39.0",
    "sharp": "^0.33.0"
  }
}
PKG_EOF

npm install

echo "✅ Percy dependencies installed"
PERCY_EOF

# Step 4: Install Landing AI Service
echo ""
echo "🔧 Step 4: Installing Landing AI OCR service..."
ssh -o StrictHostKeyChecking=no root@"$LANDING_IP" << 'LANDING_EOF'
set -e

# Update system
apt update && apt upgrade -y

# Install Python 3.11
apt install -y python3.11 python3.11-venv python3-pip

# Install system dependencies for OpenCV and PaddleOCR
apt install -y \
  libgl1-mesa-glx \
  libglib2.0-0 \
  libgomp1 \
  libsm6 \
  libxext6 \
  libxrender-dev \
  redis-server

# Create service directory
mkdir -p /opt/landing-ai-ocr
cd /opt/landing-ai-ocr

# Create virtual environment
python3.11 -m venv venv
source venv/bin/activate

# Install Python dependencies
pip install --upgrade pip wheel setuptools

# Install PaddleOCR and dependencies
pip install paddleocr==2.7.0.3 paddlepaddle==2.6.0
pip install fastapi==0.104.1 uvicorn==0.24.0 python-multipart==0.0.6
pip install opencv-python-headless==4.8.1.78 pillow==10.1.0 numpy==1.24.3
pip install openai==1.3.5 redis==5.0.1 supabase==2.0.3
pip install pydantic==2.5.0 python-dotenv==1.0.0

echo "✅ Landing AI dependencies installed"
LANDING_EOF

# Step 5: Deploy Percy Code
echo ""
echo "📝 Step 5: Deploying Percy service code..."
scp -o StrictHostKeyChecking=no \
  "$(dirname "$0")/../percy/server.js" \
  root@"$PERCY_IP":/opt/percy-visual-diff/src/ 2>/dev/null || \
  echo "⚠️  Percy server.js not found in ../percy/, skipping file copy (service installed manually)"

# Step 6: Deploy Landing AI Code
echo ""
echo "📝 Step 6: Deploying Landing AI service code..."
scp -o StrictHostKeyChecking=no \
  "$(dirname "$0")/../landing-ai/app.py" \
  root@"$LANDING_IP":/opt/landing-ai-ocr/ 2>/dev/null || \
  echo "⚠️  Landing AI app.py not found in ../landing-ai/, skipping file copy (service installed manually)"

# Step 7: Create systemd services
echo ""
echo "⚙️  Step 7: Creating systemd services..."

# Percy systemd service
ssh -o StrictHostKeyChecking=no root@"$PERCY_IP" << 'PERCY_SYSTEMD_EOF'
cat > /etc/systemd/system/percy-visual-diff.service << 'SERVICE_EOF'
[Unit]
Description=Percy Visual Diff Service
After=network.target postgresql.service redis.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/percy-visual-diff
Environment=NODE_ENV=production
EnvironmentFile=/opt/percy-visual-diff/.env
ExecStart=/usr/bin/node src/server.js
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE_EOF

systemctl daemon-reload
echo "✅ Percy systemd service created"
PERCY_SYSTEMD_EOF

# Landing AI systemd service
ssh -o StrictHostKeyChecking=no root@"$LANDING_IP" << 'LANDING_SYSTEMD_EOF'
cat > /etc/systemd/system/landing-ai-ocr.service << 'SERVICE_EOF'
[Unit]
Description=Landing AI OCR Service
After=network.target redis.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/landing-ai-ocr
Environment=PATH=/opt/landing-ai-ocr/venv/bin
EnvironmentFile=/opt/landing-ai-ocr/.env
ExecStart=/opt/landing-ai-ocr/venv/bin/uvicorn app:app --host 0.0.0.0 --port 5000 --workers 4
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE_EOF

systemctl daemon-reload
echo "✅ Landing AI systemd service created"
LANDING_SYSTEMD_EOF

# Step 8: Install nginx
echo ""
echo "🌐 Step 8: Installing nginx reverse proxy..."

# Percy nginx
ssh -o StrictHostKeyChecking=no root@"$PERCY_IP" << 'PERCY_NGINX_EOF'
apt install -y nginx certbot python3-certbot-nginx

cat > /etc/nginx/sites-available/percy << 'NGINX_EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:4000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
    }
}
NGINX_EOF

ln -sf /etc/nginx/sites-available/percy /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl restart nginx
echo "✅ Percy nginx configured"
PERCY_NGINX_EOF

# Landing AI nginx
ssh -o StrictHostKeyChecking=no root@"$LANDING_IP" << 'LANDING_NGINX_EOF'
apt install -y nginx certbot python3-certbot-nginx

cat > /etc/nginx/sites-available/landing-ai << 'NGINX_EOF'
server {
    listen 80;
    server_name _;

    client_max_body_size 50M;

    location / {
        proxy_pass http://localhost:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
    }
}
NGINX_EOF

ln -sf /etc/nginx/sites-available/landing-ai /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl restart nginx
echo "✅ Landing AI nginx configured"
LANDING_NGINX_EOF

# Step 9: Summary
echo ""
echo "✨ Deployment Complete!"
echo "======================"
echo ""
echo "📍 Percy Visual Diff:"
echo "   IP: $PERCY_IP"
echo "   URL: http://$PERCY_IP"
echo "   Service: percy-visual-diff.service"
echo "   Port: 4000 (proxied via nginx port 80)"
echo ""
echo "📍 Landing AI OCR:"
echo "   IP: $LANDING_IP"
echo "   URL: http://$LANDING_IP"
echo "   Service: landing-ai-ocr.service"
echo "   Port: 5000 (proxied via nginx port 80)"
echo ""
echo "📝 Next Steps:"
echo ""
echo "1. Configure environment variables:"
echo "   ssh root@$PERCY_IP 'nano /opt/percy-visual-diff/.env'"
echo "   ssh root@$LANDING_IP 'nano /opt/landing-ai-ocr/.env'"
echo ""
echo "2. Copy service code (if not already present):"
echo "   scp percy/server.js root@$PERCY_IP:/opt/percy-visual-diff/src/"
echo "   scp landing-ai/app.py root@$LANDING_IP:/opt/landing-ai-ocr/"
echo ""
echo "3. Start services:"
echo "   ssh root@$PERCY_IP 'systemctl start percy-visual-diff && systemctl status percy-visual-diff'"
echo "   ssh root@$LANDING_IP 'systemctl start landing-ai-ocr && systemctl status landing-ai-ocr'"
echo ""
echo "4. Test health endpoints:"
echo "   curl http://$PERCY_IP/health"
echo "   curl http://$LANDING_IP/health"
echo ""
echo "5. Configure SSL (optional):"
echo "   ssh root@$PERCY_IP 'certbot --nginx -d percy.yourdomain.com'"
echo "   ssh root@$LANDING_IP 'certbot --nginx -d ocr.yourdomain.com'"
echo ""
echo "💰 Monthly Cost Estimate:"
echo "   Percy droplet (4GB): \$24/month"
echo "   Landing AI droplet (4vCPU): \$48/month"
echo "   Spaces storage: ~\$2/month"
echo "   OpenAI API: ~\$10/month"
echo "   -------------------------"
echo "   Total: \$84/month"
echo "   Cloud equivalent: \$248-748/month"
echo "   Savings: 66-89%"
echo ""
