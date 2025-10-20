# OCR Service Technical Specification

## Architecture Overview

FastAPI microservice providing OCR and visual diff capabilities for automated expense processing.

```
Mobile/Web App
    ↓ HTTPS/multipart-form
Supabase Edge Function (OCR proxy)
    ↓ HTTPS/JSON
DigitalOcean Droplet (OCR Service)
    - FastAPI application
    - PaddleOCR-VL-900M model
    - SSIM/LPIPS diff engine
    ↓ JSON response
Supabase PostgreSQL (expenses table)
```

## Technology Stack

### OCR Engine: PaddleOCR-VL-900M

**Why PaddleOCR-VL**:
- **Accuracy**: 95%+ on receipts, invoices, business documents
- **Multilingual**: English, Chinese, Japanese, Korean, Spanish, French
- **Open Source**: Apache 2.0 license, no vendor lock-in
- **Cost**: Free (self-hosted) vs. $1,000-$4,000/month for Azure Document Intelligence
- **Document Understanding**: Structured output with layout analysis

**Model Specifications**:
- Model size: 900M parameters
- Input: JPEG, PNG, PDF (max 10MB)
- Output: JSON with fields, confidence scores, text regions
- Processing time: P95 <30s on CPU (2vCPU), <3s on GPU

### API Framework: FastAPI

**Why FastAPI**:
- **Performance**: Async I/O, 2-3x faster than Flask
- **Type Safety**: Pydantic validation, automatic OpenAPI docs
- **Developer Experience**: Auto-generated Swagger UI at `/docs`
- **Production Ready**: Battle-tested, used by Uber, Netflix, Microsoft

**Framework Specifications**:
- Python 3.11+
- Uvicorn ASGI server
- Gunicorn process manager (production)
- 2 workers for 2vCPU droplet

### Diff Engine: SSIM + LPIPS

**Visual Similarity**:
- **SSIM** (Structural Similarity Index): Fast, lightweight, CPU-friendly
- **LPIPS** (Learned Perceptual Image Patch Similarity): ML-based, more accurate
- **Threshold**: SSIM <0.95 triggers "receipt changed" alert

**JSON Diff**:
- jsondiff library for field-by-field comparison
- Highlight changes in: amount, vendor, date, tax, description

## API Contract

### `POST /v1/parse`

Extract expense fields from receipt image.

**Request**:
```http
POST /v1/parse HTTP/1.1
Content-Type: multipart/form-data

file: <binary image data>
expense_id: 123 (optional)
```

**Response**:
```json
{
  "text": "RECEIPT\nOlive Garden\nDate: 2025-10-20\nTotal: $45.80\nTax: $4.12",
  "confidence": 0.92,
  "fields": {
    "vendor": "Olive Garden",
    "amount": 45.80,
    "date": "2025-10-20",
    "tax": 4.12,
    "currency": "USD",
    "payment_method": "Credit Card"
  },
  "processing_time_ms": 2800,
  "model": "PaddleOCR-VL-900M"
}
```

**Error Response**:
```json
{
  "error": "Invalid file format",
  "detail": "Only JPEG, PNG, PDF supported",
  "status_code": 400
}
```

### `POST /v1/compare`

Compare new receipt with original OCR data.

**Request**:
```http
POST /v1/compare HTTP/1.1
Content-Type: multipart/form-data

current_file: <binary image data>
original_ocr_data: {"fields": {...}} (JSON string)
```

**Response**:
```json
{
  "visual_similarity": 0.88,
  "ssim_score": 0.88,
  "lpips_score": 0.12,
  "json_diff": {
    "amount": {
      "old": 125.50,
      "new": 225.50,
      "change": "+"
    }
  },
  "changes_detected": true,
  "alert_threshold_exceeded": true
}
```

### `POST /v1/batch`

Process multiple receipts in parallel.

**Request**:
```http
POST /v1/batch HTTP/1.1
Content-Type: multipart/form-data

files: <binary image 1>
files: <binary image 2>
files: <binary image 3>
```

