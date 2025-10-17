from odoo import models, fields

class VendorDocument(models.Model):
    _name = 'vendor.document'
    _description = 'Vendor Document'
    _inherit = ['mail.thread', 'mail.activity.mixin']
    _order = 'sequence, name'

    name = fields.Char(string='Document Name', required=True, tracking=True)
    vendor_id = fields.Many2one(
        'res.partner',
        string='Vendor',
        required=True,
        ondelete='cascade',
        tracking=True
    )
    
    document_type = fields.Selection(
        [
            ('contract', 'Contract'),
            ('agreement', 'Agreement'),
            ('certification', 'Certification'),
            ('invoice', 'Invoice'),
            ('quote', 'Quote'),
            ('other', 'Other'),
        ],
        string='Document Type',
        required=True,
        tracking=True
    )
    
    description = fields.Text(string='Description')
    
    # Document file
    attachment_ids = fields.One2many(
        'ir.attachment',
        'res_id',
        domain=[('res_model', '=', 'vendor.document')],
        string='Attachments'
    )
    
    # Metadata
    document_date = fields.Date(string='Document Date')
    expiry_date = fields.Date(string='Expiry Date')
    
    author_id = fields.Many2one(
        'res.users',
        string='Created By',
        default=lambda self: self.env.user,
        readonly=True
    )
    
    created_date = fields.Datetime(
        string='Created',
        default=fields.Datetime.now,
        readonly=True
    )
    
    # Status
    is_active = fields.Boolean(string='Active', default=True)
    sequence = fields.Integer(string='Sequence', default=10)
    
    # Computed fields
    is_expired = fields.Boolean(
        string='Is Expired',
        compute='_compute_is_expired'
    )
    
    days_until_expiry = fields.Integer(
        string='Days Until Expiry',
        compute='_compute_days_until_expiry'
    )
    
    def _compute_is_expired(self):
        from datetime import datetime
        today = datetime.now().date()
        for record in self:
            record.is_expired = record.expiry_date and record.expiry_date < today
    
    def _compute_days_until_expiry(self):
        from datetime import datetime
        today = datetime.now().date()
        for record in self:
            if record.expiry_date:
                record.days_until_expiry = (record.expiry_date - today).days
            else:
                record.days_until_expiry = -1
