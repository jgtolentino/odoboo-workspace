#!/usr/bin/env bash
set -euo pipefail

# Odoo Backend Deployment Script
# Provision DigitalOcean droplet, bootstrap Odoo, wire to OCR service

DROPLET_NAME="${DROPLET_NAME:-odoo-backend}"
DROPLET_SIZE="${DROPLET_SIZE:-s-2vcpu-4gb}"
DROPLET_REGION="${DROPLET_REGION:-sgp1}"
DROPLET_IMAGE="${DROPLET_IMAGE:-ubuntu-24-04-x64}"
SSH_KEY_ID="${SSH_KEY_ID:-}"  # Set via environment or doctl compute ssh-key list

OCR_DROPLET_IP="${OCR_DROPLET_IP:-188.166.237.231}"
ODOO_DOMAIN="${ODOO_DOMAIN:-odoo.insightpulseai.net}"

echo "==> Step 1: Provision Odoo Droplet"
if [ -z "$SSH_KEY_ID" ]; then
  echo "ERROR: SSH_KEY_ID not set. Run: doctl compute ssh-key list"
  exit 1
fi

DROPLET_ID=$(doctl compute droplet create "$DROPLET_NAME" \
  --size "$DROPLET_SIZE" \
  --image "$DROPLET_IMAGE" \
  --region "$DROPLET_REGION" \
  --ssh-keys "$SSH_KEY_ID" \
  --wait \
  --format ID \
  --no-header)

echo "Created droplet: $DROPLET_ID"

DROPLET_IP=$(doctl compute droplet get "$DROPLET_ID" --format PublicIPv4 --no-header)
echo "Droplet IP: $DROPLET_IP"

echo "Waiting for SSH to be ready..."
until ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@"$DROPLET_IP" "echo SSH ready" &>/dev/null; do
  sleep 5
done

echo "==> Step 2: Bootstrap Odoo with Docker Compose"
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

# Verify
docker --version
docker compose version

# Install Certbot for Let's Encrypt
apt-get update
apt-get install -y certbot python3-certbot-nginx

echo "Bootstrap complete"
REMOTE

echo "==> Step 3: Upload Odoo Configuration"
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

ssh -o StrictHostKeyChecking=no root@"$DROPLET_IP" "mkdir -p /opt/odoo/{config,addons,oca}"

scp -o StrictHostKeyChecking=no "$REPO_ROOT/infra/odoo/docker-compose.yml" root@"$DROPLET_IP":/opt/odoo/
scp -o StrictHostKeyChecking=no "$REPO_ROOT/infra/odoo/.env.sample" root@"$DROPLET_IP":/opt/odoo/.env
scp -o StrictHostKeyChecking=no "$REPO_ROOT/infra/odoo/config/odoo.conf" root@"$DROPLET_IP":/opt/odoo/config/
scp -o StrictHostKeyChecking=no "$REPO_ROOT/infra/odoo/nginx.conf" root@"$DROPLET_IP":/opt/odoo/

echo "==> Step 4: Configure Environment Variables"
ssh -o StrictHostKeyChecking=no root@"$DROPLET_IP" bash <<REMOTE
set -euo pipefail

cd /opt/odoo

# Generate strong passwords
DB_PASSWORD=\$(openssl rand -base64 32)
ADMIN_PASSWORD=\$(openssl rand -base64 32)

# Update .env file
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=\$DB_PASSWORD|" .env
sed -i "s|ADMIN_PASSWORD=.*|ADMIN_PASSWORD=\$ADMIN_PASSWORD|" .env
sed -i "s|ODOO_DOMAIN=.*|ODOO_DOMAIN=$ODOO_DOMAIN|" .env
sed -i "s|OCR_API_URL=.*|OCR_API_URL=https://ocr.insightpulseai.net/ocr|" .env

# Get OCR secret from OCR droplet
OCR_SECRET=\$(ssh -o StrictHostKeyChecking=no root@$OCR_DROPLET_IP "cat /etc/ocr/token" 2>/dev/null || echo "MISSING")
if [ "\$OCR_SECRET" = "MISSING" ]; then
  echo "WARNING: Could not retrieve OCR_SECRET from $OCR_DROPLET_IP"
  echo "Manually set OCR_SECRET in /opt/odoo/.env"
