#!/usr/bin/env bash
set -euo pipefail

# Production Odoo Deployment with Set B Credentials
# Email: jgtolentino.rn@gmail.com
# Password: Postgres_26
# Database: insightpulse_prod

echo "🚀 Deploying Production Odoo with Set B Credentials"
echo "=================================================="
echo ""

# Configuration
DROPLET_NAME="odoo-production"
DROPLET_SIZE="s-2vcpu-4gb"
DROPLET_REGION="sgp1"
DROPLET_IMAGE="ubuntu-24-04-x64"
SSH_KEY_ID="51525133"  # digitalocean-droplet

OCR_DROPLET_IP="188.166.237.231"
ODOO_DOMAIN="insightpulseai.net"

# Set B Credentials
ADMIN_EMAIL="jgtolentino.rn@gmail.com"
ADMIN_PASSWORD="Postgres_26"
DATABASE_NAME="insightpulse_prod"

echo "Step 1: Provision Odoo Droplet"
echo "-------------------------------"
DROPLET_ID=$(doctl compute droplet create "$DROPLET_NAME" \
  --size "$DROPLET_SIZE" \
  --image "$DROPLET_IMAGE" \
  --region "$DROPLET_REGION" \
  --ssh-keys "$SSH_KEY_ID" \
  --wait \
  --format ID \
  --no-header)

echo "✅ Created droplet: $DROPLET_ID"

DROPLET_IP=$(doctl compute droplet get "$DROPLET_ID" --format PublicIPv4 --no-header)
echo "✅ Droplet IP: $DROPLET_IP"

echo ""
echo "⏳ Waiting for SSH to be ready..."
until ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@"$DROPLET_IP" "echo SSH ready" &>/dev/null; do
  sleep 5
done
echo "✅ SSH ready"

echo ""
echo "Step 2: Bootstrap System (Docker, Nginx, Certbot)"
echo "---------------------------------------------------"
ssh -o StrictHostKeyChecking=no root@"$DROPLET_IP" bash <<'REMOTE'
set -euo pipefail

# Install Docker
curl -fsSL https://get.docker.com | sh
systemctl enable --now docker

# Install Docker Compose V2
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-linux-x86_64 \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# Install Nginx and Certbot
apt-get update
apt-get install -y nginx certbot python3-certbot-nginx

# Verify installations
docker --version
docker compose version
nginx -v
certbot --version

echo "✅ Bootstrap complete"
REMOTE

echo ""
echo "Step 3: Upload Odoo Configuration Files"
echo "----------------------------------------"
REPO_ROOT="/Users/tbwa/Library/Mobile Documents/com~apple~CloudDocs/Documents/TBWA/odoboo-workspace"

ssh -o StrictHostKeyChecking=no root@"$DROPLET_IP" "mkdir -p /opt/odoo/{config,addons,oca}"

scp -o StrictHostKeyChecking=no "$REPO_ROOT/infra/odoo/docker-compose.yml" root@"$DROPLET_IP":/opt/odoo/
scp -o StrictHostKeyChecking=no "$REPO_ROOT/infra/odoo/config/odoo.conf" root@"$DROPLET_IP":/opt/odoo/config/
scp -o StrictHostKeyChecking=no "$REPO_ROOT/infra/odoo/nginx.conf" root@"$DROPLET_IP":/opt/odoo/

echo "✅ Configuration files uploaded"

echo ""
echo "Step 4: Configure Environment with Set B Credentials"
echo "-----------------------------------------------------"
ssh -o StrictHostKeyChecking=no root@"$DROPLET_IP" bash <<REMOTE
set -euo pipefail

cd /opt/odoo

# Generate strong DB password
DB_PASSWORD=\$(openssl rand -base64 32)

# Create .env file with Set B credentials
cat > .env <<EOF
# Database
DB_PASSWORD=\$DB_PASSWORD
POSTGRES_DB=$DATABASE_NAME
POSTGRES_USER=odoo

