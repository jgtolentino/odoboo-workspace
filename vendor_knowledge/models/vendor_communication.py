from odoo import models, fields

class VendorCommunication(models.Model):
    _name = 'vendor.communication'
    _description = 'Vendor Communication'
    _inherit = ['mail.thread', 'mail.activity.mixin']
    _order = 'communication_date desc'

    vendor_id = fields.Many2one(
        'res.partner',
        string='Vendor',
        required=True,
        ondelete='cascade'
    )
    
    communication_type = fields.Selection(
        [
            ('email', 'Email'),
            ('phone', 'Phone Call'),
            ('meeting', 'Meeting'),
            ('note', 'Note'),
            ('other', 'Other'),
        ],
        string='Communication Type',
        required=True
    )
    
    subject = fields.Char(string='Subject', required=True)
    description = fields.Html(string='Description')
    
    communication_date = fields.Datetime(
        string='Communication Date',
        default=fields.Datetime.now,
        required=True
    )
    
    # Participants
    user_id = fields.Many2one(
        'res.users',
        string='Communicated By',
        default=lambda self: self.env.user,
        required=True
    )
    
    # Attachments
    attachment_ids = fields.One2many(
        'ir.attachment',
        'res_id',
        domain=[('res_model', '=', 'vendor.communication')],
        string='Attachments'
    )
    
    # Follow-up
    follow_up_required = fields.Boolean(string='Follow-up Required', default=False)
    follow_up_date = fields.Date(string='Follow-up Date')
