#!/usr/bin/env bash
# One-Shot Production Deployment for Odoo 18 + OCR + Agent Services
#
# Prerequisites:
# - Point insightpulseai.net (and www) to your droplet IP
# - Run as root on Ubuntu 22.04/24.04
#
# Usage:
#   sudo bash deploy_production_oneshot.sh
#
# Or with custom settings:
#   DOMAIN=your-domain.com EMAIL=admin@your-domain.com sudo bash deploy_production_oneshot.sh

set -euo pipefail

##### CONFIG (override via env or edit here) ###################################
: "${DOMAIN:=insightpulseai.net}"
: "${EMAIL:=admin@insightpulseai.net}"
: "${ODOO_DB:=insightpulse_prod}"
: "${DB_PASSWORD:=odoo_db_$(openssl rand -hex 8)}"
: "${ADMIN_PASSWORD:=Admin_$(openssl rand -hex 4)}"
: "${OCR_CONFIDENCE:=0.6}"
: "${ODOO_VERSION:=18}"
: "${PG_MAJOR:=15}"

echo "=== One-Shot Deploy for ${DOMAIN} ==="
echo "Odoo DB: ${ODOO_DB}"
echo "Admin (master) password: ${ADMIN_PASSWORD}"
echo "Postgres password: ${DB_PASSWORD}"
echo

##### SYSTEM PREP ##############################################################
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release ufw jq software-properties-common
# Docker
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
  > /etc/apt/sources.list.d/docker.list
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# Nginx + Certbot
apt-get install -y nginx certbot python3-certbot-nginx

systemctl enable --now docker
systemctl enable --now nginx

##### FIREWALL #################################################################
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

##### FOLDERS ##################################################################
mkdir -p /opt/fin-workspace/{config,compose,addons,oca,logs}
cd /opt/fin-workspace

##### OCA MODULES (minimal set) ###############################################
# Web responsiveness, audit log, queue jobs
apt-get install -y git
mkdir -p /opt/fin-workspace/oca
cd /opt/fin-workspace/oca
[ -d web ] || git clone --depth 1 -b "${ODOO_VERSION}.0" https://github.com/OCA/web.git
[ -d server-tools ] || git clone --depth 1 -b "${ODOO_VERSION}.0" https://github.com/OCA/server-tools.git
[ -d queue ] || git clone --depth 1 -b "${ODOO_VERSION}.0" https://github.com/OCA/queue.git
cd /opt/fin-workspace

##### ODOO CONFIG ##############################################################
cat > /opt/fin-workspace/config/odoo.conf <<EOF
[options]
admin_passwd = ${ADMIN_PASSWORD}
db_host = db
db_port = 5432
db_user = odoo
db_password = ${DB_PASSWORD}
proxy_mode = True
xmlrpc_port = 8069
longpolling_port = 8072
limit_memory_soft = 2147483648
limit_memory_hard = 2684354560
limit_time_cpu = 600
limit_time_real = 1200
max_cron_threads = 1
workers = 2
addons_path = /usr/lib/python3/dist-packages/odoo/addons,/mnt/extra-addons,/mnt/oca-addons/web,/mnt/oca-addons/server-tools,/mnt/oca-addons/queue
logfile = /var/log/odoo/odoo.log
EOF

##### DOCKER COMPOSE ###########################################################
cat > /opt/fin-workspace/compose/docker-compose.yml <<'YML'
version: "3.9"
services:
  db:
    image: postgres:15
    environment:
      POSTGRES_DB: odoo
      POSTGRES_USER: odoo
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - db-data:/var/lib/postgresql/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL","pg_isready -U odoo -d odoo"]
      interval: 10s
      timeout: 5s
      retries: 10
    networks: [fw-net]

  odoo18:
    image: odoo:18
    depends_on:
      db:
        condition: service_healthy
    environment:
      HOST: db
      USER: odoo
      PASSWORD: ${DB_PASSWORD}
    volumes:
      - /opt/fin-workspace/addons:/mnt/extra-addons
      - /opt/fin-workspace/oca/web:/mnt/oca-addons/web
      - /opt/fin-workspace/oca/server-tools:/mnt/oca-addons/server-tools
      - /opt/fin-workspace/oca/queue:/mnt/oca-addons/queue
      - /opt/fin-workspace/config/odoo.conf:/etc/odoo/odoo.conf
      - odoo-data:/var/lib/odoo
      - /opt/fin-workspace/logs:/var/log/odoo
    ports:
      - "127.0.0.1:8069:8069"
      - "127.0.0.1:8072:8072"
    restart: unless-stopped
    networks: [fw-net]

  # OCR service: build locally from repo path if present; else comment image/build and use your existing image.
  ocr-service:
    build:
      context: /opt/fin-workspace/src/services/ocr-service
      dockerfile: Dockerfile
      args:
        - TARGETARCH=amd64
    platform: linux/amd64
    environment:
      - UVICORN_WORKERS=2
    ports:
      - "127.0.0.1:8000:8000"
    restart: unless-stopped
    networks: [fw-net]

  # Agent service: simple FastAPI (adjust if you have another impl)
  agent-service:
    build:
      context: /opt/fin-workspace/src/services/agent-service
      dockerfile: Dockerfile
    ports:
      - "127.0.0.1:8001:8001"
    restart: unless-stopped
    networks: [fw-net]

