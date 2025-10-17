import hashlib
import json
from odoo import api, fields, models, _
from odoo.exceptions import ValidationError

USE_CONCUR_PARAM = "expense_integration.use_concur"


class HrExpense(models.Model):
    _inherit = "hr.expense"

    cost_center_id = fields.Many2one("account.analytic.account", string="Cost Center", index=True)
    gl_account_id = fields.Many2one("account.account", string="GL Account", index=True)
    tax_id = fields.Many2one("account.tax", string="Tax Code")
    project_id = fields.Many2one("project.project", string="Project")
    vendor_id = fields.Many2one(
        "res.partner", domain=[("supplier_rank", ">", 0)], string="Vendor"
    )
    txn_date = fields.Date(string="Transaction Date")
    fx_rate = fields.Float(help="Locked at submit.")
    amount_net = fields.Monetary()
    amount_tax = fields.Monetary()
    amount_gross = fields.Monetary()
    extracted_fields = fields.Json(string="OCR Extract", help="Raw normalized fields")
    idempotency_key = fields.Char(copy=False, index=True, readonly=True)
    export_status = fields.Selection(
        [
            ("pending", "Pending"),
            ("sent", "Sent"),
            ("ack", "Acknowledged"),
            ("error", "Error"),
        ],
        default="pending",
        copy=False,
        index=True,
    )
    export_payload = fields.Json(copy=False)

    @api.onchange("tax_id", "total_amount")
    def _onchange_amounts(self):
        for rec in self:
            tax_rate = 0.0
            if rec.tax_id and rec.tax_id.amount_type == "percent":
                tax_rate = rec.tax_id.amount / 100.0
            if tax_rate:
                rec.amount_net = rec.total_amount / (1.0 + tax_rate)
                rec.amount_tax = rec.total_amount - rec.amount_net
            else:
                rec.amount_net = rec.total_amount
                rec.amount_tax = 0.0
            rec.amount_gross = rec.total_amount

    def _current_fx(self):
        """Get current FX rate for expense currency."""
        self.ensure_one()
        if self.currency_id == self.company_id.currency_id:
            return 1.0
        rate = self.currency_id._get_conversion_rate(
            self.currency_id,
            self.company_id.currency_id,
            self.company_id,
            self.date or fields.Date.today(),
        )
        return rate

    def action_submit_expenses(self):
        """Lock FX rate on submit."""
        for rec in self:
            if not rec.fx_rate:
                rec.fx_rate = rec._current_fx()
        return super().action_submit_expenses()

    @api.constrains("product_id", "cost_center_id", "gl_account_id", "tax_id", "project_id", "vendor_id")
    def _check_concur_mappings_if_enabled(self):
        """Validate required Concur fields when integration is enabled."""
        param = self.env["ir.config_parameter"].sudo().get_param(USE_CONCUR_PARAM, "false")
        if param.lower() != "true":
            return
        required = [("cost_center_id", "cost_center"), ("gl_account_id", "gl_account")]
        for rec in self:
            for f, kind in required:
                if not rec[f]:
                    raise ValidationError(
                        _("%s is required when Concur integration is enabled.") % f
                    )

    def _make_idempotency_key(self):
        """Generate idempotency key for Concur export."""
        self.ensure_one()
        payload = f"{self.employee_id.id}|{self.txn_date or self.date}|{self.total_amount}|{self.vendor_id.id or 0}"
        return hashlib.sha256(payload.encode("utf-8")).hexdigest()

    def to_concur_dto(self):
        """Convert expense to Concur DTO format."""
        self.ensure_one()
        dto = {
            "employee": {
                "id": self.employee_id.id,
                "name": self.employee_id.name,
                "work_email": self.employee_id.work_email,
            },
            "report": {
                "currency": self.currency_id.name,
                "submitted_at": fields.Datetime.now().isoformat(),
            },
            "line": {
                "expense_id": self.id,
                "type": self.product_id and self.product_id.name or "",
                "cost_center_id": self.cost_center_id and self.cost_center_id.id or None,
                "gl_account_id": self.gl_account_id and self.gl_account_id.id or None,
                "tax_code_id": self.tax_id and self.tax_id.id or None,
                "project_id": self.project_id and self.project_id.id or None,
                "vendor_id": self.vendor_id and self.vendor_id.id or None,
                "txn_date": (self.txn_date or self.date).isoformat()
                if (self.txn_date or self.date)
                else None,
                "currency": self.currency_id.name,
                "fx_rate": self.fx_rate or 1.0,
                "amount_net": float(self.amount_net or 0),
                "amount_tax": float(self.amount_tax or 0),
                "amount_gross": float(self.amount_gross or 0),
            },
            "meta": {
                "idempotency_key": self.idempotency_key or self._make_idempotency_key(),
                "source": "odoo",
                "version": "19.0.1",
            },
        }
        return dto

    def action_mark_pending(self):
        """Mark expense as pending for export."""
        self.write({"export_status": "pending"})

    def export_batch_to_concur_queue(self, limit=200):
        """Batch export pending expenses to Concur queue."""
        to_send = self.search([("export_status", "=", "pending")], limit=limit)
        for rec in to_send:
            payload = rec.to_concur_dto()
            rec.write(
                {
                    "export_payload": payload,
                    "idempotency_key": payload["meta"]["idempotency_key"],
                    "export_status": "sent",
                }
            )
        return len(to_send)


class HrExpenseSheet(models.Model):
    _inherit = "hr.expense.sheet"

    def action_submit_sheet(self):
        """Submit sheet and trigger Concur export for new lines."""
        res = super().action_submit_sheet()
        # Kick off export for newly submitted lines
        for sheet in self:
            sheet.expense_line_ids.filtered(
                lambda e: e.export_status == "pending"
            ).export_batch_to_concur_queue(limit=9999)
        return res
