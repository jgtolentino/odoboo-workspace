from odoo import models, fields

class WorkspaceActivity(models.Model):
    _name = 'workspace.activity'
    _description = 'Workspace Activity'
    _order = 'activity_date desc'

    activity_date = fields.Datetime(
        string='Activity Date',
        default=fields.Datetime.now,
        required=True
    )
    
    activity_type = fields.Selection(
        [
            ('page_created', 'Page Created'),
            ('page_updated', 'Page Updated'),
            ('task_created', 'Task Created'),
            ('task_completed', 'Task Completed'),
            ('expense_submitted', 'Expense Submitted'),
            ('invoice_created', 'Invoice Created'),
            ('vendor_added', 'Vendor Added'),
            ('document_uploaded', 'Document Uploaded'),
            ('comment_added', 'Comment Added'),
        ],
        string='Activity Type',
        required=True
    )
    
    user_id = fields.Many2one(
        'res.users',
        string='User',
        required=True
    )
    
    description = fields.Char(string='Description', required=True)
    
    # Related record
    related_model = fields.Char(string='Related Model')
    related_id = fields.Integer(string='Related ID')
    
    # Metadata
    is_important = fields.Boolean(string='Important', default=False)
    
    def create_activity(self, activity_type, user_id, description, related_model=None, related_id=None):
        """Helper method to create activity records"""
        return self.create({
            'activity_type': activity_type,
            'user_id': user_id,
            'description': description,
            'related_model': related_model,
            'related_id': related_id,
        })
