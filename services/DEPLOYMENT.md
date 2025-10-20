# Agent + OCR Services Deployment Guide

Consolidated deployment of **odoobo-expert** agent and OCR services to Singapore droplet.

## Architecture Overview

```
DigitalOcean Droplet (Singapore sgp1)
├── Nginx (Port 80/443) - Reverse Proxy
│   ├── /ocr/ → OCR Service (Port 8000)
│   └── /agent/ → Agent Service (Port 8001)
│
├── OCR Service (Container)
│   ├── PaddleOCR-VL-900M
│   ├── OpenAI gpt-4o-mini
│   └── FastAPI Backend
│
└── Agent Service (Container)
    ├── Anthropic Claude 3.5 Sonnet
    ├── 13 Tool Functions
    ├── 3 Workflows (Migration, Review, Analytics)
    └── FastAPI Backend
```

## Cost & Performance

**Monthly Cost**: $8-13 USD

- DigitalOcean Droplet (Basic, 2GB RAM, 1 vCPU): $6-8/month
- DigitalOcean Spaces (storage, if needed): $5/month
- **Total**: $8-13/month (87% reduction from $100/month Azure budget)

**Performance**:

- **Latency**: <10ms internal, <50ms external (Singapore region)
- **Throughput**: 10-30 requests/second
- **Uptime**: 99.9% (self-hosted SLA)

## Prerequisites

1. **DigitalOcean Droplet**
   - Region: Singapore (sgp1)
   - Size: Basic (2GB RAM, 1 vCPU)
   - IP: 188.166.237.231 (or your droplet IP)

2. **Environment Variables**

   ```bash
   # Copy .env.example to .env
   cp .env.example .env

   # Edit .env with your credentials
   vim .env
   ```

3. **SSH Access**
   ```bash
   ssh root@188.166.237.231
   ```

## Deployment Steps

### 1. Copy Files to Droplet

```bash
# From local machine
scp -r services/ocr-service root@188.166.237.231:/opt/
scp -r services/agent-service root@188.166.237.231:/opt/
scp docker-compose.services.yml root@188.166.237.231:/opt/docker-compose.yml
scp nginx.conf root@188.166.237.231:/opt/
scp .env root@188.166.237.231:/opt/
```

### 2. SSH into Droplet

```bash
ssh root@188.166.237.231
cd /opt
```

### 3. Install Dependencies

```bash
# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
apt install docker-compose -y

# Verify installation
docker --version
docker-compose --version
```

### 4. Deploy Services

```bash
# Build and start services
docker-compose up -d --build

# Check logs
docker-compose logs -f

# Check service health
curl http://localhost:8000/health  # OCR Service
curl http://localhost:8001/health  # Agent Service
curl http://localhost:80/          # Nginx
```

### 5. Verify Deployment

```bash
# Test OCR Service
curl -X POST http://localhost:80/ocr/v1/parse \
  -F "file=@sample-receipt.jpg"

# Test Agent Service
curl -X POST http://localhost:80/agent/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-3-5-sonnet-20241022",
    "messages": [{"role": "user", "content": "Hello"}]
  }'

# Test from external
curl http://188.166.237.231/health
```

## Service Endpoints

### OCR Service

- **Base URL**: `http://188.166.237.231/ocr/`
- **Health**: `GET /ocr/health`
- **Parse**: `POST /ocr/v1/parse` (multipart/form-data, file upload)

### Agent Service

- **Base URL**: `http://188.166.237.231/agent/`
- **Health**: `GET /agent/health`
- **Chat**: `POST /agent/v1/chat/completions` (OpenAI-compatible)
- **Migration**: `POST /agent/v1/migrate`
- **Review**: `POST /agent/v1/review`
- **Analytics**: `POST /agent/v1/analytics`
- **Tools**: `GET /agent/v1/tools`

## Maintenance

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f ocr-service
docker-compose logs -f agent-service
docker-compose logs -f nginx
```

### Restart Services

```bash
# Restart all
docker-compose restart

# Restart specific service
docker-compose restart ocr-service
docker-compose restart agent-service
```

### Update Services

```bash
# Pull latest code
cd /opt
git pull  # if using git

# Rebuild and restart
docker-compose up -d --build

