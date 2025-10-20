# -*- coding: utf-8 -*-
from odoo import models, fields


class ResPartner(models.Model):
    """Extend res.partner for portal preferences"""
    _inherit = 'res.partner'

    # Portal Preferences
    x_hardcopy_billing = fields.Boolean(
        string='Send Hardcopy Statements',
        help='If enabled, receive printed Statement of Account by mail',
        default=False,
    )

    # Budget Requests
    budget_request_ids = fields.One2many(
        'odoobo.budget.request',
        'customer_id',
        string='Budget Requests',
    )
    budget_request_count = fields.Integer(
        string='Budget Requests',
        compute='_compute_budget_request_count',
    )

    def _compute_budget_request_count(self):
        """Count budget requests for smart button"""
        for partner in self:
            partner.budget_request_count = len(partner.budget_request_ids)

    def action_view_budget_requests(self):
        """Smart button: View budget requests"""
        self.ensure_one()
        return {
            'name': 'Budget Requests',
            'type': 'ir.actions.act_window',
            'res_model': 'odoobo.budget.request',
            'view_mode': 'tree,form',
            'domain': [('customer_id', '=', self.id)],
            'context': {'default_customer_id': self.id},
        }