else
  sed -i "s|OCR_SECRET=.*|OCR_SECRET=\$OCR_SECRET|" .env
fi

echo "Environment configured. Admin password: \$ADMIN_PASSWORD"
echo "Save this password securely!"
REMOTE

echo "==> Step 5: Start Docker Compose Stack"
ssh -o StrictHostKeyChecking=no root@"$DROPLET_IP" bash <<'REMOTE'
set -euo pipefail

cd /opt/odoo

# Start db and odoo (nginx will fail without TLS certs)
docker compose up -d db odoo

echo "Waiting for Odoo to be healthy..."
until docker compose exec -T odoo curl -sf http://localhost:8069/web/health; do
  sleep 5
done

echo "Odoo is healthy"
REMOTE

echo "==> Step 6: Configure Let's Encrypt TLS"
ssh -o StrictHostKeyChecking=no root@"$DROPLET_IP" bash <<REMOTE
set -euo pipefail

# Initial Certbot setup (manual DNS verification required)
echo "Run the following command on your DNS provider:"
echo "  A Record: $ODOO_DOMAIN -> $DROPLET_IP"
echo ""
read -p "Press Enter after DNS is configured..."

certbot certonly --standalone -d "$ODOO_DOMAIN" --non-interactive --agree-tos --email admin@insightpulseai.net

# Update nginx.conf with actual domain
sed -i "s|odoo.insightpulseai.net|$ODOO_DOMAIN|g" /opt/odoo/nginx.conf

# Start nginx now that certs exist
cd /opt/odoo
docker compose up -d nginx

echo "TLS configured for $ODOO_DOMAIN"
REMOTE

echo "==> Step 7: Clone OCA Addons"
ssh -o StrictHostKeyChecking=no root@"$DROPLET_IP" bash <<'REMOTE'
set -euo pipefail

cd /opt/odoo/oca

# Clone essential OCA repositories (Odoo 18)
git clone -b 18.0 --depth 1 https://github.com/OCA/web.git
git clone -b 18.0 --depth 1 https://github.com/OCA/server-tools.git
git clone -b 18.0 --depth 1 https://github.com/OCA/queue.git
git clone -b 18.0 --depth 1 https://github.com/OCA/social.git
git clone -b 18.0 --depth 1 https://github.com/OCA/project.git

echo "OCA addons cloned"
REMOTE

echo "==> Step 8: Restart Odoo with OCA Addons"
ssh -o StrictHostKeyChecking=no root@"$DROPLET_IP" bash <<'REMOTE'
set -euo pipefail

cd /opt/odoo
docker compose restart odoo

echo "Waiting for Odoo to restart..."
sleep 10

until docker compose exec -T odoo curl -sf http://localhost:8069/web/health; do
  sleep 5
done

echo "Odoo restarted with OCA addons"
REMOTE

echo "==> Step 9: Sanity Checks"
echo "Testing Odoo health endpoint..."
curl -sf "https://$ODOO_DOMAIN/web/health" && echo "✅ Odoo health check passed" || echo "❌ Health check failed"

echo "Testing Odoo login page..."
curl -sf "https://$ODOO_DOMAIN/web/login" | grep -q "Odoo" && echo "✅ Login page accessible" || echo "❌ Login page failed"

echo ""
echo "==> Deployment Complete!"
echo ""
echo "Odoo URL: https://$ODOO_DOMAIN"
echo "Admin password: (see output from Step 4)"
echo ""
echo "Next steps:"
echo "1. Log in to Odoo and create a database"
echo "2. Install modules: knowledge, project, hr_expense, queue_job, web_responsive"
echo "3. Configure OCR integration in Settings -> Technical -> System Parameters"
echo "4. Test expense OCR workflow"
echo ""
echo "Manual module installation:"
echo "  ssh root@$DROPLET_IP"
echo "  cd /opt/odoo"
echo "  docker compose exec odoo odoo -d production -i knowledge,project,hr_expense,queue_job,web_responsive --stop-after-init"