# Odoo
ODOO_TAG=18.0
ADMIN_PASSWORD=$ADMIN_PASSWORD

# OCR Integration
OCR_API_URL=https://ocr.insightpulseai.net/ocr
OCR_SECRET=PLACEHOLDER

# Domain
ODOO_DOMAIN=$ODOO_DOMAIN
EOF

# Retrieve OCR secret from existing OCR droplet
OCR_SECRET=\$(ssh -o StrictHostKeyChecking=no root@$OCR_DROPLET_IP "cat /etc/ocr/token" 2>/dev/null || echo "")
if [ -n "\$OCR_SECRET" ]; then
  sed -i "s|OCR_SECRET=PLACEHOLDER|OCR_SECRET=\$OCR_SECRET|" .env
  echo "✅ OCR secret retrieved"
else
  echo "⚠️  Could not retrieve OCR secret - manual configuration required"
fi

echo "✅ Environment configured"
echo ""
echo "📝 Credentials Summary:"
echo "   Database: $DATABASE_NAME"
echo "   Admin Email: $ADMIN_EMAIL"
echo "   Admin Password: $ADMIN_PASSWORD"
echo "   DB Password: \$DB_PASSWORD"
REMOTE

echo ""
echo "Step 5: Start Docker Compose Stack"
echo "-----------------------------------"
ssh -o StrictHostKeyChecking=no root@"$DROPLET_IP" bash <<'REMOTE'
set -euo pipefail

cd /opt/odoo
docker compose up -d db odoo

echo "⏳ Waiting for Odoo to be healthy..."
sleep 15

# Wait for Odoo health check
for i in {1..30}; do
  if docker compose exec -T odoo curl -sf http://localhost:8069/web/health &>/dev/null; then
    echo "✅ Odoo is healthy"
    break
  fi
  sleep 5
done
REMOTE

echo ""
echo "Step 6: Initialize Database and Create Admin"
echo "---------------------------------------------"
ssh -o StrictHostKeyChecking=no root@"$DROPLET_IP" bash <<REMOTE
set -euo pipefail

cd /opt/odoo

# Initialize database with base modules
docker compose exec -T odoo odoo \
  -d $DATABASE_NAME \
  -i base \
  --without-demo=all \
  --stop-after-init

echo "✅ Database initialized"

# Create admin user with Set B credentials
docker compose exec -T odoo odoo shell -d $DATABASE_NAME <<'PYEOF'
print("👤 Creating admin user...")

user = env['res.users'].search([('login', '=', 'admin')], limit=1)
if user:
    user.write({
        'login': '$ADMIN_EMAIL',
        'email': '$ADMIN_EMAIL',
        'password': '$ADMIN_PASSWORD',
    })
    print(f"✅ Admin user updated (ID: {user.id})")
else:
    user = env['res.users'].create({
        'name': 'Admin',
        'login': '$ADMIN_EMAIL',
        'email': '$ADMIN_EMAIL',
        'password': '$ADMIN_PASSWORD',
    })
    print(f"✅ Admin user created (ID: {user.id})")

# Grant admin rights
admin_group = env.ref('base.group_system')
if admin_group.id not in user.groups_id.ids:
    user.groups_id = [(4, admin_group.id)]
    print("✅ Admin rights granted")

env.cr.commit()
print("✅ Admin setup complete")
PYEOF

echo "✅ Admin user created: $ADMIN_EMAIL"
REMOTE

echo ""
echo "Step 7: Clone OCA Addons"
echo "------------------------"
ssh -o StrictHostKeyChecking=no root@"$DROPLET_IP" bash <<'REMOTE'
set -euo pipefail

cd /opt/odoo/oca

