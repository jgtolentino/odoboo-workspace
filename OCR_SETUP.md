# Receipt/Invoice OCR Integration - Setup Guide

**Date**: October 23, 2025
**Server**: 188.166.237.231 (ocr-service-droplet, Singapore)
**Domain**: https://insightpulseai.net
**Status**: ✅ **READY FOR DEPLOYMENT**

---

## 📋 Overview

Automated receipt and invoice processing system using PaddleOCR for Odoo 18 hr.expense module.

**Architecture**:
```
Receipt Image → OCR Service (PaddleOCR) → JSON → Odoo hr.expense
                     ↓
            Confidence Score
                     ↓
         ≥85%: Auto-Approve
         <85%: Review Queue
```

**Stack**:
- **OCR Engine**: PaddleOCR PP-OCRv4 (CPU mode)
- **API**: FastAPI on port 8000
- **Preprocessing**: Deskew, denoise, binarization
- **Routing**: Traefik `/api/ocr/*`
- **Odoo Module**: `hr_expense_ocr_audit`

---

## 🚀 Deployment

### 1. Build and Start Services

```bash
ssh root@188.166.237.231
cd /opt/odoobo

# Build OCR service image
docker compose build ocr-service

# Start OCR service
docker compose up -d ocr-service

# Verify OCR service is running
docker compose ps ocr-service
curl -sf http://localhost:8000/health | jq
```

**Expected Output**:
```json
{
  "status": "healthy",
  "service": "paddleocr-receipt-service",
  "version": "1.0.0",
  "timestamp": "2025-10-23T05:00:00"
}
```

### 2. Install Odoo Module

```bash
# Restart Odoo to detect new module
docker compose restart odoo

# Wait for Odoo to start (check logs)
docker compose logs -f odoo
```

**Install via Odoo UI**:
1. Navigate to **Apps** → **Update Apps List**
2. Search for "HR Expense OCR Integration"
3. Click **Install**
4. Refresh browser

**Verify Installation**:
1. Go to **Expenses** menu
2. Should see new submenu: **OCR Processing** → **Review Queue**

### 3. Verify External Access

```bash
# Test OCR service via Traefik
curl -sf https://insightpulseai.net/api/ocr/health | jq

# Expected: Same JSON response as above
```

---

## 🔧 Usage

### Manual OCR Processing (Odoo UI)

1. **Create Expense**: Expenses → My Expenses → Create
2. **Attach Receipt**: Click **Attach** → Upload image (JPEG/PNG)
3. **Process OCR**: Click **Process with OCR** button
4. **Review Results**: Fields auto-populated if confidence ≥85%

### OCR Review Queue

**Path**: Expenses → OCR Processing → Review Queue

**Features**:
- Lists all OCR processing results
- Filter by confidence level
- Filter by review status
- Approve and create expense from review queue

**Low Confidence Items**:
- Highlighted in orange
- Manual review required
- Click **Approve & Create Expense** after verification

### Automatic OCR (Optional)

Enable auto-processing for new expenses:

```bash
# SSH to server
ssh root@188.166.237.231

# Enable auto-OCR
docker compose exec -T db psql -U odoo -d insightpulseai.net -c \
  "INSERT INTO ir_config_parameter (key, value) VALUES ('hr_expense_ocr.auto_process', 'True') ON CONFLICT (key) DO UPDATE SET value = 'True';"
```

Now all new expenses with image attachments will auto-process OCR.

---

## 📡 API Reference

### OCR Service API

**Base URL**: `http://ocr-service:8000` (internal)
**Public URL**: `https://insightpulseai.net/api/ocr` (via Traefik)

#### POST /v1/parse

Process receipt image and extract structured data.

**Request**:
```bash
curl -X POST https://insightpulseai.net/api/ocr/v1/parse \
  -F "file=@receipt.jpg"
```

**Response**:
```json
{
  "success": true,
  "filename": "receipt.jpg",
  "confidence": 0.923,
  "extracted_fields": {
    "merchant": "STARBUCKS",
    "total_amount": 15.75,
    "currency": "USD",
    "date": "10/22/2025",
    "tax_amount": 1.42
  },
  "raw_text": ["STARBUCKS", "10/22/2025", "Total: $15.75"],
  "line_count": 12,
  "needs_review": false,
  "processed_at": "2025-10-23T05:15:00"
}
```

#### GET /health

Health check endpoint for monitoring.

**Response**:
```json
{
  "status": "healthy",
  "service": "paddleocr-receipt-service",
  "version": "1.0.0"
}
```

#### GET /models

List available OCR models.

**Response**:
```json
{
  "models": [
    {
      "name": "PP-OCRv4",
      "language": "en",
      "use_case": "receipts, invoices, documents",
      "gpu": false
    }
  ]
}
```

### Odoo API Endpoints

**Base URL**: `https://insightpulseai.net`

#### POST /api/expense/ocr/upload

Upload receipt for OCR processing (requires Odoo authentication).

**Request**:
```bash
curl -X POST https://insightpulseai.net/api/expense/ocr/upload \
  -H "Cookie: session_id=YOUR_SESSION" \
  -F "file=@receipt.jpg" \
  -F "employee_id=1"
```

**Response**:
```json
{
  "success": true,
  "ocr_id": 5,
  "confidence": 0.923,
  "needs_review": false,
  "extracted_fields": {
    "merchant": "STARBUCKS",
    "total_amount": 15.75,
    "currency": "USD",
    "date": "2025-10-22",
    "tax_amount": 1.42
  },
  "state": "done",
  "expense_id": 42,
  "expense_reference": "EXP/2025/0042"
}
```

