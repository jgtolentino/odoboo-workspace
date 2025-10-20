# -*- coding: utf-8 -*-
from odoo import models, fields, api
from odoo.exceptions import ValidationError


class RateCard(models.Model):
    """Rate Card for role-based pricing"""
    _name = 'odoobo.rate.card'
    _description = 'Rate Card'
    _order = 'role, seniority, effective_from desc'
    _inherit = ['mail.thread', 'mail.activity.mixin']

    # Basic Information
    name = fields.Char(
        string='Name',
        compute='_compute_name',
        store=True,
        index=True,
    )
    role = fields.Char(
        string='Role',
        required=True,
        tracking=True,
        help='E.g., Designer, Engineer, PM, QA'
    )
    seniority = fields.Selection([
        ('junior', 'Junior'),
        ('mid', 'Mid-Level'),
        ('senior', 'Senior'),
        ('lead', 'Lead'),
        ('principal', 'Principal'),
    ], string='Seniority', required=True, tracking=True)

    # Pricing
    hourly_rate = fields.Monetary(
        string='Hourly Rate',
        required=True,
        tracking=True,
        help='Rate per hour for this role/seniority'
    )
    currency_id = fields.Many2one(
        'res.currency',
        string='Currency',
        default=lambda self: self.env.company.currency_id,
        required=True,
    )

    # Validity
    effective_from = fields.Date(
        string='Effective From',
        required=True,
        default=fields.Date.context_today,
        tracking=True,
    )
    effective_to = fields.Date(
        string='Effective To',
        tracking=True,
        help='Leave blank for indefinite validity'
    )
    active = fields.Boolean(
        string='Active',
        default=True,
        tracking=True,
    )

    # Description
    description = fields.Text(string='Description')

    # Related Budget Lines
    budget_line_ids = fields.One2many(
        'odoobo.budget.line',
        'rate_card_id',
        string='Budget Lines',
    )
    budget_line_count = fields.Integer(
        string='Budget Lines',
        compute='_compute_budget_line_count',
    )

    @api.depends('role', 'seniority', 'effective_from')
    def _compute_name(self):
        """Auto-generate name from role/seniority/date"""
        for record in self:
            record.name = f"{record.role} ({record.seniority}) - {record.effective_from}"

    @api.depends('budget_line_ids')
    def _compute_budget_line_count(self):
        """Count related budget lines"""
        for record in self:
            record.budget_line_count = len(record.budget_line_ids)

    @api.constrains('effective_from', 'effective_to')
    def _check_date_validity(self):
        """Ensure effective_to is after effective_from"""
        for record in self:
            if record.effective_to and record.effective_to < record.effective_from:
                raise ValidationError(
                    "Effective To date must be after Effective From date."
                )

    @api.model
    def get_active_rate(self, role, seniority, date=None):
        """
        Get active rate for a role/seniority combination

        Args:
            role (str): Role name
            seniority (str): Seniority level
            date (date): Reference date (default: today)

        Returns:
            odoobo.rate.card: Active rate card or empty recordset
        """
        if not date:
            date = fields.Date.context_today(self)

        domain = [
            ('role', '=', role),
            ('seniority', '=', seniority),
            ('active', '=', True),
            ('effective_from', '<=', date),
            '|',
            ('effective_to', '=', False),
            ('effective_to', '>=', date),
        ]

        return self.search(domain, limit=1, order='effective_from desc')

    def action_view_budget_lines(self):
        """Smart button: View related budget lines"""
        self.ensure_one()
        return {
            'name': 'Budget Lines',
            'type': 'ir.actions.act_window',
            'res_model': 'odoobo.budget.line',
            'view_mode': 'tree,form',
            'domain': [('rate_card_id', '=', self.id)],
            'context': {'default_rate_card_id': self.id},
        }