**Response**:
```json
{
  "total": 3,
  "successful": 3,
  "failed": 0,
  "results": [
    {"file_index": 0, "confidence": 0.95, "fields": {...}},
    {"file_index": 1, "confidence": 0.89, "fields": {...}},
    {"file_index": 2, "confidence": 0.91, "fields": {...}}
  ],
  "processing_time_ms": 8400
}
```

### `GET /health`

Health check endpoint for monitoring.

**Response**:
```json
{
  "status": "ok",
  "service": "ocr-service",
  "model_loaded": true,
  "version": "1.0.0",
  "uptime_seconds": 86400
}
```

## Deployment Architecture

### DigitalOcean Droplet Configuration

**Instance Specifications**:
- **Size**: s-2vcpu-4gb (2 vCPU, 4GB RAM)
- **Region**: Singapore (sgp1) - closest to Asia-Pacific users
- **OS**: Ubuntu 24.04 LTS
- **Cost**: $12/month

**Network Configuration**:
- **Public IP**: 188.166.237.231 (example)
- **Firewall**: UFW enabled, ports 22 (SSH), 80 (HTTP), 443 (HTTPS)
- **Internal Port**: 8000 (FastAPI, localhost-only binding)
- **Reverse Proxy**: NGINX → FastAPI on localhost:8000

**TLS/SSL**:
- **Certificate**: Let's Encrypt (Certbot)
- **Auto-Renewal**: Certbot systemd timer (every 12 hours)
- **Domain**: ocr.insightpulseai.net (example)
- **HTTPS Redirect**: HTTP → HTTPS (NGINX config)

### Docker Configuration

**Dockerfile**:
```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libgomp1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgl1 \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Run with Uvicorn
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
```

**docker-compose.yml**:
```yaml
version: "3.8"
services:
  ocr:
    image: registry.digitalocean.com/fin-workspace/ocr-service:prod
    container_name: ocr-service
    ports:
      - "127.0.0.1:8000:8000"  # Localhost-only binding
    environment:
      UVICORN_WORKERS: "2"
      LOG_LEVEL: "info"
      MIN_CONFIDENCE: "0.60"
      GPU_ENABLED: "false"
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "curl -fsS http://localhost:8000/health || exit 1"]
      interval: 30s
      timeout: 5s
      retries: 5
```

### NGINX Configuration

**`/etc/nginx/sites-available/ocr`**:
```nginx
server {
    listen 80;
    server_name ocr.insightpulseai.net;

    # Redirect HTTP → HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ocr.insightpulseai.net;

    # TLS certificates
    ssl_certificate /etc/letsencrypt/live/ocr.insightpulseai.net/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/ocr.insightpulseai.net/privkey.pem;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;

    # Reverse proxy to FastAPI
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Increase timeout for OCR processing
        proxy_read_timeout 90s;
        proxy_send_timeout 90s;

        # Increase max body size for images
        client_max_body_size 10M;
    }
}
```

## Performance Optimization

### CPU Mode (Current)

**Specifications**:
- 2 vCPU, 4GB RAM
- Processing time: P95 <30s per image
- Throughput: ~120 receipts/hour
- Cost: $12/month

**Optimization Strategies**:
- **Image Preprocessing**: Resize images to max 2048px before OCR
- **Batch Processing**: Process up to 10 images in parallel (async I/O)
- **Caching**: Cache OCR results in Supabase (keyed by image hash)
- **Connection Pooling**: Reuse HTTP connections to Supabase

### GPU Mode (Future)

**Specifications**:
- 1 GPU, 8GB VRAM
- Processing time: P95 <3s per image (10x faster)
- Throughput: ~1,200 receipts/hour
- Cost: $30-50/month

**Activation**:
```yaml
# docker-compose.yml
environment:
  GPU_ENABLED: "true"

# Requires GPU-enabled droplet
# DigitalOcean GPU droplet: g-2vcpu-8gb-nvidia-tesla-t4
```

### Caching Strategy