#### GET /api/expense/ocr/status/<ocr_id>

Get OCR processing status.

---

## 🔍 Monitoring

### DigitalOcean Monitoring Alerts

Add OCR service health check to DO monitoring:

```bash
export DIGITALOCEAN_ACCESS_TOKEN='dop_v1_...'

doctl monitoring alert create \
  --type v1/insights/droplet/http_check \
  --compare GreaterThan \
  --value 500 \
  --window 5m \
  --entities 525178434 \
  --emails jgtolentino_rn@yahoo.com \
  --description "OCR service HTTP check failed (>500 response code)"
```

### Manual Health Checks

```bash
# Check OCR service
curl -sf https://insightpulseai.net/api/ocr/health || echo "OCR service down"

# Check Docker container
docker compose ps ocr-service

# Check logs
docker compose logs --tail=50 ocr-service
```

### Performance Metrics

**Target SLAs**:
- OCR processing time: <5 seconds per receipt
- Auto-approval rate: ≥90% (confidence ≥85%)
- Service uptime: 99.5%

**Monitor in Odoo**:
- Expenses → OCR Processing → Processing History
- Filter by confidence level
- Track approval rates over time

---

## 🐛 Troubleshooting

### OCR Service Not Responding

```bash
# Check service status
docker compose ps ocr-service

# Restart service
docker compose restart ocr-service

# Check logs
docker compose logs --tail=100 ocr-service

# Verify Traefik routing
curl -v https://insightpulseai.net/api/ocr/health
```

### Low OCR Accuracy

**Possible Causes**:
1. Poor image quality (blurry, dark, tilted)
2. Non-English text
3. Handwritten receipts
4. Damaged or faded receipts

**Solutions**:
1. Re-capture with better lighting
2. Use manual entry for low-quality receipts
3. Adjust preprocessing parameters (advanced)

### "Process with OCR" Button Not Visible

**Check**:
1. Module installed: Apps → HR Expense OCR Integration
2. Image attached to expense record
3. Expense not already OCR processed

### Expenses Not Auto-Creating

**Check**:
1. Confidence score ≥85%
2. Review queue filter
3. Odoo logs for errors

```bash
docker compose logs odoo | grep -i "ocr"
```

---

## 📊 Configuration

### Resource Limits

Current configuration (compose.yaml):

```yaml
ocr-service:
  deploy:
    resources:
      limits:
        cpus: '1.5'
        memory: 2g
      reservations:
        memory: 1g
```

**Adjust if needed**:
- Increase CPU for faster processing
- Increase memory for GPU mode (future)

### Rate Limiting

Current configuration (Traefik):

```yaml
rate-ocr:
  rateLimit:
    average: 10
    burst: 20
```

**Meaning**: 10 requests/second average, 20 burst
**Adjust**: Edit `docker/traefik/dynamic.yml` and restart Traefik

### Auto-Process Threshold

Default: Confidence ≥85% auto-approves

**Change threshold**:

```python
# Edit: addons/custom/hr_expense_ocr_audit/models/expense_ocr.py
# Line: needs_review = result.get('needs_review', False)

# Change to:
needs_review = confidence < 0.90  # 90% threshold
```

---

## 🔄 Maintenance

### Weekly Tasks

```bash
# Review OCR processing stats
docker compose logs ocr-service | grep -E "OCR completed" | tail -50

# Check review queue size
# Odoo UI: Expenses → OCR Processing → Review Queue
```

### Monthly Tasks

```bash
# Review auto-approval rate
# Target: ≥90% of receipts auto-approved

# Archive old OCR records (optional)
# Odoo UI: Expenses → OCR Processing → Processing History → Archive
```

### Updates

```bash
# Update PaddleOCR models
docker compose exec ocr-service pip install --upgrade paddleocr

# Restart service
docker compose restart ocr-service
```

---

## 🚀 Future Enhancements

### GPU Acceleration (Optional)

For high-volume processing (>100 receipts/day):

1. Upgrade droplet to GPU instance
2. Update Dockerfile: `paddlepaddle==2.6.0` → `paddlepaddle-gpu==2.6.0`
3. Enable GPU in `docker/ocr/app.py`: `use_gpu=True`
4. Expected speedup: 3-5x faster

### Mobile App Integration

Flutter mobile app (optional):

1. Install mobile app from repository
2. Configure Odoo URL: `https://insightpulseai.net`
3. Authenticate with Odoo credentials
4. Capture receipts directly from mobile camera
5. Real-time OCR processing and expense creation

See `MOBILE_APP_SETUP.md` (coming soon)

### Supabase Integration (Optional)

Cloud storage for receipts:

1. Create Supabase project
2. Configure storage bucket: `expense-receipts`
3. Add Supabase credentials to `.env.production`
4. Install `supabase_sync` Odoo module
5. Receipts auto-sync to cloud storage

---

## 📞 Support

**OCR Service Issues**: Check `docker compose logs ocr-service`
**Odoo Module Issues**: Check Odoo logs and review queue
**API Integration**: See API Reference section above

**Contact**: Jake Tolentino (jgtolentino_rn@yahoo.com)
**Repository**: https://github.com/jgtolentino/odoboo-workspace

---

*Last Updated: October 23, 2025 05:30 UTC*
*Status: Ready for Production*
