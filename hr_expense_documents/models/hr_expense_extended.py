from odoo import models, fields, api

class HrExpenseExtended(models.Model):
    _inherit = 'hr.expense'

    # Knowledge integration
    knowledge_page_id = fields.Many2one(
        'knowledge.page',
        string='Related Knowledge Page',
        ondelete='set null'
    )
    
    # Document management
    attachment_ids = fields.One2many(
        'ir.attachment',
        'res_id',
        domain=[('res_model', '=', 'hr.expense')],
        string='Attachments'
    )
    
    # Extended categorization
    expense_category_id = fields.Many2one(
        'expense.category',
        string='Expense Category',
        ondelete='set null'
    )
    
    # Approval tracking
    approval_date = fields.Datetime(string='Approval Date', readonly=True)
    approval_notes = fields.Text(string='Approval Notes')
    
    # Computed fields for rollups
    total_attachments = fields.Integer(
        string='Number of Attachments',
        compute='_compute_total_attachments'
    )
    
    def _compute_total_attachments(self):
        for record in self:
            record.total_attachments = len(record.attachment_ids)
    
    def action_submit_expenses(self):
        """Override to add approval date tracking"""
        result = super().action_submit_expenses()
        self.approval_date = fields.Datetime.now()
        return result
