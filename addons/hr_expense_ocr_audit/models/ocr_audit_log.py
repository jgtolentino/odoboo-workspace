# -*- coding: utf-8 -*-
from odoo import models, fields, api


class HrExpenseOCRAuditLog(models.Model):
    _name = "hr.expense.ocr.audit.log"
    _description = "HR Expense OCR Audit Log"
    _order = "create_date desc"
    _rec_name = "expense_id"

    expense_id = fields.Many2one(
        "hr.expense",
        string="Expense",
        required=True,
        ondelete="cascade",
        index=True,
    )
    action = fields.Selection(
        [
            ("ocr_processed", "OCR Processed"),
            ("document_compared", "Document Compared"),
            ("ocr_failed", "OCR Failed"),
            ("manual_review", "Manual Review"),
            ("anomaly_detected", "Anomaly Detected"),
        ],
        string="Action",
        required=True,
    )
    ocr_confidence = fields.Float(
        string="OCR Confidence",
        digits=(5, 2),
        help="OCR confidence score at time of action",
    )
    visual_similarity = fields.Float(
        string="Visual Similarity",
        digits=(5, 4),
        help="SSIM/LPIPS score if comparison was performed",
    )
    result_data = fields.Text(
        string="Result Data",
        help="JSON payload of OCR or comparison result",
    )
    user_id = fields.Many2one(
        "res.users",
        string="User",
        default=lambda self: self.env.user,
        required=True,
    )
    notes = fields.Text(string="Notes")

    # Related fields for easy access
    employee_id = fields.Many2one(
        related="expense_id.employee_id",
        string="Employee",
        store=True,
        readonly=True,
    )
    expense_date = fields.Date(
        related="expense_id.date",
        string="Expense Date",
        store=True,
        readonly=True,
    )
    expense_amount = fields.Monetary(
        related="expense_id.total_amount",
        string="Amount",
        store=True,
        readonly=True,
    )
    currency_id = fields.Many2one(
        related="expense_id.currency_id",
        string="Currency",
        readonly=True,
    )
