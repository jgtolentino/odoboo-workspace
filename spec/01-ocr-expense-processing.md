# OCR Expense Processing Specification

## User Story

**As a** finance team member or employee submitting expenses
**I want to** upload receipt images and have expense details automatically extracted
**So that** I save time on manual data entry and reduce errors in expense reports

## Success Criteria

### For Employees

- **Upload Receipt**: Snap photo on mobile or upload file → expense fields auto-filled in <30 seconds
- **95%+ Accuracy**: Vendor name, amount, date, tax extracted correctly (verified by user review)
- **Multi-Format Support**: Accept JPEG, PNG, PDF receipts from any device
- **Mobile-First**: Offline photo capture → sync and process when connected
- **Auto-Approval**: If confidence ≥85% and within policy, auto-approve (no manual review)

### For Finance Team

- **Audit Trail**: Every OCR extraction stored with confidence scores and original image
- **Change Detection**: If receipt is replaced, visual + JSON diff highlights changes
- **Batch Processing**: Upload 50+ receipts → all processed in parallel
- **Concur Export**: OCR data maps to Concur fields for seamless export
- **Dashboard**: See OCR processing status, confidence distribution, error rates

## User Journeys

### Journey 1: Employee Submits Expense (Mobile)

**Context**: Employee finishes business lunch, needs to submit expense before leaving restaurant

**Steps**:
1. Open mobile app → Navigate to Expenses
2. Tap "New Expense" → Tap camera icon
3. Snap photo of receipt
4. App auto-extracts: Vendor ("Olive Garden"), Amount ($45.80), Date (today), Tax ($4.12)
5. Employee reviews fields → Adjusts category ("Client Meals")
6. Tap "Submit"

**Expected Outcome**:
- ✅ Expense created in <10 seconds (including photo snap)
- ✅ OCR accuracy ≥95% (vendor, amount, date correct)
- ✅ Receipt stored in both mobile SQLite (offline) and Supabase (online)
- ✅ If policy-compliant + confidence ≥85%, auto-approved (no manager review)

**Failure Scenarios**:
- ❌ Blurry photo → OCR confidence <60% → Prompt user to retake
- ❌ Receipt in foreign language → OCR extracts amount/date only → User fills vendor name
- ❌ Receipt damaged → OCR partial extraction → User completes missing fields

### Journey 2: Finance Admin Reviews Flagged Expense

**Context**: Finance admin sees flagged expense (original receipt replaced by employee)

**Steps**:
1. Open Expenses Dashboard → Filter "Flagged for Review"
2. Click expense #1234 → See alert: "Receipt changed after submission"
3. View side-by-side comparison:
   - Original receipt: $125.50
   - New receipt: $225.50
   - Visual similarity: 65% (significant differences)
   - JSON diff: Amount changed from $125.50 to $225.50
4. Contact employee for clarification
5. Either approve with note or reject

**Expected Outcome**:
- ✅ Visual diff highlights changed regions in red
- ✅ JSON diff shows field-by-field changes with old/new values
- ✅ Full audit trail: timestamps, user IDs, confidence scores
- ✅ Decision logged (approved/rejected + reason)

**Failure Scenarios**:
- ❌ Visual diff fails (images too different) → Fall back to JSON diff only
- ❌ OCR confidence drops below 60% on new receipt → Manual review required

### Journey 3: Finance Team Processes Monthly Batch

**Context**: End of month, 300 pending expense receipts need processing

**Steps**:
1. Finance admin uploads ZIP file with 300 receipt images
2. System queues all 300 for batch OCR processing
3. Dashboard shows progress: "Processing 87/300 (29%)"
4. After 15 minutes, all 300 processed
5. Dashboard shows:
   - 255 auto-approved (≥85% confidence)
   - 32 flagged for review (<85% confidence)
   - 13 failed (invalid file format)
6. Admin reviews 32 flagged expenses
7. Export all 287 valid expenses to Concur CSV

**Expected Outcome**:
- ✅ 300 receipts processed in ≤30 minutes (P95 <30s per receipt)
- ✅ 85% auto-approval rate (255/300)
- ✅ Zero data loss (all 300 images and OCR results stored)
- ✅ Concur export matches Concur field mapping spec

