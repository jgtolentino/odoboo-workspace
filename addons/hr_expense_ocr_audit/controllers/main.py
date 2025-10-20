# -*- coding: utf-8 -*-
import json
from odoo import http
from odoo.http import request


class HrExpenseOCRAuditController(http.Controller):
    @http.route(
        "/hr_expense/ocr/process/<int:expense_id>",
        type="json",
        auth="user",
        methods=["POST"],
    )
    def process_ocr(self, expense_id, **kwargs):
        """Trigger OCR processing for expense via JSON-RPC."""
        expense = request.env["hr.expense"].browse(expense_id)
        if not expense.exists():
            return {"error": "Expense not found"}

        try:
            expense.action_process_ocr()
            return {
                "success": True,
                "ocr_confidence": expense.ocr_confidence,
                "ocr_status": expense.ocr_status,
            }
        except Exception as e:
            return {"error": str(e)}

    @http.route(
        "/hr_expense/ocr/compare/<int:expense_id>",
        type="json",
        auth="user",
        methods=["POST"],
    )
    def compare_documents(self, expense_id, **kwargs):
        """Trigger document comparison for expense via JSON-RPC."""
        expense = request.env["hr.expense"].browse(expense_id)
        if not expense.exists():
            return {"error": "Expense not found"}

        try:
            expense.action_compare_documents()
            return {
                "success": True,
                "visual_similarity": expense.ocr_diff_score,
                "has_changes": expense.has_visual_changes,
                "anomaly_detected": expense.anomaly_detected,
            }
        except Exception as e:
            return {"error": str(e)}

    @http.route(
        "/hr_expense/ocr/audit_logs/<int:expense_id>",
        type="json",
        auth="user",
        methods=["GET"],
    )
    def get_audit_logs(self, expense_id, **kwargs):
        """Get audit logs for expense."""
        expense = request.env["hr.expense"].browse(expense_id)
        if not expense.exists():
            return {"error": "Expense not found"}

        logs = expense.ocr_audit_log_ids.read(
            [
                "action",
                "ocr_confidence",
                "visual_similarity",
                "create_date",
                "user_id",
                "notes",
            ]
        )

        return {"success": True, "logs": logs}
