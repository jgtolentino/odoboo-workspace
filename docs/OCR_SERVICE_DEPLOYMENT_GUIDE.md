# OCR Service Deployment Guide

Complete deployment guide for PaddleOCR-VL expense document processing service.

## Overview

FastAPI microservice providing OCR and visual diff capabilities for Odoo HR expense management:

- **PaddleOCR** for text extraction
- **Visual comparison** with SSIM/LPIPS
- **JSON diff** for structured data
- **Batch processing** support
- **DigitalOcean deployment** ready

## Architecture

```
Odoo (hr_expense_ocr_audit module)
    ↓ HTTP/JSON
DigitalOcean App Platform (OCR Service)
    - FastAPI application
    - PaddleOCR-VL engine
    - Diff engine
    ↓ Response
Odoo expense record updated
```

## Prerequisites

### Local Development
- Python 3.11+
- pip
- Docker (optional for testing)

### Production Deployment
- DigitalOcean account
- GitHub repository
- doctl CLI configured

## Local Development Setup

### 1. Clone Repository

```bash
cd /path/to/odoboo-workspace
```

### 2. Install Dependencies

```bash
cd services/ocr-service
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

pip install -r requirements.txt
```

### 3. Run Service

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### 4. Test Endpoints

```bash
# Health check
curl http://localhost:8000/health

# OCR test
curl -X POST http://localhost:8000/ocr \
  -F "file=@sample_receipt.jpg" \
  -F "expense_id=123"
```

## DigitalOcean Deployment

### Option 1: App Platform UI

1. **Create App:**
   - Go to DigitalOcean App Platform
   - Click "Create App"
   - Connect GitHub repository
   - Select `odoboo-workspace` repo

2. **Configure Service:**
   - **Type:** Web Service
   - **Source Directory:** `services/ocr-service`
   - **Dockerfile Path:** `services/ocr-service/Dockerfile`
   - **HTTP Port:** 8000
   - **Instance Size:** Basic (512MB RAM, 1 vCPU) - $5/month

3. **Environment Variables:**
   ```
   MODEL_NAME=PaddleOCR
   MIN_CONFIDENCE=0.60
   GPU_ENABLED=false
   LOG_LEVEL=INFO
   ```

4. **Health Check:**
   - **Path:** `/health`
   - **Initial Delay:** 60 seconds
   - **Period:** 30 seconds

5. **Deploy:**
   - Click "Create Resources"
   - Wait for build (~5 minutes)
   - Note app URL: `https://ocr-api-xxxxx.ondigitalocean.app`

### Option 2: doctl CLI

```bash
# Authenticate
doctl auth init

# Create app from spec
doctl apps create --spec infra/do/ocr-service.yaml

# Get app ID
doctl apps list

# View deployment logs
doctl apps logs <app-id> --follow

# Get app URL
doctl apps get <app-id>
```

## Odoo Configuration

### 1. Update System Parameters

```
Settings → Technical → System Parameters

# Add/update:
hr_expense_ocr_audit.ocr_api_url = https://ocr-api-xxxxx.ondigitalocean.app/ocr
hr_expense_ocr_audit.ocr_api_key = (optional bearer token)
hr_expense_ocr_audit.visual_diff_threshold = 0.95
```

### 2. Install Module

```bash
# Update Odoo addons path
docker exec -i odoo18 odoo -d odoboo_local \
  -i hr_expense_ocr_audit \
  --stop-after-init

# Restart Odoo
docker-compose -f docker-compose.local.yml restart odoo
```

### 3. Test Integration

```
# In Odoo:
1. Create expense
2. Upload receipt image
3. Click "Process OCR" button
4. Verify fields auto-filled
```

## API Documentation

### Endpoints

#### `POST /ocr`

Process expense document through OCR.

**Request:**
```bash
curl -X POST https://ocr-api-xxxxx.ondigitalocean.app/ocr \
  -F "file=@receipt.jpg" \
  -F "expense_id=123" \
  -F "employee_id=5"
```

**Response:**
```json
{
  "confidence": 0.92,
  "extracted_fields": {
    "total_amount": 125.50,
    "date": "2025-10-20",
    "vendor": "Starbucks Coffee",
    "description": "Business meeting coffee",
    "tax_amount": 12.55,
    "currency": "USD",
    "payment_method": "Credit Card"
  },
  "text_regions": [...],
  "layout_analysis": {...},
  "raw_text": "..."
}
```

#### `POST /compare`

Compare current document with original.

**Request:**
```bash
curl -X POST https://ocr-api-xxxxx.ondigitalocean.app/compare \
  -F "current_file=@receipt_v2.jpg" \
  -F 'original_ocr_data={"extracted_fields": {...}}' \
  -F "expense_id=123"
```