**Failure Scenarios**:
- ❌ Batch processing timeout → Partial results saved → Resume from last checkpoint
- ❌ Network failure mid-upload → ZIP saved locally → Retry when connection restored

## Experience Principles

### Speed

- **Mobile Photo Snap**: Camera ready in <1 second
- **OCR Processing**: P95 <30 seconds (receipt upload → fields filled)
- **Batch Processing**: 50 receipts in ≤5 minutes (parallel processing)
- **Dashboard Load**: TTI <2.5 seconds for expense list view

### Accuracy

- **Field Extraction**: ≥95% accuracy on vendor, amount, date (validated on 1000+ receipts)
- **Confidence Scoring**: 0.0-1.0 scale, block auto-approval if <0.85
- **Failure Recovery**: If OCR fails, user can manually enter fields
- **Multi-Language**: English (primary), Spanish, French, Japanese, Chinese

### Trust

- **Audit Trail**: Every OCR extraction logged (who, when, confidence, result)
- **Change Detection**: Visual + JSON diff if receipt replaced after submission
- **Explainability**: Show confidence score + extracted regions on hover
- **Human Override**: User can always correct OCR-extracted fields

### Mobile-First

- **Offline Drafts**: Snap photo → save locally → sync when online
- **Native Camera**: Use device camera API (not web upload)
- **Touch-Optimized**: 44px minimum tap targets, swipe gestures
- **Bandwidth Aware**: Compress images before upload (max 2MB)

## Non-Goals (What We're NOT Building)

- ❌ **Custom OCR Model Training** - Use PaddleOCR-VL pre-trained model
- ❌ **Real-Time Video OCR** - Batch/single-image processing only
- ❌ **Handwritten Receipt Support** - Typed/printed text only (may add later)
- ❌ **Receipt Fraud Detection** - Change detection only, not ML-based fraud scoring
- ❌ **Multi-Currency Auto-Conversion** - Extract currency symbol, user converts

## Success Metrics

### Performance

- **OCR Latency**: P95 <30s (receipt upload → fields filled)
- **Batch Throughput**: ≥100 receipts/hour (single instance)
- **Auto-Approval Rate**: ≥85% (confidence ≥0.85)
- **Accuracy**: ≥95% on vendor, amount, date (manual validation sample)

### User Experience

- **Mobile Photo Snap**: ≤10 seconds (camera open → expense created)
- **Error Rate**: <5% of OCR extractions fail (confidence <0.60)
- **User Corrections**: <20% of auto-filled fields manually corrected
- **Time Savings**: 70% reduction in manual data entry time (vs. typing all fields)

### Reliability

- **Uptime**: 99.9% availability (8.7 hours downtime/year)
- **Data Loss**: Zero receipt images or OCR results lost
- **Failure Recovery**: If OCR fails, user can still create expense manually
- **Audit Trail**: 100% coverage (every OCR extraction logged)

## Roadmap Milestones

### P0 (MVP - Weeks 1-4)

- ✅ Single receipt OCR (vendor, amount, date, tax)
- ✅ Mobile photo upload with offline draft
- ✅ Confidence scoring and auto-approval (≥85%)
- ✅ Basic audit trail (who, when, result)
- ✅ DigitalOcean deployment (CPU mode)

### P1 (v1.0 - Weeks 5-8)

- Change detection (visual + JSON diff)
- Batch processing (50+ receipts)
- OCR dashboard with metrics
- Concur export integration
- Multi-language support (ES, FR, JA, ZH)

### P2 (v2.0 - Weeks 9-12)

- GPU acceleration (10x faster processing)
- Advanced analytics (fraud risk scoring)
- Handwritten receipt support (experimental)
- Vendor rate card auto-matching
- AI-powered category suggestions

## Open Questions

1. **Handwritten Receipt Support**: Should we support handwritten receipts in P1 or P2?
2. **Multi-Currency Conversion**: Should OCR service auto-convert currencies or leave to user?
3. **Fraud Detection**: Do we need ML-based fraud scoring or is change detection sufficient?
4. **Mobile Offline Mode**: How long should we cache receipts locally before requiring sync?

## References

- [Technical Architecture](../plan/architecture.md) - OCR microservice architecture
- [Deployment Standards](../plan/deployment.md) - DigitalOcean deployment procedures
- [Technology Stack](../plan/stack.md) - PaddleOCR-VL + FastAPI rationale
