# OCR Service Quick Start

**60-Second Setup Guide** for PaddleOCR-VL OCR service on DigitalOcean droplet.

---

## Step 1: Choose Topology (5 seconds)

```
Same droplet? → http://127.0.0.1:8000/ocr (fast, internal)
Different host? → https://ocr.insightpulseai.net/ocr (secure, TLS required)
```

---

## Step 2A: Same Droplet Setup (30 seconds)

```bash
# Already deployed? Skip to Step 3
cd /opt/ocr && docker compose ps

# Set Odoo parameter
docker exec -it odoo18 odoo shell -d odoboo_local
env['ir.config_parameter'].sudo().set_param(
    'hr_expense_ocr_audit.ocr_api_url',
    'http://127.0.0.1:8000/ocr'
)
```

---

## Step 2B: Different Host Setup (55 seconds)

```bash
# 1. Deploy Nginx + TLS (40s)
tee /etc/nginx/sites-available/ocr.conf >/dev/null <<'NG'
server {
  listen 80;
  server_name ocr.insightpulseai.net;
  client_max_body_size 20m;
  location / { proxy_pass http://127.0.0.1:8000; include /etc/nginx/proxy_params; }
}
NG
ln -sf /etc/nginx/sites-available/ocr.conf /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
certbot --nginx -d ocr.insightpulseai.net

# 2. Firewall (5s)
ufw allow 80,443/tcp && ufw deny 8000/tcp 2375/tcp 2376/tcp

# 3. Set Odoo parameter (10s)
docker exec -it odoo18 odoo shell -d odoboo_local
env['ir.config_parameter'].sudo().set_param(
    'hr_expense_ocr_audit.ocr_api_url',
    'https://ocr.insightpulseai.net/ocr'
)
```

---

## Step 3: Verify (15 seconds)

```bash
# Health check (droplet)
curl -f http://127.0.0.1:8000/health

# Health check (nginx - if configured)
curl -f https://ocr.insightpulseai.net/health

# Odoo test
docker exec -it odoo18 odoo shell -d odoboo_local
import requests
url = env['ir.config_parameter'].sudo().get_param('hr_expense_ocr_audit.ocr_api_url')
print(requests.get(url.replace('/ocr','/health'), timeout=5).json())
# Expected: {"status":"ok","ocr_impl":"paddleocr-vl","version":"1.0.0"}
```

---

## Step 4: Queue Job Setup (10 seconds)

```bash
# Verify queue_job installed
docker exec -it odoo18 odoo shell -d odoboo_local
env['ir.module.module'].search([('name','=','queue_job')]).state
# Expected: 'installed'

# Create OCR channel (if not exists)
Channel = env['queue.job.channel']
Channel.create({'name': 'root:ocr', 'parent_id': env.ref('queue_job.channel_root').id, 'capacity': 5})

# Verify cron active
env['ir.cron'].search([('name','=','Process Pending OCR')]).active
# Expected: True
```

---

## Emergency Ops

```bash
# Restart OCR service
cd /opt/ocr && docker compose restart

# Check logs
docker logs ocr-service --tail 50

# Snapshot now
doctl compute droplet-action snapshot 525178434 --snapshot-name "ocr-$(date +%F)" --wait

# Update image
docker pull registry.digitalocean.com/fin-workspace/ocr-service:prod
cd /opt/ocr && docker compose up -d
```

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| 502 Bad Gateway | `docker compose restart && nginx -t && systemctl reload nginx` |
| TLS cert expired | `certbot renew` |
| Odoo can't reach OCR | Check firewall: `ufw status` |
| Slow OCR processing | Check queue: `docker logs ocr-service` |

---

**Full Documentation**: [docs/OCR_SERVICE_DEPLOYMENT.md](OCR_SERVICE_DEPLOYMENT.md)

**Droplet**: `188.166.237.231` (Singapore)
**Domain**: `ocr.insightpulseai.net`
**Registry**: `registry.digitalocean.com/fin-workspace/ocr-service:prod`
