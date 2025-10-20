# HR Expense OCR Audit

**Version:** 18.0.1.0.0
**Category:** Human Resources/Expenses
**License:** AGPL-3

Document-aware visual diff and OCR pipeline for Odoo expense management with PaddleOCR-VL integration.

## Features

### 🔍 OCR Extraction
- **PaddleOCR-VL Integration**: Vision-language model for accurate receipt/invoice text extraction
- **Structured Output**: JSON-formatted extraction with confidence scores
- **Auto-Fill**: Automatically populate expense fields when confidence ≥80%
- **Field Extraction**: Total amount, date, vendor, description, tax, currency, payment method

### 📊 Visual Diff
- **LPIPS/SSIM Comparison**: Perceptual visual similarity scoring
- **JSON Diff**: Structured data change detection with jsondiffpatch
- **Version Tracking**: Document version history with incremental versioning
- **Anomaly Detection**: Automated flagging of suspicious changes

### 🛡️ Audit Trail
- **Complete Logging**: All OCR and comparison operations logged
- **User Tracking**: Who processed or compared documents
- **Result Storage**: Full OCR and diff results stored for compliance
- **Historical Analysis**: Trend analysis and pattern detection

### 🚨 Anomaly Detection
- **Visual Similarity Threshold**: Flag documents with similarity <95%
- **Amount Validation**: Detect manual amount changes vs OCR extraction
- **Date Changes**: Track and alert on date modifications
- **Low Confidence**: Flag OCR results <60% confidence
- **Manager Approval**: Automatically require approval for flagged expenses

## Installation

### 1. Install Module Dependencies

```bash
pip install requests Pillow
```

### 2. Install Odoo Module

```bash
# Copy module to addons directory
cp -r hr_expense_ocr_audit /path/to/odoo/addons/

# Update apps list in Odoo
# Settings → Apps → Update Apps List

# Install module
# Apps → Search "HR Expense OCR Audit" → Install
```

### 3. Configure OCR Service

```bash
# Settings → Technical → System Parameters

# Add parameters:
hr_expense_ocr_audit.ocr_api_url = http://localhost:8000/ocr
hr_expense_ocr_audit.ocr_api_key = your-api-key-here
hr_expense_ocr_audit.visual_diff_threshold = 0.95
```

## OCR Service Deployment

### FastAPI Microservice

The module requires a separate FastAPI service running PaddleOCR-VL. See deployment guide below.

#### Docker Deployment (DigitalOcean App Platform)

```yaml
# infra/do/ocr-service.yaml
name: ocr-service
region: sgp
services:
  - name: ocr-api
    source_dir: services/ocr
    dockerfile_path: Dockerfile
    instance_size_slug: basic-xs
    instance_count: 1
    http_port: 8000
    routes:
      - path: /
    envs:
      - key: MODEL_NAME
        value: PaddleOCR-VL-900M
      - key: MIN_CONFIDENCE
        value: "0.60"
      - key: GPU_ENABLED
        value: "false"
```

#### Local Development

```bash
# Clone OCR service
git clone https://github.com/your-org/paddleocr-vl-service.git
cd paddleocr-vl-service

# Install dependencies
pip install -r requirements.txt

# Run service
uvicorn main:app --host 0.0.0.0 --port 8000
```

## Usage

### 1. Process OCR for Expense

```python
# Python API
expense = env['hr.expense'].browse(expense_id)
expense.action_process_ocr()

# JSON-RPC
POST /hr_expense/ocr/process/<expense_id>
```

**Workflow:**
1. Upload receipt/invoice to expense
2. Click "Process OCR" button
3. System sends image to OCR service
4. OCR extracts fields and returns JSON
5. Expense auto-fills if confidence ≥80%
6. Audit log created

### 2. Compare Documents

```python
# Python API
expense.action_compare_documents()

# JSON-RPC
POST /hr_expense/ocr/compare/<expense_id>
```

**Workflow:**
1. User modifies expense document
2. Click "Compare Documents" button
3. System compares with original OCR extraction
4. Visual diff (SSIM/LPIPS) calculated
5. JSON diff highlights field changes
6. Anomalies flagged if changes significant

### 3. View Audit Logs

```python
# Open audit logs for expense
expense.action_view_audit_logs()

# Menu: Expenses → Reporting → OCR Audit Logs
```

### 4. Automated Processing

```xml
<!-- Enable auto-processing cron job -->
Settings → Technical → Scheduled Actions → Auto-Process Pending OCR Requests
Set Active: True
```

## API Reference

### Models

#### `hr.expense` (Extended)

**New Fields:**
- `ocr_payload` (Text): JSON OCR extraction result
- `ocr_confidence` (Float): Average confidence score (0-100)
- `ocr_status` (Selection): pending | processing | completed | failed | manual_review
- `ocr_diff_json` (Text): JSON diff between versions
- `ocr_diff_score` (Float): Visual similarity score (0-1)
- `has_visual_changes` (Boolean): Significant changes detected
- `anomaly_detected` (Boolean): Anomaly flagged
- `anomaly_reason` (Text): Explanation of anomaly
- `document_version` (Integer): Version number
- `original_ocr_payload` (Text): First OCR extraction

**Methods:**
- `action_process_ocr()`: Trigger OCR processing
- `action_compare_documents()`: Compare with original
- `action_view_audit_logs()`: Open audit log view