**Response:**
```json
{
  "visual_similarity": 0.88,
  "json_diff": {
    "total_amount": {
      "old": 125.50,
      "new": 225.50
    }
  },
  "changes_detected": true
}
```

#### `POST /batch_ocr`

Process multiple documents in batch.

**Request:**
```bash
curl -X POST https://ocr-api-xxxxx.ondigitalocean.app/batch_ocr \
  -F "files=@receipt1.jpg" \
  -F "files=@receipt2.jpg"
```

## Performance Optimization

### CPU vs GPU

**CPU Mode** (Current):
- Cost: $5/month (Basic droplet)
- Processing: ~3-5 seconds per image
- Suitable for: <100 receipts/day

**GPU Mode** (Future):
- Cost: $30-50/month (GPU droplet)
- Processing: ~0.3-0.5 seconds per image
- Suitable for: >1000 receipts/day

To enable GPU:
```yaml
# infra/do/ocr-service.yaml
envs:
  - key: GPU_ENABLED
    value: "true"

# Requires GPU-enabled instance size
instance_size_slug: gpu-basic
```

### Caching

OCR results are cached in Odoo `hr.expense` records:
- `ocr_payload`: Full OCR result
- `original_ocr_payload`: First extraction for comparison
- No need for Redis or external cache

## Monitoring

### Health Checks

```bash
# Basic health
curl https://ocr-api-xxxxx.ondigitalocean.app/health

# Expected response
{
  "status": "ok",
  "service": "ocr-service",
  "model_loaded": true
}
```

### Logs

```bash
# DigitalOcean CLI
doctl apps logs <app-id> --follow --type run

# View in UI
DigitalOcean → Apps → <app-name> → Runtime Logs
```

### Metrics

DigitalOcean provides:
- CPU usage
- Memory usage
- Request count
- Response time (P50, P95, P99)
- Error rate

Access via: Apps → <app-name> → Insights

## Troubleshooting

### Model Loading Timeout

**Problem:** App fails health check, "model not loaded"

**Solution:**
```yaml
# Increase health check initial delay
health_check:
  initial_delay_seconds: 90  # Increase from 60
```

### High Memory Usage

**Problem:** App crashes with OOM errors

**Solution:**
```yaml
# Upgrade instance size
instance_size_slug: basic-s  # 1GB RAM, $12/month
```

### Slow OCR Processing

**Problem:** OCR takes >10 seconds

**Solutions:**
1. Enable GPU mode (see above)
2. Reduce image size before sending
3. Use batch processing for multiple receipts

### Connection Timeout from Odoo

**Problem:** Odoo "OCR service unavailable"

**Solutions:**
```python
# Increase timeout in ocr_service.py
response = requests.post(
    api_url,
    files=files,
    data=data,
    timeout=90  # Increase from 60
)
```

## Cost Breakdown

### Monthly Costs

```
OCR Service (Basic): $5/month
- 512MB RAM
- 1 vCPU
- 10GB disk

Total: $5/month
```

### Cost Optimization

**Free Tier** (DigitalOcean):
- $200 credit for 60 days
- Perfect for testing

**Production** (at scale):
- Process 1000 receipts/month: $5/month (CPU)
- Process 10,000 receipts/month: $12/month (larger CPU)
- Process 100,000 receipts/month: $30-50/month (GPU)

## Security

### API Authentication

Add bearer token authentication:

```python
# app/main.py
from fastapi import Header, HTTPException

async def verify_token(authorization: str = Header(None)):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Unauthorized")

    token = authorization.replace("Bearer ", "")
    # Verify token against database or secret
    if token != os.getenv("OCR_API_KEY"):
        raise HTTPException(status_code=401, detail="Invalid token")

@app.post("/ocr", dependencies=[Depends(verify_token)])
async def process_ocr(...):
    ...
```

### HTTPS Only

DigitalOcean App Platform automatically provides:
- TLS/SSL certificate
- HTTPS enforcement
- Certificate renewal

### Input Validation

```python
# app/main.py
from fastapi import File, UploadFile, HTTPException

async def validate_image(file: UploadFile):
    # Check file type
    if file.content_type not in ["image/jpeg", "image/png", "application/pdf"]:
        raise HTTPException(status_code=400, detail="Invalid file type")

    # Check file size (max 10MB)
    contents = await file.read()
    if len(contents) > 10 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="File too large")

    return contents
```

## Next Steps

1. **Deploy OCR service** to DigitalOcean
2. **Configure Odoo** with service URL
3. **Test integration** with sample receipts
4. **Monitor performance** and optimize as needed
5. **Scale up** if processing >1000 receipts/month

## Support

- **Odoo Module:** See [hr_expense_ocr_audit/README.md](../addons/hr_expense_ocr_audit/README.md)
- **DigitalOcean:** https://docs.digitalocean.com/products/app-platform/
- **PaddleOCR:** https://github.com/PaddlePaddle/PaddleOCR
