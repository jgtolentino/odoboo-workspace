# -*- coding: utf-8 -*-
from odoo import models, fields, api, _
from odoo.exceptions import UserError, ValidationError
import requests
import json


class BudgetRequest(models.Model):
    """Project Budget Request with AI agent integration"""
    _name = 'odoobo.budget.request'
    _description = 'Project Budget Request'
    _order = 'create_date desc'
    _inherit = ['mail.thread', 'mail.activity.mixin', 'portal.mixin']

    # Basic Information
    name = fields.Char(
        string='Budget Reference',
        required=True,
        copy=False,
        default='New',
        index=True,
    )
    project_name = fields.Char(
        string='Project Name',
        required=True,
        tracking=True,
    )
    customer_id = fields.Many2one(
        'res.partner',
        string='Customer',
        required=True,
        tracking=True,
        domain=[('customer_rank', '>', 0)],
    )

    # State Management
    state = fields.Selection([
        ('draft', 'Draft'),
        ('submitted', 'Submitted'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    ], string='Status', default='draft', required=True, tracking=True)

    # Budget Lines
    line_ids = fields.One2many(
        'odoobo.budget.line',
        'budget_id',
        string='Budget Lines',
        copy=True,
    )

    # Totals
    total = fields.Monetary(
        string='Total Amount',
        compute='_compute_total',
        store=True,
        tracking=True,
    )
    currency_id = fields.Many2one(
        'res.currency',
        string='Currency',
        default=lambda self: self.env.company.currency_id,
        required=True,
    )

    # Notes and Rejection
    notes = fields.Text(string='Notes')
    rejection_reason = fields.Text(
        string='Rejection Reason',
        tracking=True,
    )

    # Related Records
    sale_order_id = fields.Many2one(
        'sale.order',
        string='Sales Order',
        copy=False,
        tracking=True,
    )
    analytic_account_id = fields.Many2one(
        'account.analytic.account',
        string='Analytic Account',
        copy=False,
        tracking=True,
    )

    # Responsible Users
    user_id = fields.Many2one(
        'res.users',
        string='Account Manager',
        default=lambda self: self.env.user,
        required=True,
        tracking=True,
    )
    approver_id = fields.Many2one(
        'res.users',
        string='Approved By',
        copy=False,
        tracking=True,
    )
    approved_date = fields.Datetime(
        string='Approved Date',
        copy=False,
        tracking=True,
    )

    @api.model_create_multi
    def create(self, vals_list):
        """Auto-generate sequence number"""
        for vals in vals_list:
            if vals.get('name', 'New') == 'New':
                vals['name'] = self.env['ir.sequence'].next_by_code(
                    'odoobo.budget.request'
                ) or 'New'
        return super().create(vals_list)

    @api.depends('line_ids.subtotal')
    def _compute_total(self):
        """Calculate total from budget lines"""
        for record in self:
            record.total = sum(record.line_ids.mapped('subtotal'))

    def action_submit(self):
        """Submit budget for approval"""
        self.ensure_one()

        if not self.line_ids:
            raise UserError(_("Cannot submit empty budget request."))

        # Call AI agent for validation (pr-review skill)
        agent_validation = self._call_agent_pr_review()

        # Update state
        self.write({
            'state': 'submitted',
        })

        # Add Finance Director as follower
        finance_group = self.env.ref('odoobo_budget.group_budget_finance_director')
        finance_users = self.env['res.users'].search([
            ('groups_id', 'in', finance_group.id)
        ])
        self.message_subscribe(partner_ids=finance_users.mapped('partner_id').ids)

        # Send email notification
        template = self.env.ref('odoobo_budget.email_template_budget_submitted')
        self.message_post_with_template(template.id)

        # Post agent validation if warnings
        if agent_validation.get('warnings'):
            self.message_post(
                body=f"<strong>AI Validation Warnings:</strong><br/>"
                     f"{agent_validation['warnings']}",
                message_type='notification',
            )

        return True

    def action_approve(self):
        """Approve budget and create SO + Analytic Account"""
        self.ensure_one()

        if self.state != 'submitted':
            raise UserError(_("Only submitted budgets can be approved."))

        # Create Analytic Account
        analytic = self.env['account.analytic.account'].create({
            'name': f"{self.project_name} - {self.customer_id.name}",
            'partner_id': self.customer_id.id,
        })

        # Create Sales Order
        so = self.env['sale.order'].create({
            'partner_id': self.customer_id.id,
            'origin': self.name,
            'analytic_account_id': analytic.id,
        })

        # Create SO lines from budget lines
        for line in self.line_ids:
            self.env['sale.order.line'].create({
                'order_id': so.id,
                'name': f"{line.rate_card_id.role} ({line.rate_card_id.seniority})",
                'product_uom_qty': line.qty,
                'price_unit': line.unit_rate,
                'analytic_distribution': {str(analytic.id): 100},
            })

        # Update budget
        self.write({
            'state': 'approved',
            'approver_id': self.env.user.id,
            'approved_date': fields.Datetime.now(),
            'sale_order_id': so.id,
            'analytic_account_id': analytic.id,
        })

        # Post message
        self.message_post(
            body=f"Budget approved. Sales Order <a href='/web#id={so.id}&"
                 f"model=sale.order'>{so.name}</a> created.",
            message_type='notification',
        )

        # Send email
        template = self.env.ref('odoobo_budget.email_template_budget_approved')
        self.message_post_with_template(template.id)

        return True

    def action_reject(self):
        """Reject budget request"""
        self.ensure_one()

        if self.state != 'submitted':
            raise UserError(_("Only submitted budgets can be rejected."))

        # Open wizard for rejection reason
        return {
            'name': 'Reject Budget',
            'type': 'ir.actions.act_window',
            'res_model': 'odoobo.budget.reject.wizard',
            'view_mode': 'form',
            'target': 'new',
            'context': {'default_budget_id': self.id},
        }

    def _call_agent_pr_review(self):
        """
        Call odoobo-expert agent pr-review skill for budget validation

        Returns:
            dict: Agent response with validation results
        """
        agent_url = self.env['ir.config_parameter'].sudo().get_param(
            'odoobo.agent_url'
        )

        if not agent_url:
            return {'warnings': ''}

        try:
            # Prepare budget data
            budget_data = {
                'name': self.name,
                'project_name': self.project_name,
                'customer': self.customer_id.name,
                'total': self.total,
                'lines': [{
                    'role': line.rate_card_id.role,
                    'seniority': line.rate_card_id.seniority,
                    'qty': line.qty,
                    'rate': line.unit_rate,
                    'subtotal': line.subtotal,
                } for line in self.line_ids],
            }

            # Call agent
            response = requests.post(
                f"{agent_url}/skills/pr-review",
                json={'input': budget_data},
                timeout=30,
            )
            response.raise_for_status()

            return response.json().get('result', {})

        except Exception as e:
            # Log error but don't block submission
            self.message_post(
                body=f"Agent validation unavailable: {str(e)}",
                message_type='comment',
            )
            return {'warnings': ''}

    def action_view_sale_order(self):
        """Smart button: View related Sales Order"""
        self.ensure_one()
        return {
            'name': 'Sales Order',
            'type': 'ir.actions.act_window',
            'res_model': 'sale.order',
            'res_id': self.sale_order_id.id,
            'view_mode': 'form',
        }

    def _compute_access_url(self):
        """Portal access URL"""
        super()._compute_access_url()
        for record in self:
            record.access_url = f'/my/budgets/{record.id}'