**Image Hash Caching**:
```python
import hashlib

def compute_image_hash(image_bytes):
    return hashlib.sha256(image_bytes).hexdigest()

# Check cache before OCR
image_hash = compute_image_hash(file.read())
cached_result = supabase.table("ocr_cache").select("*").eq("image_hash", image_hash).execute()

if cached_result.data:
    return cached_result.data[0]["ocr_result"]
else:
    # Perform OCR and cache result
    result = perform_ocr(image_bytes)
    supabase.table("ocr_cache").insert({
        "image_hash": image_hash,
        "ocr_result": result,
        "created_at": "now()"
    }).execute()
    return result
```

**Cache Invalidation**:
- TTL: 90 days (receipts rarely change after 3 months)
- Max cache size: 10,000 entries (~500MB storage)
- Eviction policy: LRU (least recently used)

## Security

### Input Validation

**File Type Validation**:
```python
ALLOWED_TYPES = ["image/jpeg", "image/png", "application/pdf"]

async def validate_file(file: UploadFile):
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(status_code=400, detail="Invalid file type")

    # Check file size (max 10MB)
    contents = await file.read()
    if len(contents) > 10 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="File too large (max 10MB)")

    # Check magic bytes (not just extension)
    if not is_valid_image(contents):
        raise HTTPException(status_code=400, detail="Invalid image format")

    return contents
```

### API Authentication

**Bearer Token (Optional)**:
```python
from fastapi import Header, HTTPException
import os

async def verify_token(authorization: str = Header(None)):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Unauthorized")

    token = authorization.replace("Bearer ", "")
    if token != os.getenv("OCR_API_KEY"):
        raise HTTPException(status_code=401, detail="Invalid token")

@app.post("/v1/parse", dependencies=[Depends(verify_token)])
async def process_ocr(...):
    ...
```

### Firewall Rules

**UFW Configuration**:
```bash
# Allow SSH
ufw allow 22/tcp

# Allow HTTP (redirects to HTTPS)
ufw allow 80/tcp

# Allow HTTPS
ufw allow 443/tcp

# DENY direct access to port 8000 (internal only)
ufw deny 8000/tcp

# Enable firewall
ufw enable
```

## Monitoring & Observability

### Health Checks

**Uptime Monitoring** (cron every 5 minutes):
```bash
#!/bin/bash
RESPONSE=$(curl -sf --max-time 10 https://ocr.insightpulseai.net/health)
if [ $? -ne 0 ]; then
  echo "❌ OCR service down"
  # Send alert (PagerDuty, Slack, email)
fi
```

### Logging

**Log Format** (JSON structured logs):
```json
{
  "timestamp": "2025-10-20T12:34:56Z",
  "level": "INFO",
  "service": "ocr-service",
  "endpoint": "/v1/parse",
  "expense_id": 123,
  "processing_time_ms": 2800,
  "confidence": 0.92,
  "success": true
}
```

**Log Aggregation**:
- **Local**: Docker logs (`docker logs ocr-service`)
- **Remote**: Logflare integration (Supabase Logs)
- **Retention**: 30 days

### Metrics

**Key Performance Indicators**:
- **Latency**: P50, P95, P99 processing time
- **Throughput**: Requests per minute
- **Error Rate**: 4xx, 5xx responses
- **Confidence Distribution**: Histogram of confidence scores
- **Cache Hit Rate**: % of requests served from cache

**Monitoring Tools**:
- **DigitalOcean Insights**: CPU, memory, disk, network
- **Custom Prometheus Exporter**: Application metrics
- **Grafana Dashboard**: Visualization

## Operational Runbook

**See**: [docs/OCR_SERVICE_DEPLOYMENT_GUIDE.md](../docs/OCR_SERVICE_DEPLOYMENT_GUIDE.md) for:
- Local development setup
- DigitalOcean deployment (UI + CLI)
- Odoo configuration and integration
- Troubleshooting common issues
- Cost breakdown and optimization

## References

- [OCR Expense Processing Spec](../spec/01-ocr-expense-processing.md) - User journeys and success criteria
- [Deployment Standards](./deployment.md) - General deployment procedures
- [Technology Stack](./stack.md) - PaddleOCR-VL rationale
- [OCR Deployment Guide](../docs/OCR_SERVICE_DEPLOYMENT_GUIDE.md) - Operational procedures