volumes:
  db-data:
  odoo-data:

networks:
  fw-net:
    driver: bridge
YML

##### NGINX ROUTING (host nginx reverse proxy) #################################
cat > /etc/nginx/sites-available/${DOMAIN} <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN} www.${DOMAIN};
    location /.well-known/acme-challenge/ { root /var/www/html; }
    location / { return 301 https://\$host\$request_uri; }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ${DOMAIN} www.${DOMAIN};

    ssl_certificate     /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
    add_header Strict-Transport-Security "max-age=31536000" always;

    client_max_body_size 100M;
    proxy_read_timeout 300s;

    # Odoo
    location /longpolling {
        proxy_pass http://127.0.0.1:8072;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
    }
    location /web/ {
        proxy_pass http://127.0.0.1:8069;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
    location / {
        proxy_pass http://127.0.0.1:8069;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    # OCR
    location /ocr/ {
        proxy_pass http://127.0.0.1:8000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-Proto https;
    }

    # Agent
    location /agent/ {
        proxy_pass http://127.0.0.1:8001/;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-Proto https;
    }
}
EOF

mkdir -p /var/www/html
nginx -t
ln -sf /etc/nginx/sites-available/${DOMAIN} /etc/nginx/sites-enabled/${DOMAIN}
systemctl reload nginx || true

##### TLS (issue cert before enabling SSL block fully) #########################
# Temporarily serve http challenge off default server:
systemctl stop nginx
certbot certonly --standalone -d "${DOMAIN}" -d "www.${DOMAIN}" --agree-tos -m "${EMAIL}" --non-interactive --no-eff-email
systemctl start nginx
systemctl reload nginx

##### SOURCE CODE (optional placeholders) #####################################
# If your repo is not already here, clone it so OCR/Agent builds can run:
[ -d /opt/fin-workspace/src ] || mkdir -p /opt/fin-workspace/src
# Place your services here (adjust if already present):
# git clone https://github.com/jgtolentino/odoboo-workspace.git /opt/fin-workspace/src
# (Ensure Dockerfiles exist at src/services/ocr-service and src/services/agent-service)

##### START STACK ##############################################################
cd /opt/fin-workspace/compose
echo "DB_PASSWORD=${DB_PASSWORD}" > .env
docker compose pull || true
docker compose up -d --build

##### INIT ODOO DB + MODULES ###################################################
echo "→ Waiting for Odoo to start…"
for i in {1..60}; do
  curl -fsS http://127.0.0.1:8069 >/dev/null 2>&1 && break || sleep 3
done

# Create DB (idempotent)
docker compose exec -T odoo18 odoo -i base --without-demo=all \
  -d "${ODOO_DB}" --db_host db --db_port 5432 --db_user odoo --db_password "${DB_PASSWORD}" \
  --stop-after-init || true

# Install core modules (idempotent)
docker compose exec -T odoo18 odoo -d "${ODOO_DB}" \
  -i web_responsive,auditlog,queue_job,hr,hr_expense \
  --stop-after-init || true

# Configure OCR endpoint + confidence
docker compose exec -T odoo18 bash -lc "python3 - <<'PY'
import odoo, odoo.tools.config as c
c['db_name'] = '${ODOO_DB}'
odoo.cli.server.report_configuration()
from odoo.tools import config
from odoo.service import db
import odoo.api as api
odoo.tools.config['db_name'] = '${ODOO_DB}'
odoo.registry('${ODOO_DB}')
with odoo.api.Environment.manage():
    cr = odoo.sql_db.db_connect('${ODOO_DB}').cursor()
    env = api.Environment(cr, odoo.SUPERUSER_ID, {})
    ICP = env['ir.config_parameter'].sudo()
    ICP.set_param('hr_expense_ocr_audit.ocr_api_url', 'https://${DOMAIN}/ocr')
    ICP.set_param('hr_expense_ocr_audit.confidence_threshold', '${OCR_CONFIDENCE}')
    cr.commit(); cr.close()
print('Configured OCR URL + confidence')
PY"

##### NGINX RELOAD (now with certs) ###########################################
nginx -t && systemctl reload nginx

##### HEALTH CHECKS ############################################################
echo "=== Health ==="
curl -f -s https://${DOMAIN}/web/login >/dev/null && echo "Odoo: OK" || echo "Odoo: FAIL"
curl -f -s https://${DOMAIN}/ocr/health   || echo "OCR: check logs (building may take long)"
curl -f -s https://${DOMAIN}/agent/health || echo "Agent: check logs"

echo
echo "=== Done ==="
echo "URL:  https://${DOMAIN}"
echo "DB:   ${ODOO_DB}"
echo "Admin master password (keep safe): ${ADMIN_PASSWORD}"
echo "Postgres password: ${DB_PASSWORD}"
echo "Tip: create your Odoo user in UI and generate an API Key."
