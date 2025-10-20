# -*- coding: utf-8 -*-
import json
import logging
from odoo import models, fields, api, _
from odoo.exceptions import UserError, ValidationError

_logger = logging.getLogger(__name__)


class HrExpense(models.Model):
    _inherit = "hr.expense"

    # OCR Fields
    ocr_payload = fields.Text(
        string="OCR Extracted Data",
        help="JSON payload from PaddleOCR-VL extraction",
        copy=False,
    )
    ocr_confidence = fields.Float(
        string="OCR Confidence Score",
        digits=(5, 2),
        help="Average confidence score from OCR extraction (0-100)",
        copy=False,
    )
    ocr_status = fields.Selection(
        [
            ("pending", "Pending OCR"),
            ("processing", "Processing"),
            ("completed", "Completed"),
            ("failed", "Failed"),
            ("manual_review", "Manual Review Required"),
        ],
        string="OCR Status",
        default="pending",
        tracking=True,
        copy=False,
    )

    # Visual Diff Fields
    ocr_diff_json = fields.Text(
        string="OCR Diff Result",
        help="JSON diff between original and current OCR extraction",
        copy=False,
    )
    ocr_diff_score = fields.Float(
        string="Visual Similarity Score",
        digits=(5, 4),
        help="SSIM/LPIPS score for visual comparison (0-1, higher is more similar)",
        copy=False,
    )
    has_visual_changes = fields.Boolean(
        string="Visual Changes Detected",
        compute="_compute_has_visual_changes",
        store=True,
        help="True if significant visual changes detected",
    )

    # Audit Trail
    ocr_audit_log_ids = fields.One2many(
        "hr.expense.ocr.audit.log",
        "expense_id",
        string="OCR Audit Logs",
        copy=False,
    )
    ocr_audit_count = fields.Integer(
        string="Audit Log Count",
        compute="_compute_ocr_audit_count",
    )

    # Anomaly Detection
    anomaly_detected = fields.Boolean(
        string="Anomaly Detected",
        default=False,
        tracking=True,
        help="Automated anomaly detection flagged this expense",
    )
    anomaly_reason = fields.Text(
        string="Anomaly Details",
        help="Explanation of detected anomalies",
    )
    requires_manager_approval = fields.Boolean(
        string="Requires Manager Approval",
        default=False,
        help="Expense flagged for additional approval",
    )

    # Version Tracking
    document_version = fields.Integer(
        string="Document Version",
        default=1,
        copy=False,
        help="Increments each time document is resubmitted with changes",
    )
    original_ocr_payload = fields.Text(
        string="Original OCR Data",
        help="First OCR extraction for comparison",
        copy=False,
    )

    @api.depends("ocr_diff_score", "ocr_diff_json")
    def _compute_has_visual_changes(self):
        """Detect significant visual changes based on diff score and JSON diff."""
        threshold = float(
            self.env["ir.config_parameter"]
            .sudo()
            .get_param("hr_expense_ocr_audit.visual_diff_threshold", default="0.95")
        )

        for expense in self:
            if expense.ocr_diff_score and expense.ocr_diff_score < threshold:
                expense.has_visual_changes = True
            elif expense.ocr_diff_json:
                try:
                    diff = json.loads(expense.ocr_diff_json)
                    # Check if there are meaningful changes in the diff
                    expense.has_visual_changes = bool(diff)
                except (json.JSONDecodeError, TypeError):
                    expense.has_visual_changes = False
            else:
                expense.has_visual_changes = False

    @api.depends("ocr_audit_log_ids")
    def _compute_ocr_audit_count(self):
        """Count OCR audit log entries."""
        for expense in self:
            expense.ocr_audit_count = len(expense.ocr_audit_log_ids)

    def action_process_ocr(self):
        """Trigger OCR processing for expense document."""
        self.ensure_one()

        if not self.attachment_ids:
            raise UserError(_("No document attached to process."))

        if self.ocr_status == "processing":
            raise UserError(_("OCR processing already in progress."))

        # Update status
        self.write({"ocr_status": "processing"})

        # Call OCR service
        try:
            ocr_service = self.env["hr.expense.ocr.service"]
            result = ocr_service.process_expense_document(self)

            # Update expense with OCR results
            self._update_from_ocr_result(result)

            # Create audit log
            self._create_audit_log("ocr_processed", result)

            self.message_post(
                body=_("OCR processing completed. Confidence: %.2f%%")
                % self.ocr_confidence,
                subject=_("OCR Processing"),
            )

        except Exception as e:
            _logger.error(f"OCR processing failed for expense {self.id}: {str(e)}")
            self.write(
                {
                    "ocr_status": "failed",
                    "anomaly_detected": True,
                    "anomaly_reason": f"OCR processing error: {str(e)}",
                }
            )
            self._create_audit_log("ocr_failed", {"error": str(e)})
            raise UserError(_("OCR processing failed: %s") % str(e))

        return True

    def action_compare_documents(self):
        """Compare current document with original version."""
        self.ensure_one()

        if not self.original_ocr_payload:
            raise UserError(
                _("No original OCR data available for comparison. Process OCR first.")
            )

        if not self.attachment_ids:
            raise UserError(_("No current document attached to compare."))

        try:
            ocr_service = self.env["hr.expense.ocr.service"]
            comparison = ocr_service.compare_expense_documents(self)

            # Update expense with comparison results
            self.write(
                {
                    "ocr_diff_json": json.dumps(comparison.get("json_diff", {})),
                    "ocr_diff_score": comparison.get("visual_similarity", 1.0),
                    "document_version": self.document_version + 1,
                }
            )

            # Check for anomalies
            self._detect_anomalies(comparison)

            # Create audit log
            self._create_audit_log("document_compared", comparison)

            self.message_post(
                body=_(
                    "Document comparison completed. Similarity: %.2f%%. Changes detected: %s"
                )
                % (self.ocr_diff_score * 100, "Yes" if self.has_visual_changes else "No"),
                subject=_("Document Comparison"),
            )

        except Exception as e:
            _logger.error(f"Document comparison failed for expense {self.id}: {str(e)}")
            raise UserError(_("Document comparison failed: %s") % str(e))

        return True

    def _update_from_ocr_result(self, ocr_result):
        """Update expense fields from OCR result."""
        ocr_data = ocr_result.get("ocr_data", {})
        confidence = ocr_result.get("confidence", 0.0)

        # Store OCR payload
        payload = json.dumps(ocr_data)

        # Store original if first extraction
        original_payload = self.original_ocr_payload or payload

        vals = {
            "ocr_payload": payload,
            "ocr_confidence": confidence * 100,  # Convert to percentage
            "ocr_status": "completed"
            if confidence >= 0.6
            else "manual_review",  # 60% threshold
            "original_ocr_payload": original_payload,
        }

        # Auto-fill fields if confidence is high
        if confidence >= 0.8:  # 80% confidence for auto-fill
            extracted = ocr_data.get("extracted_fields", {})

            if extracted.get("total_amount"):
                vals["total_amount"] = float(extracted["total_amount"])

            if extracted.get("date"):
                vals["date"] = extracted["date"]

            if extracted.get("description"):
                vals["name"] = extracted["description"]

        self.write(vals)

    def _detect_anomalies(self, comparison):
        """Detect anomalies in document comparison."""
        anomalies = []

        # Check visual similarity
        visual_threshold = float(
            self.env["ir.config_parameter"]
            .sudo()
            .get_param("hr_expense_ocr_audit.visual_diff_threshold", default="0.95")
        )

        if comparison.get("visual_similarity", 1.0) < visual_threshold:
            anomalies.append(
                f"Visual similarity below threshold: {comparison['visual_similarity']:.2%}"
            )

        # Check JSON diff for significant changes
        json_diff = comparison.get("json_diff", {})
        if json_diff:
            # Check for amount changes
            if "total_amount" in json_diff:
                anomalies.append(
                    f"Amount changed: {json_diff['total_amount'].get('old')} → {json_diff['total_amount'].get('new')}"
                )

            # Check for date changes
            if "date" in json_diff:
                anomalies.append(
                    f"Date changed: {json_diff['date'].get('old')} → {json_diff['date'].get('new')}"
                )

        # Check OCR confidence drop
        if self.ocr_confidence < 60:
            anomalies.append(f"Low OCR confidence: {self.ocr_confidence:.2f}%")

        # Update anomaly status
        if anomalies:
            self.write(
                {
                    "anomaly_detected": True,
                    "anomaly_reason": "\n".join(anomalies),
                    "requires_manager_approval": True,
                }
            )

    def _create_audit_log(self, action, result_data):
        """Create audit log entry."""
        self.env["hr.expense.ocr.audit.log"].create(
            {
                "expense_id": self.id,
                "action": action,
                "ocr_confidence": result_data.get("confidence", 0.0) * 100,
                "visual_similarity": result_data.get("visual_similarity"),
                "result_data": json.dumps(result_data),
                "user_id": self.env.user.id,
            }
        )

    def action_view_audit_logs(self):
        """Open audit log view for this expense."""
        self.ensure_one()
        return {
            "name": _("OCR Audit Logs"),
            "type": "ir.actions.act_window",
            "res_model": "hr.expense.ocr.audit.log",
            "view_mode": "tree,form",
            "domain": [("expense_id", "=", self.id)],
            "context": {"default_expense_id": self.id},
        }

    @api.constrains("total_amount")
    def _check_amount_vs_ocr(self):
        """Validate manual amount changes against OCR extraction."""
        for expense in self:
            if expense.ocr_payload and expense.total_amount:
                try:
                    ocr_data = json.loads(expense.ocr_payload)
                    ocr_amount = float(
                        ocr_data.get("extracted_fields", {}).get("total_amount", 0)
                    )

                    if ocr_amount and abs(expense.total_amount - ocr_amount) > 1.0:
                        # Allow difference up to 1.0 currency unit
                        _logger.warning(
                            f"Amount mismatch for expense {expense.id}: "
                            f"Manual {expense.total_amount} vs OCR {ocr_amount}"
                        )
                        expense.write(
                            {
                                "anomaly_detected": True,
                                "anomaly_reason": f"Manual amount ({expense.total_amount}) differs from OCR extraction ({ocr_amount})",
                            }
                        )
                except (json.JSONDecodeError, ValueError, TypeError):
                    pass

    def write(self, vals):
        """Override write to detect document changes."""
        # Track attachment changes
        if "attachment_ids" in vals and self.original_ocr_payload:
            # Document has been changed, trigger comparison
            res = super(HrExpense, self).write(vals)
            for expense in self:
                if expense.attachment_ids:
                    expense.action_compare_documents()
            return res

        return super(HrExpense, self).write(vals)
