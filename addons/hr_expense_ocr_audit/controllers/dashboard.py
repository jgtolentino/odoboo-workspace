# -*- coding: utf-8 -*-
import json
from datetime import datetime, timedelta
from odoo import http
from odoo.http import request


class HrExpenseOCRAuditDashboard(http.Controller):
    @http.route("/hr_expense/ocr/dashboard", type="http", auth="user", website=False)
    def ocr_dashboard(self, **kwargs):
        """Main OCR Audit Dashboard page."""
        # Get dashboard metrics
        metrics = self._get_dashboard_metrics()

        return request.render(
            "hr_expense_ocr_audit.ocr_dashboard_template", {"metrics": metrics}
        )

    @http.route(
        "/hr_expense/ocr/dashboard/data",
        type="json",
        auth="user",
        methods=["POST"],
    )
    def dashboard_data(self, **kwargs):
        """JSON endpoint for dashboard metrics (AJAX refresh)."""
        return self._get_dashboard_metrics()

    def _get_dashboard_metrics(self):
        """Calculate dashboard KPIs."""
        Expense = request.env["hr.expense"]
        AuditLog = request.env["hr.expense.ocr.audit.log"]

        today = datetime.now().date()
        week_ago = today - timedelta(days=7)

        # Total metrics
        total_expenses = Expense.search_count([])
        total_with_ocr = Expense.search_count([("ocr_payload", "!=", False)])

        # Today's metrics
        today_processed = Expense.search_count(
            [
                ("ocr_status", "=", "completed"),
                ("create_date", ">=", datetime.combine(today, datetime.min.time())),
            ]
        )

        # Low confidence flags
        low_confidence_count = Expense.search_count(
            [("ocr_confidence", "<", 60), ("ocr_payload", "!=", False)]
        )

        # Anomaly detection
        anomaly_count = Expense.search_count([("anomaly_detected", "=", True)])

        # Visual changes detected
        visual_changes_count = Expense.search_count([("has_visual_changes", "=", True)])

        # Average OCR confidence
        expenses_with_ocr = Expense.search([("ocr_payload", "!=", False)])
        avg_confidence = (
            sum(exp.ocr_confidence for exp in expenses_with_ocr) / len(expenses_with_ocr)
            if expenses_with_ocr
            else 0
        )

        # Average visual similarity
        expenses_with_diff = Expense.search([("ocr_diff_score", ">", 0)])
        avg_similarity = (
            sum(exp.ocr_diff_score for exp in expenses_with_diff) / len(expenses_with_diff)
            if expenses_with_diff
            else 0
        )

        # Top vendors by volume
        vendor_query = """
            SELECT
                COALESCE(json_extract_path_text(ocr_payload::json, 'extracted_fields', 'vendor'), 'Unknown') as vendor,
                COUNT(*) as count
            FROM hr_expense
            WHERE ocr_payload IS NOT NULL
            GROUP BY vendor
            ORDER BY count DESC
            LIMIT 5
        """
        request.env.cr.execute(vendor_query)
        top_vendors = [
            {"vendor": row[0], "count": row[1]} for row in request.env.cr.fetchall()
        ]

        # OCR status distribution
        status_distribution = []
        for status in ["pending", "processing", "completed", "failed", "manual_review"]:
            count = Expense.search_count([("ocr_status", "=", status)])
            if count > 0:
                status_distribution.append({"status": status, "count": count})

        # Recent audit logs
        recent_logs = AuditLog.search([], order="create_date desc", limit=10)
        recent_activity = [
            {
                "id": log.id,
                "expense_name": log.expense_id.name or f"Expense #{log.expense_id.id}",
                "action": log.action,
                "confidence": log.ocr_confidence,
                "date": log.create_date.strftime("%Y-%m-%d %H:%M:%S"),
                "user": log.user_id.name,
            }
            for log in recent_logs
        ]

        # Weekly trend
        weekly_trend = []
        for i in range(7):
            day = today - timedelta(days=i)
            day_start = datetime.combine(day, datetime.min.time())
            day_end = datetime.combine(day, datetime.max.time())

            day_count = Expense.search_count(
                [
                    ("ocr_status", "=", "completed"),
                    ("create_date", ">=", day_start),
                    ("create_date", "<=", day_end),
                ]
            )

            weekly_trend.append({"date": day.strftime("%Y-%m-%d"), "count": day_count})

        weekly_trend.reverse()  # Chronological order

        return {
            "total_expenses": total_expenses,
            "total_with_ocr": total_with_ocr,
            "ocr_coverage_pct": round(
                (total_with_ocr / total_expenses * 100) if total_expenses > 0 else 0, 1
            ),
            "today_processed": today_processed,
            "low_confidence_count": low_confidence_count,
            "anomaly_count": anomaly_count,
            "visual_changes_count": visual_changes_count,
            "avg_confidence": round(avg_confidence, 2),
            "avg_similarity": round(avg_similarity * 100, 2),
            "top_vendors": top_vendors,
            "status_distribution": status_distribution,
            "recent_activity": recent_activity,
            "weekly_trend": weekly_trend,
        }