#### `hr.expense.ocr.audit.log`

**Fields:**
- `expense_id` (Many2one): Related expense
- `action` (Selection): ocr_processed | document_compared | ocr_failed | manual_review | anomaly_detected
- `ocr_confidence` (Float): Confidence at time of action
- `visual_similarity` (Float): SSIM score if comparison performed
- `result_data` (Text): JSON result payload
- `user_id` (Many2one): User who triggered action

### Services

#### `hr.expense.ocr.service`

**Methods:**
- `process_expense_document(expense)`: Call OCR API and return structured result
- `compare_expense_documents(expense)`: Call comparison API and return diff result

## Configuration

### System Parameters

```python
# OCR Service
hr_expense_ocr_audit.ocr_api_url = "http://localhost:8000/ocr"
hr_expense_ocr_audit.ocr_api_key = "optional-bearer-token"

# Thresholds
hr_expense_ocr_audit.visual_diff_threshold = 0.95  # 95% similarity required
hr_expense_ocr_audit.confidence_threshold = 0.60   # 60% min confidence
hr_expense_ocr_audit.auto_fill_threshold = 0.80    # 80% for auto-fill
```

### Scheduled Actions

```xml
<!-- Auto-process pending OCR requests every 15 minutes -->
<record id="ir_cron_auto_process_ocr" model="ir.cron">
    <field name="name">Auto-Process Pending OCR Requests</field>
    <field name="interval_number">15</field>
    <field name="interval_type">minutes</field>
    <field name="active" eval="True"/>
</record>
```

## OCR Service API Specification

### POST /ocr

**Request:**
```bash
curl -X POST http://localhost:8000/ocr \
  -H "Authorization: Bearer <api-key>" \
  -F "file=@receipt.jpg" \
  -F "expense_id=123"
```

**Response:**
```json
{
  "confidence": 0.92,
  "extracted_fields": {
    "total_amount": 125.50,
    "date": "2025-10-20",
    "vendor": "Starbucks Coffee",
    "description": "Business meeting - coffee",
    "tax_amount": 12.55,
    "currency": "USD",
    "payment_method": "Credit Card"
  },
  "text_regions": [...],
  "layout_analysis": {...},
  "raw_text": "..."
}
```

### POST /compare

**Request:**
```bash
curl -X POST http://localhost:8000/compare \
  -H "Authorization: Bearer <api-key>" \
  -F "current_file=@receipt_v2.jpg" \
  -F "original_ocr_data=<json-string>"
```

**Response:**
```json
{
  "visual_similarity": 0.88,
  "changes_detected": true,
  "json_diff": {
    "total_amount": {
      "old": 125.50,
      "new": 225.50
    },
    "date": {
      "old": "2025-10-20",
      "new": "2025-10-21"
    }
  }
}
```

## Security

### Access Rights

- **User**: Read/Write own expenses and audit logs
- **Manager**: Full access including delete audit logs

### RLS Policies

```sql
-- Employees can only view their own expense audit logs
CREATE POLICY user_own_audit_logs ON hr_expense_ocr_audit_log
  FOR SELECT USING (
    expense_id IN (
      SELECT id FROM hr_expense WHERE employee_id = current_employee_id()
    )
  );
```

## Performance

### Optimization

- **Caching**: OCR results cached in expense record
- **Batch Processing**: Cron job processes up to 50 expenses per run
- **Async Operations**: OCR calls with 60s timeout
- **Comparison Timeout**: 90s for visual diff operations

### Resource Requirements

- **CPU**: 2 vCPU recommended for OCR service
- **Memory**: 4GB RAM minimum
- **GPU**: Optional (10x faster inference)
- **Storage**: ~1MB per expense for OCR data

## Troubleshooting

### OCR Processing Failed

**Error:** `OCR service unavailable`

**Solution:**
1. Check OCR service is running: `curl http://localhost:8000/health`
2. Verify `ocr_api_url` system parameter
3. Check network connectivity
4. Review OCR service logs

### Low Confidence Scores

**Error:** OCR confidence <60%

**Solution:**
1. Check image quality (resolution ≥1024px recommended)
2. Ensure receipt/invoice is clear and readable
3. Verify OCR model is loaded correctly
4. Try manual review workflow

### Visual Diff Anomalies

**Error:** Unexpected anomaly detected

**Solution:**
1. Review audit logs for details
2. Check visual_diff_threshold parameter (default 0.95)
3. Manually compare documents in expense form
4. Adjust threshold if false positives occur

## Development

### Testing

```bash
# Run tests
python -m pytest addons/hr_expense_ocr_audit/tests/

# Test OCR service integration
python -m pytest addons/hr_expense_ocr_audit/tests/test_ocr_service.py
```

### Contributing

This module is OCA-ready and follows OCA guidelines:
- AGPL-3 license
- OCA manifest format
- Proper security definitions
- Complete documentation

## Roadmap

- [ ] Multi-language OCR support
- [ ] Custom field extraction templates
- [ ] ML-based anomaly detection
- [ ] Integration with approval workflows
- [ ] Batch OCR processing UI
- [ ] Export audit reports to PDF/Excel
- [ ] WebSocket real-time updates

## Credits

**Authors:**
- Your Name
- Odoo Community Association (OCA)

**Maintainer:**
- OCA: https://github.com/OCA/hr

## License

AGPL-3

This module is licensed under AGPL-3. See LICENSE file for full text.
