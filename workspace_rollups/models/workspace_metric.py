from odoo import models, fields, api
from datetime import datetime, timedelta

class WorkspaceMetric(models.Model):
    _name = 'workspace.metric'
    _description = 'Workspace Metric'
    _order = 'metric_date desc'

    metric_date = fields.Date(
        string='Metric Date',
        default=fields.Date.today,
        required=True
    )
    
    # Knowledge metrics
    total_pages = fields.Integer(
        string='Total Knowledge Pages',
        compute='_compute_knowledge_metrics'
    )
    
    total_categories = fields.Integer(
        string='Total Categories',
        compute='_compute_knowledge_metrics'
    )
    
    # HR metrics
    total_expenses = fields.Float(
        string='Total Expenses',
        compute='_compute_hr_metrics'
    )
    
    pending_expenses = fields.Integer(
        string='Pending Expenses',
        compute='_compute_hr_metrics'
    )
    
    approved_expenses = fields.Float(
        string='Approved Expenses',
        compute='_compute_hr_metrics'
    )
    
    # Project metrics
    total_projects = fields.Integer(
        string='Total Projects',
        compute='_compute_project_metrics'
    )
    
    total_tasks = fields.Integer(
        string='Total Tasks',
        compute='_compute_project_metrics'
    )
    
    completed_tasks = fields.Integer(
        string='Completed Tasks',
        compute='_compute_project_metrics'
    )
    
    overall_project_progress = fields.Float(
        string='Overall Project Progress %',
        compute='_compute_project_metrics'
    )
    
    # Accounting metrics
    total_invoices = fields.Integer(
        string='Total Invoices',
        compute='_compute_accounting_metrics'
    )
    
    unpaid_invoices = fields.Integer(
        string='Unpaid Invoices',
        compute='_compute_accounting_metrics'
    )
    
    total_invoice_amount = fields.Float(
        string='Total Invoice Amount',
        compute='_compute_accounting_metrics'
    )
    
    overdue_amount = fields.Float(
        string='Overdue Amount',
        compute='_compute_accounting_metrics'
    )
    
    # Vendor metrics
    total_vendors = fields.Integer(
        string='Total Vendors',
        compute='_compute_vendor_metrics'
    )
    
    active_vendors = fields.Integer(
        string='Active Vendors',
        compute='_compute_vendor_metrics'
    )
    
    total_vendor_spend = fields.Float(
        string='Total Vendor Spend',
        compute='_compute_vendor_metrics'
    )
    
    def _compute_knowledge_metrics(self):
        for record in self:
            record.total_pages = self.env['knowledge.page'].search_count([
                ('is_archived', '=', False)
            ])
            record.total_categories = self.env['knowledge.category'].search_count([])
    
    def _compute_hr_metrics(self):
        for record in self:
            expenses = self.env['hr.expense'].search([
                ('create_date', '>=', record.metric_date),
                ('create_date', '<', record.metric_date + timedelta(days=1))
            ])
            record.total_expenses = sum(expenses.mapped('total_amount'))
            record.pending_expenses = len(expenses.filtered(lambda e: e.state == 'draft'))
            record.approved_expenses = sum(expenses.filtered(lambda e: e.state == 'approved').mapped('total_amount'))
    
    def _compute_project_metrics(self):
        for record in self:
            projects = self.env['project.project'].search([])
            record.total_projects = len(projects)
            
            all_tasks = self.env['project.task'].search([])
            record.total_tasks = len(all_tasks)
            record.completed_tasks = len(all_tasks.filtered(lambda t: t.state == 'done'))
            
            if record.total_tasks > 0:
                record.overall_project_progress = (record.completed_tasks / record.total_tasks) * 100
            else:
                record.overall_project_progress = 0
    
    def _compute_accounting_metrics(self):
        for record in self:
            invoices = self.env['account.move'].search([
                ('move_type', 'in', ['out_invoice', 'in_invoice']),
                ('state', '=', 'posted')
            ])
            record.total_invoices = len(invoices)
            record.unpaid_invoices = len(invoices.filtered(lambda i: i.payment_status in ['unpaid', 'partial']))
            record.total_invoice_amount = sum(invoices.mapped('amount_total'))
            record.overdue_amount = sum(invoices.filtered(lambda i: i.payment_status == 'overdue').mapped('amount_residual'))
    
    def _compute_vendor_metrics(self):
        for record in self:
            vendors = self.env['res.partner'].search([('is_vendor_kb', '=', True)])
            record.total_vendors = len(vendors)
            record.active_vendors = len(vendors.filtered(lambda v: v.active))
            record.total_vendor_spend = sum(vendors.mapped('total_spent'))
