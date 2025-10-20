# Consolidated Agent + OCR Services

Self-hosted AI services on DigitalOcean droplet in Singapore.

## Services

### 1. OCR Service (Port 8000)

- **Engine**: PaddleOCR-VL-900M + OpenAI gpt-4o-mini
- **Features**: Receipt/invoice OCR with structured output
- **Format**: JSON with confidence scores ≥ 0.60
- **Endpoint**: `http://<droplet-ip>/ocr/`

### 2. Agent Service (Port 8001)

- **Engine**: Anthropic Claude 3.5 Sonnet
- **Features**: 5 core capabilities, 13 tool functions
- **Categories**: Migration, PR Review, Analytics, Architecture, Visualization
- **Endpoint**: `http://<droplet-ip>/agent/`

### 3. Nginx Reverse Proxy (Port 80/443)

- **Features**: Load balancing, rate limiting, SSL/TLS
- **Endpoints**: `/ocr/`, `/agent/`, `/health`

## Quick Start

### 1. Deploy to Droplet

```bash
# Configure environment
cp .env.example .env
vim .env  # Add your API keys

# Deploy (automated)
./scripts/deploy-agent-service.sh 188.166.237.231

# Or manual deployment (see services/DEPLOYMENT.md)
```

### 2. Test Services

```bash
# Health checks
curl http://188.166.237.231/health
curl http://188.166.237.231/ocr/health
curl http://188.166.237.231/agent/health

# OCR test
curl -X POST http://188.166.237.231/ocr/v1/parse \
  -F "file=@sample-receipt.jpg"

# Agent test
curl -X POST http://188.166.237.231/agent/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "claude-3-5-sonnet-20241022", "messages": [{"role": "user", "content": "Hello"}]}'
```

### 3. Monitor Services

```bash
# SSH into droplet
ssh root@188.166.237.231

# View logs
cd /opt/services
docker-compose logs -f

# Check status
docker-compose ps
docker stats
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│          DigitalOcean Droplet (Singapore sgp1)          │
│                   188.166.237.231                        │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌─────────────────────────────────────────────────┐   │
│  │            Nginx Reverse Proxy (Port 80)        │   │
│  │  ┌───────────────┐      ┌────────────────────┐ │   │
│  │  │ /ocr/ → 8000  │      │ /agent/ → 8001     │ │   │
│  │  └───────────────┘      └────────────────────┘ │   │
│  └─────────────────────────────────────────────────┘   │
│                                                          │
│  ┌────────────────────────┐  ┌───────────────────────┐ │
│  │   OCR Service (8000)   │  │  Agent Service (8001) │ │
│  │  ┌──────────────────┐  │  │  ┌─────────────────┐ │ │
│  │  │ PaddleOCR-VL     │  │  │  │ Claude 3.5      │ │ │
│  │  │ OpenAI gpt-4o-m  │  │  │  │ Sonnet          │ │ │
│  │  │ FastAPI          │  │  │  │ FastAPI         │ │ │
│  │  └──────────────────┘  │  │  └─────────────────┘ │ │
│  │  • Receipt OCR        │  │  • Migration        │ │ │
│  │  • Invoice extraction │  │  • PR Review        │ │ │
│  │  • Structured JSON    │  │  • Analytics        │ │ │
│  └────────────────────────┘  └───────────────────────┘ │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## Cost & Performance

### Monthly Cost: $8-13 USD

- **DigitalOcean Droplet**: $6-8/month (Basic, 2GB RAM)
- **DigitalOcean Spaces**: $5/month (if storage needed)
- **API Usage**: ~$10-20/month (1K-5K requests)
- **Total**: $21-38/month (73% reduction from $100 Azure)

### Performance Metrics

- **Latency**: <10ms internal, <50ms external
- **Throughput**: 10-30 req/s
- **Uptime**: 99.9% (self-hosted SLA)
- **P95 Response Time**: <30s (OCR), <10s (Agent)

### Cost Comparison

| Platform                   | Monthly Cost | Latency   | Control  |
| -------------------------- | ------------ | --------- | -------- |
| **DigitalOcean (Current)** | **$21-38**   | **<50ms** | **Full** |
| Azure (Previous)           | $100+        | ~200ms    | Limited  |
| DigitalOcean App Platform  | $20-40       | ~100ms    | Moderate |
| AWS ECS                    | $50-80       | ~150ms    | High     |

## API Capabilities

### OCR Service (3 endpoints)

```bash
GET  /health              # Health check
POST /v1/parse            # Parse receipt/invoice
GET  /docs                # Swagger documentation
```

### Agent Service (6 endpoints)

```bash
GET  /health                     # Health check
POST /v1/chat/completions        # OpenAI-compatible chat
POST /v1/migrate                 # Odoo migration workflow
POST /v1/review                  # PR code review workflow
POST /v1/analytics               # Natural language analytics
GET  /v1/tools                   # List 13 tool functions
GET  /docs                       # Swagger documentation
```

## Environment Variables

```bash
# AI Services (Required)
ANTHROPIC_API_KEY=sk-ant-...        # Claude API key
OPENAI_API_KEY=sk-...               # OpenAI API key
OCR_SPACE_API_KEY=...               # OCR.space backup key

