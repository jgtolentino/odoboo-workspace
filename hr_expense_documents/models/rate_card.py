from odoo import api, fields, models, _
from odoo.exceptions import ValidationError


class VendorRateCard(models.Model):
    _name = "vendor.rate.card"
    _description = "Vendor Rate Card"
    _inherit = ["mail.thread", "mail.activity.mixin"]
    _order = "partner_id, version desc, id desc"

    name = fields.Char(required=True, tracking=True)
    partner_id = fields.Many2one(
        "res.partner",
        string="Vendor",
        required=True,
        domain=[("supplier_rank", ">", 0)],
        tracking=True,
    )
    version = fields.Integer(required=True, default=1, tracking=True)
    status = fields.Selection(
        [
            ("draft", "Draft"),
            ("review", "In Review"),
            ("approved", "Approved"),
            ("active", "Active"),
            ("archived", "Archived"),
        ],
        default="draft",
        tracking=True,
    )
    valid_from = fields.Date(required=True, tracking=True)
    valid_to = fields.Date(tracking=True)
    item_ids = fields.One2many("vendor.rate.card.item", "rate_card_id", string="Items")
    active = fields.Boolean(default=True)

    _sql_constraints = [
        ("uniq_vendor_version", "unique(partner_id,version)", "Vendor + version must be unique."),
    ]

    @api.constrains("valid_from", "valid_to")
    def _check_dates(self):
        for rec in self:
            if rec.valid_to and rec.valid_to < rec.valid_from:
                raise ValidationError(_("valid_to must be after valid_from."))

    @api.constrains("partner_id", "valid_from", "valid_to", "status", "active")
    def _check_overlap(self):
        for rec in self:
            if rec.status in ("approved", "active"):
                domain = [
                    ("id", "!=", rec.id),
                    ("partner_id", "=", rec.partner_id.id),
                    ("status", "in", ["approved", "active"]),
                    ("active", "=", True),
                    ("valid_from", "<=", rec.valid_to or fields.Date.max),
                    ("valid_to", ">=", rec.valid_from),
                ]
                if self.search_count(domain):
                    raise ValidationError(_("Overlapping approved/active rate cards for this vendor."))


class VendorRateCardItem(models.Model):
    _name = "vendor.rate.card.item"
    _description = "Vendor Rate Card Item"
    _order = "rate_card_id, role_id, region_id, valid_from desc"

    rate_card_id = fields.Many2one("vendor.rate.card", required=True, ondelete="cascade")
    role_id = fields.Many2one("hr.job", string="Role")
    region_id = fields.Many2one("res.country.state", string="Region/State")
    unit = fields.Selection(
        [("hour", "Hour"), ("day", "Day"), ("piece", "Piece")],
        default="hour",
        required=True,
    )
    price = fields.Monetary(required=True)
    currency_id = fields.Many2one(
        "res.currency",
        required=True,
        default=lambda self: self.env.company.currency_id.id,
    )
    sla_tier = fields.Char()
    valid_from = fields.Date(required=True)
    valid_to = fields.Date()

    @api.constrains("valid_from", "valid_to")
    def _check_dates(self):
        for rec in self:
            if rec.valid_to and rec.valid_to < rec.valid_from:
                raise ValidationError(_("valid_to must be after valid_from."))

    def find_effective_price(self, partner, role, region, as_of_date, unit):
        """Find effective price for a vendor on a given date with role/region filters."""
        self.ensure_one()
        Item = self.env["vendor.rate.card.item"]
        Card = self.env["vendor.rate.card"]
        
        cards = Card.search(
            [
                ("partner_id", "=", partner.id),
                ("status", "in", ["approved", "active"]),
                ("valid_from", "<=", as_of_date),
                "|",
                ("valid_to", "=", False),
                ("valid_to", ">=", as_of_date),
                ("active", "=", True),
            ],
            order="version desc",
            limit=1,
        )
        
        if not cards:
            return None
        
        items = Item.search(
            [
                ("rate_card_id", "=", cards.id),
                ("unit", "=", unit),
                "|",
                ("role_id", "=", False),
                ("role_id", "=", role.id),
                "|",
                ("region_id", "=", False),
                ("region_id", "=", region.id),
                ("valid_from", "<=", as_of_date),
                "|",
                ("valid_to", "=", False),
                ("valid_to", ">=", as_of_date),
            ],
            order="role_id desc, region_id desc, valid_from desc",
            limit=1,
        )
        
        return items and items.price or None
