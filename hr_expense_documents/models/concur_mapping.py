from odoo import api, fields, models, _
from odoo.exceptions import ValidationError


class ConcurMapping(models.Model):
    _name = "concur.mapping"
    _description = "Concur ↔ Odoo Mapping"
    _rec_name = "display_name"
    _order = "kind, concur_key"

    kind = fields.Selection(
        [
            ("expense_type", "Expense Type"),
            ("cost_center", "Cost Center"),
            ("gl_account", "GL Account"),
            ("tax_code", "Tax Code"),
            ("project", "Project"),
            ("payment_type", "Payment Type"),
            ("vendor", "Vendor"),
        ],
        required=True,
        index=True,
    )
    concur_key = fields.Char(required=True, index=True)
    odoo_ref_model = fields.Char(
        required=True,
        help="e.g., account.account, account.analytic.account, project.project, res.partner, account.tax",
    )
    odoo_ref_id = fields.Integer(required=True)
    active = fields.Boolean(default=True)
    display_name = fields.Char(compute="_compute_display", store=False)

    _sql_constraints = [
        ("uniq_kind_key", "unique(kind, concur_key)", "Kind + Concur Key must be unique."),
    ]

    @api.depends("kind", "concur_key", "odoo_ref_model", "odoo_ref_id")
    def _compute_display(self):
        for rec in self:
            rec.display_name = f"[{rec.kind}] {rec.concur_key} → {rec.odoo_ref_model}:{rec.odoo_ref_id}"

    def resolve(self, kind, key):
        """Resolve a Concur key to an Odoo model reference."""
        rec = self.search(
            [("kind", "=", kind), ("concur_key", "=", key), ("active", "=", True)],
            limit=1,
        )
        return rec and (rec.odoo_ref_model, rec.odoo_ref_id) or (False, False)