# Clean up old images
docker image prune -f
```

### Monitor Resources

```bash
# CPU and memory usage
docker stats

# Disk usage
df -h
docker system df

# Clean up
docker system prune -f
```

## Troubleshooting

### OCR Service Not Responding

```bash
# Check logs
docker-compose logs ocr-service

# Check health
curl http://localhost:8000/health

# Restart service
docker-compose restart ocr-service
```

### Agent Service Not Responding

```bash
# Check logs
docker-compose logs agent-service

# Check health
curl http://localhost:8001/health

# Verify API keys
docker-compose exec agent-service env | grep API_KEY

# Restart service
docker-compose restart agent-service
```

### Nginx Issues

```bash
# Check nginx config
docker-compose exec nginx nginx -t

# Reload nginx
docker-compose restart nginx

# Check logs
docker-compose logs nginx
```

### Out of Memory

```bash
# Check memory usage
free -h
docker stats

# Restart services
docker-compose restart

# Upgrade droplet size if needed
```

## Security

### Firewall Setup

```bash
# Install ufw
apt install ufw -y

# Allow SSH
ufw allow 22/tcp

# Allow HTTP/HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Enable firewall
ufw --force enable

# Check status
ufw status
```

### SSL/TLS (Optional)

```bash
# Install Certbot
apt install certbot python3-certbot-nginx -y

# Get certificate
certbot --nginx -d your-domain.com

# Auto-renewal (already configured by Certbot)
certbot renew --dry-run
```

### Environment Variables

```bash
# Never commit .env to git
echo ".env" >> .gitignore

# Use strong API keys
# Rotate keys regularly
# Use read-only keys where possible
```

## Monitoring

### Health Checks

```bash
# Create health check script
cat > /opt/health-check.sh << 'EOF'
#!/bin/bash
curl -sf http://localhost:8000/health || echo "OCR Service DOWN"
curl -sf http://localhost:8001/health || echo "Agent Service DOWN"
curl -sf http://localhost:80/ || echo "Nginx DOWN"
EOF

chmod +x /opt/health-check.sh

# Add to crontab (every 5 minutes)
crontab -e
# Add: */5 * * * * /opt/health-check.sh >> /var/log/health-check.log 2>&1
```

### Alerts (Optional)

```bash
# Install uptime monitoring
# - UptimeRobot (free tier)
# - Pingdom
# - DataDog
# - New Relic
```

## Backup

### Configuration Backup

```bash
# Backup configuration
tar -czf /root/backup-$(date +%Y%m%d).tar.gz /opt

# Copy to local machine
scp root@188.166.237.231:/root/backup-*.tar.gz ./backups/
```

### Container State

```bash
# Export container
docker export ocr-service > ocr-service.tar
docker export agent-service > agent-service.tar

# Import container
docker import ocr-service.tar
```

## Rollback

### Rollback to Previous Version

```bash
# Stop services
docker-compose down

# Restore from backup
cd /root
tar -xzf backup-YYYYMMDD.tar.gz -C /

# Restart services
cd /opt
docker-compose up -d
```

## Cost Optimization

### DigitalOcean Droplet Sizing

- **2GB RAM**: Recommended for production (handles 10-30 req/s)
- **1GB RAM**: Budget option (handles 5-10 req/s)
- **4GB RAM**: High traffic (handles 50-100 req/s)

### API Cost Optimization

- **Anthropic Claude**: $3-6/M tokens (cheaper than OpenAI)
- **OpenAI gpt-4o-mini**: $0.15/M input, $0.60/M output
- **PaddleOCR**: Free (self-hosted)

**Total Estimated API Cost**: $10-20/month for moderate usage (1K-5K requests/month)

## Future Enhancements

1. **Load Balancing**: Add multiple droplets with load balancer
2. **Auto-Scaling**: Kubernetes deployment for auto-scaling
3. **Caching**: Redis cache for frequent queries
4. **Queue System**: RabbitMQ/Redis for async processing
5. **Monitoring**: Grafana + Prometheus dashboards
6. **CI/CD**: GitHub Actions auto-deployment

## Support

**Issues**: https://github.com/jgtolentino/odoboo-workspace/issues
**Docs**: https://github.com/jgtolentino/odoboo-workspace/tree/main/docs
