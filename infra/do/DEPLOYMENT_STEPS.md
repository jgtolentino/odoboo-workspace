# OCR Service Deployment to DigitalOcean Droplet

## Prerequisites
- Droplet: `188.166.237.231` (ocr-service-droplet, Singapore)
- Registry: `registry.digitalocean.com/fin-workspace`
- Image: `ocr-service:amd64`

## Step 1: Build & Push AMD64 Image

```bash
# Create buildx builder
docker buildx create --name ocrbuilder --driver docker-container --use
docker buildx inspect --bootstrap

# Build and push AMD64 image
cd services/ocr-service
docker buildx build --platform linux/amd64 \
  -t registry.digitalocean.com/fin-workspace/ocr-service:amd64 \
  --push .

# Verify image
docker buildx imagetools inspect registry.digitalocean.com/fin-workspace/ocr-service:amd64
```

## Step 2: Deploy on Droplet

### Copy files to droplet
```bash
scp infra/do/docker-compose-droplet.yml root@188.166.237.231:/root/docker-compose.yml
```

### On droplet (SSH: root@188.166.237.231)
```bash
# Login to registry
doctl registry login

# Pull and start service
docker compose pull && docker compose up -d

# Check status
docker compose ps
docker compose logs -f ocr
```

## Step 3: Test Health Endpoint

```bash
curl http://188.166.237.231:8000/health
```

Expected response:
```json
{
  "status": "ok",
  "service": "ocr-service",
  "model_loaded": true
}
```

## Step 4: (Optional) Setup Nginx + HTTPS

### Install Nginx
```bash
sudo apt update && sudo apt install -y nginx
sudo ufw allow "Nginx Full"
```

### Configure reverse proxy
```bash
# Copy nginx config
sudo cp nginx-ocr.conf /etc/nginx/sites-available/ocr.yourdomain.com

# Enable site
sudo ln -s /etc/nginx/sites-available/ocr.yourdomain.com /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

### Install SSL certificate
```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d ocr.yourdomain.com
sudo certbot renew --dry-run
```

## Step 5: Configure Odoo

In Odoo (Technical → Parameters → System Parameters):

```
Key: hr_expense_ocr_audit.ocr_api_url
Val: http://188.166.237.231:8000/ocr
# OR with HTTPS: https://ocr.yourdomain.com/ocr
```

## Maintenance Commands

### Update OCR service
```bash
docker compose pull && docker compose up -d
```

### View logs
```bash
docker compose logs -f ocr
```

### Restart service
```bash
docker compose restart ocr
```

### Check health
```bash
curl http://localhost:8000/health
```

## Troubleshooting

### Container won't start
```bash
docker compose logs ocr
docker ps -a
```

### Platform mismatch error
Ensure you built for `linux/amd64`:
```bash
docker buildx imagetools inspect registry.digitalocean.com/fin-workspace/ocr-service:amd64
```

### Port already in use
```bash
sudo lsof -i :8000
docker compose down
```
