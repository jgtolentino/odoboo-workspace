# -*- coding: utf-8 -*-
from odoo import models, fields, api


class BudgetLine(models.Model):
    """Budget Request Line"""
    _name = 'odoobo.budget.line'
    _description = 'Budget Line'
    _order = 'budget_id, sequence, id'

    # Parent Budget
    budget_id = fields.Many2one(
        'odoobo.budget.request',
        string='Budget',
        required=True,
        ondelete='cascade',
        index=True,
    )

    # Sequence for ordering
    sequence = fields.Integer(string='Sequence', default=10)

    # Rate Card Selection
    rate_card_id = fields.Many2one(
        'odoobo.rate.card',
        string='Rate Card',
        required=True,
        domain=[('active', '=', True)],
    )

    # Line Details
    qty = fields.Float(
        string='Hours',
        default=1.0,
        required=True,
        help='Number of hours for this role'
    )
    unit_rate = fields.Monetary(
        string='Hourly Rate',
        required=True,
        currency_field='currency_id',
    )
    subtotal = fields.Monetary(
        string='Subtotal',
        compute='_compute_subtotal',
        store=True,
        currency_field='currency_id',
    )
    currency_id = fields.Many2one(
        related='budget_id.currency_id',
        string='Currency',
        store=True,
    )

    # Descriptions
    description = fields.Text(string='Description')

    @api.onchange('rate_card_id')
    def _onchange_rate_card(self):
        """Auto-fill unit rate from selected rate card"""
        if self.rate_card_id:
            self.unit_rate = self.rate_card_id.hourly_rate

    @api.depends('qty', 'unit_rate')
    def _compute_subtotal(self):
        """Calculate line subtotal"""
        for line in self:
            line.subtotal = (line.qty or 0.0) * (line.unit_rate or 0.0)