# Clone essential OCA repositories (Odoo 18)
echo "Cloning OCA repositories..."
git clone -b 18.0 --depth 1 https://github.com/OCA/web.git &
git clone -b 18.0 --depth 1 https://github.com/OCA/server-tools.git &
git clone -b 18.0 --depth 1 https://github.com/OCA/queue.git &
git clone -b 18.0 --depth 1 https://github.com/OCA/social.git &
git clone -b 18.0 --depth 1 https://github.com/OCA/project.git &
wait

echo "✅ OCA addons cloned"
REMOTE

echo ""
echo "Step 8: Install Notion Workspace"
echo "---------------------------------"

# Copy Notion workspace setup script
scp -o StrictHostKeyChecking=no "$REPO_ROOT/scripts/setup_notion_workspace.sh" root@"$DROPLET_IP":/opt/odoo/

ssh -o StrictHostKeyChecking=no root@"$DROPLET_IP" bash <<REMOTE
set -euo pipefail

cd /opt/odoo

# Restart Odoo with OCA addons
docker compose restart odoo
sleep 10

# Run Notion workspace setup
DB_NAME=$DATABASE_NAME ODOO_CTN=\$(docker compose ps -q odoo | xargs docker inspect --format '{{.Name}}' | sed 's|/||') bash setup_notion_workspace.sh

echo "✅ Notion workspace installed"
REMOTE

echo ""
echo "Step 9: Configure TLS with Let's Encrypt"
echo "-----------------------------------------"
echo ""
echo "⚠️  Manual DNS Configuration Required"
echo "   Add this A record to your DNS provider:"
echo "   $ODOO_DOMAIN -> $DROPLET_IP"
echo ""
read -p "Press Enter after DNS is configured..."

ssh -o StrictHostKeyChecking=no root@"$DROPLET_IP" bash <<REMOTE
set -euo pipefail

# Obtain TLS certificate
certbot certonly --standalone -d "$ODOO_DOMAIN" \
  --non-interactive \
  --agree-tos \
  --email admin@insightpulseai.net

# Update nginx configuration
sed -i "s|odoo.insightpulseai.net|$ODOO_DOMAIN|g" /opt/odoo/nginx.conf

# Start nginx
cd /opt/odoo
docker compose up -d nginx

echo "✅ TLS configured"
REMOTE

echo ""
echo "Step 10: Final Verification"
echo "----------------------------"
echo "Testing Odoo health..."
curl -sf "https://$ODOO_DOMAIN/web/health" && echo "✅ Health check passed" || echo "❌ Health check failed"

echo ""
echo "Testing login page..."
curl -sf "https://$ODOO_DOMAIN/web/login" | grep -q "Odoo" && echo "✅ Login page accessible" || echo "❌ Login failed"

echo ""
echo "=================================================="
echo "🎉 DEPLOYMENT COMPLETE!"
echo "=================================================="
echo ""
echo "🌐 Odoo URL: https://$ODOO_DOMAIN"
echo ""
echo "🔑 Login Credentials (Set B):"
echo "   Email:    $ADMIN_EMAIL"
echo "   Password: $ADMIN_PASSWORD"
echo "   Database: $DATABASE_NAME"
echo ""
echo "📊 Features Installed:"
echo "   ✅ Notion-style CI/CD Pipeline workspace"
echo "   ✅ 8 Kanban stages (Backlog → Deployed)"
echo "   ✅ 9 custom fields for PR/build tracking"
echo "   ✅ #ci-updates Discuss channel"
echo "   ✅ OCA modules (web, server-tools, queue, social, project)"
echo ""
echo "🎯 Next Steps:"
echo "   1. Log in at https://$ODOO_DOMAIN"
echo "   2. Navigate to Project → CI/CD Pipeline"
echo "   3. Install additional apps as needed"
echo "   4. Configure OCR integration in System Parameters"
echo ""
echo "💾 Droplet Info:"
echo "   ID: $DROPLET_ID"
echo "   IP: $DROPLET_IP"
echo "   SSH: ssh root@$DROPLET_IP"
echo ""