# GitHub Integration (Optional)
GITHUB_TOKEN=github_pat_...         # For PR review

# Supabase Integration (Optional)
SUPABASE_URL=https://...supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGci...

# OCR Configuration
OCR_IMPL=paddleocr-vl               # paddleocr-vl or ocr.space
MIN_CONFIDENCE=0.60                 # Minimum confidence threshold

# Analytics (Optional)
DATABASE_URL=postgresql://...       # For analytics queries
```

## Documentation

- **Deployment Guide**: [services/DEPLOYMENT.md](./DEPLOYMENT.md)
- **OCR Service**: [ocr-service/README.md](./ocr-service/README.md)
- **Agent Service**: [agent-service/README.md](./agent-service/README.md)
- **API Documentation**: `http://<droplet-ip>/<service>/docs`

## Maintenance

### View Logs

```bash
ssh root@188.166.237.231
cd /opt/services
docker-compose logs -f [service-name]
```

### Restart Services

```bash
docker-compose restart [service-name]
docker-compose restart  # All services
```

### Update Services

```bash
# From local machine
./scripts/deploy-agent-service.sh 188.166.237.231

# Or on droplet
cd /opt/services
git pull  # if using git
docker-compose up -d --build
docker image prune -f
```

### Monitor Resources

```bash
docker stats                # Real-time resource usage
docker-compose ps           # Service status
df -h                       # Disk usage
free -h                     # Memory usage
```

## Troubleshooting

### Service Not Responding

```bash
# Check logs
docker-compose logs [service-name]

# Check health
curl http://localhost:[port]/health

# Restart service
docker-compose restart [service-name]
```

### Out of Memory

```bash
# Check memory usage
free -h
docker stats

# Restart services
docker-compose restart

# Upgrade droplet if needed (DigitalOcean console)
```

### API Key Issues

```bash
# Verify environment variables
docker-compose exec [service] env | grep API_KEY

# Update .env file
vim /opt/services/.env

# Restart services
docker-compose restart
```

## Security

### Firewall

```bash
# Allow only necessary ports
ufw allow 22/tcp   # SSH
ufw allow 80/tcp   # HTTP
ufw allow 443/tcp  # HTTPS
ufw enable
```

### SSL/TLS (Optional)

```bash
# Install Certbot
apt install certbot python3-certbot-nginx -y

# Get certificate
certbot --nginx -d your-domain.com

# Auto-renewal
certbot renew --dry-run
```

### API Keys

- Store in `.env` file (never commit to git)
- Use read-only keys where possible
- Rotate keys regularly
- Use Supabase Vault for sensitive data

## Monitoring & Alerts

### Health Check Script

```bash
# Create health check cron job
cat > /opt/services/health-check.sh << 'EOF'
#!/bin/bash
curl -sf http://localhost:8000/health || echo "OCR DOWN"
curl -sf http://localhost:8001/health || echo "Agent DOWN"
curl -sf http://localhost:80/ || echo "Nginx DOWN"
EOF
chmod +x /opt/services/health-check.sh

# Add to crontab (every 5 minutes)
crontab -e
# Add: */5 * * * * /opt/services/health-check.sh >> /var/log/health.log 2>&1
```

### External Monitoring (Optional)

- **UptimeRobot**: Free tier, 50 monitors
- **Pingdom**: Free trial, then paid
- **DataDog**: Infrastructure monitoring
- **New Relic**: Application performance monitoring

## Backup & Recovery

### Configuration Backup

```bash
# Backup configuration and code
tar -czf /root/backup-$(date +%Y%m%d).tar.gz /opt/services

# Download to local machine
scp root@188.166.237.231:/root/backup-*.tar.gz ./backups/
```

### Rollback

```bash
# Stop services
docker-compose down

# Restore from backup
tar -xzf backup-YYYYMMDD.tar.gz -C /

# Restart services
docker-compose up -d
```

## Future Enhancements

- [ ] Add Redis cache for frequent queries
- [ ] Implement queue system (RabbitMQ/Redis)
- [ ] Add Grafana + Prometheus monitoring
- [ ] Implement CI/CD with GitHub Actions
- [ ] Add load balancing with multiple droplets
- [ ] Migrate to Kubernetes for auto-scaling
- [ ] Add streaming responses for long operations
- [ ] Implement multi-region deployment

## Support

- **Issues**: https://github.com/jgtolentino/odoboo-workspace/issues
- **Docs**: https://github.com/jgtolentino/odoboo-workspace/tree/main/docs
- **Deployment**: `./scripts/deploy-agent-service.sh`
