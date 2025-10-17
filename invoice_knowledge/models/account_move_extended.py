from odoo import models, fields, api

class AccountMoveExtended(models.Model):
    _inherit = 'account.move'

    # Knowledge integration
    knowledge_page_id = fields.Many2one(
        'knowledge.page',
        string='Related Documentation',
        ondelete='set null'
    )
    
    invoice_template_id = fields.Many2one(
        'invoice.template',
        string='Invoice Template',
        ondelete='set null'
    )
    
    # Document management
    attachment_ids = fields.One2many(
        'ir.attachment',
        'res_id',
        domain=[('res_model', '=', 'account.move')],
        string='Attachments'
    )
    
    # Extended metadata
    invoice_category = fields.Selection(
        [
            ('sales', 'Sales Invoice'),
            ('purchase', 'Purchase Invoice'),
            ('credit', 'Credit Note'),
            ('debit', 'Debit Note'),
        ],
        string='Invoice Category',
        compute='_compute_invoice_category',
        store=True
    )
    
    # Workflow tracking
    approval_date = fields.Datetime(string='Approval Date', readonly=True)
    approval_notes = fields.Text(string='Approval Notes')
    
    # Computed fields for rollups
    total_attachments = fields.Integer(
        string='Number of Attachments',
        compute='_compute_total_attachments'
    )
    
    days_overdue = fields.Integer(
        string='Days Overdue',
        compute='_compute_days_overdue'
    )
    
    payment_status = fields.Selection(
        [
            ('unpaid', 'Unpaid'),
            ('partial', 'Partially Paid'),
            ('paid', 'Paid'),
            ('overdue', 'Overdue'),
        ],
        string='Payment Status',
        compute='_compute_payment_status',
        store=True
    )
    
    @api.depends('move_type')
    def _compute_invoice_category(self):
        for record in self:
            if record.move_type == 'out_invoice':
                record.invoice_category = 'sales'
            elif record.move_type == 'in_invoice':
                record.invoice_category = 'purchase'
            elif record.move_type == 'out_refund':
                record.invoice_category = 'credit'
            elif record.move_type == 'in_refund':
                record.invoice_category = 'debit'
    
    def _compute_total_attachments(self):
        for record in self:
            record.total_attachments = len(record.attachment_ids)
    
    def _compute_days_overdue(self):
        from datetime import datetime
        today = datetime.now().date()
        for record in self:
            if record.invoice_date_due and record.invoice_date_due < today:
                record.days_overdue = (today - record.invoice_date_due).days
            else:
                record.days_overdue = 0
    
    @api.depends('amount_residual', 'amount_total', 'state')
    def _compute_payment_status(self):
        for record in self:
            if record.state != 'posted':
                record.payment_status = 'unpaid'
            elif record.amount_residual == 0:
                record.payment_status = 'paid'
            elif record.amount_residual < record.amount_total:
                record.payment_status = 'partial'
            else:
                from datetime import datetime
                if record.invoice_date_due and record.invoice_date_due < datetime.now().date():
                    record.payment_status = 'overdue'
                else:
                    record.payment_status = 'unpaid'
