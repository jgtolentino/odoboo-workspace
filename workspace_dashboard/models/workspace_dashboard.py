from odoo import models, fields, api

class WorkspaceDashboard(models.Model):
    _name = 'workspace.dashboard'
    _description = 'Workspace Dashboard'

    user_id = fields.Many2one(
        'res.users',
        string='User',
        default=lambda self: self.env.user,
        required=True,
        ondelete='cascade'
    )
    
    # Dashboard configuration
    dashboard_name = fields.Char(string='Dashboard Name', default='My Workspace')
    is_default = fields.Boolean(string='Set as Default', default=False)
    
    # Widget configuration
    show_knowledge = fields.Boolean(string='Show Knowledge', default=True)
    show_expenses = fields.Boolean(string='Show Expenses', default=True)
    show_projects = fields.Boolean(string='Show Projects', default=True)
    show_invoices = fields.Boolean(string='Show Invoices', default=True)
    show_vendors = fields.Boolean(string='Show Vendors', default=True)
    show_metrics = fields.Boolean(string='Show Metrics', default=True)
    show_activity = fields.Boolean(string='Show Activity', default=True)
    
    # Widget order
    widget_order = fields.Text(
        string='Widget Order',
        default='knowledge,expenses,projects,invoices,vendors,metrics,activity',
        help='Comma-separated list of widget names in order'
    )
    
    # Computed fields for dashboard data
    recent_pages = fields.Integer(
        string='Recent Pages',
        compute='_compute_recent_pages'
    )
    
    pending_tasks = fields.Integer(
        string='Pending Tasks',
        compute='_compute_pending_tasks'
    )
    
    pending_expenses = fields.Integer(
        string='Pending Expenses',
        compute='_compute_pending_expenses'
    )
    
    overdue_invoices = fields.Integer(
        string='Overdue Invoices',
        compute='_compute_overdue_invoices'
    )
    
    def _compute_recent_pages(self):
        for record in self:
            record.recent_pages = self.env['knowledge.page'].search_count([
                ('is_archived', '=', False)
            ])
    
    def _compute_pending_tasks(self):
        for record in self:
            record.pending_tasks = self.env['project.task'].search_count([
                ('state', '!=', 'done'),
                ('assigned_user_id', '=', record.user_id.id)
            ])
    
    def _compute_pending_expenses(self):
        for record in self:
            record.pending_expenses = self.env['hr.expense'].search_count([
                ('state', '=', 'draft'),
                ('employee_id.user_id', '=', record.user_id.id)
            ])
    
    def _compute_overdue_invoices(self):
        from datetime import datetime
        for record in self:
            record.overdue_invoices = self.env['account.move'].search_count([
                ('payment_status', '=', 'overdue')
            ])
