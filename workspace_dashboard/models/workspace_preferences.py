from odoo import models, fields

class WorkspacePreferences(models.Model):
    _name = 'workspace.preferences'
    _description = 'Workspace Preferences'

    user_id = fields.Many2one(
        'res.users',
        string='User',
        default=lambda self: self.env.user,
        required=True,
        ondelete='cascade',
        unique=True
    )
    
    # Display preferences
    theme = fields.Selection(
        [
            ('light', 'Light'),
            ('dark', 'Dark'),
            ('auto', 'Auto'),
        ],
        string='Theme',
        default='auto'
    )
    
    items_per_page = fields.Integer(
        string='Items Per Page',
        default=20,
        help='Number of items to display per page'
    )
    
    # Notification preferences
    notify_task_assigned = fields.Boolean(string='Notify on Task Assignment', default=True)
    notify_expense_approved = fields.Boolean(string='Notify on Expense Approval', default=True)
    notify_invoice_overdue = fields.Boolean(string='Notify on Overdue Invoices', default=True)
    notify_document_shared = fields.Boolean(string='Notify on Document Sharing', default=True)
    
    # Workspace preferences
    default_view = fields.Selection(
        [
            ('dashboard', 'Dashboard'),
            ('knowledge', 'Knowledge'),
            ('projects', 'Projects'),
            ('expenses', 'Expenses'),
            ('invoices', 'Invoices'),
            ('vendors', 'Vendors'),
        ],
        string='Default View',
        default='dashboard'
    )
    
    show_tips = fields.Boolean(string='Show Tips', default=True)
    enable_quick_search = fields.Boolean(string='Enable Quick Search', default=True)
    
    # Sidebar preferences
    sidebar_collapsed = fields.Boolean(string='Sidebar Collapsed', default=False)
    favorite_modules = fields.Char(
        string='Favorite Modules',
        help='Comma-separated list of favorite module names'
    )
