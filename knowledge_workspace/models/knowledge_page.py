from odoo import models, fields, api
from datetime import datetime

class KnowledgePage(models.Model):
    _name = 'knowledge.page'
    _description = 'Knowledge Page'
    _inherit = ['mail.thread', 'mail.activity.mixin']
    _order = 'sequence, name'

    name = fields.Char(string='Title', required=True, tracking=True)
    slug = fields.Char(string='URL Slug', compute='_compute_slug', store=True)
    content = fields.Html(string='Content', tracking=True)
    description = fields.Text(string='Description')
    
    category_id = fields.Many2one(
        'knowledge.category',
        string='Category',
        ondelete='set null',
        tracking=True
    )
    tag_ids = fields.Many2many(
        'knowledge.tag',
        string='Tags'
    )
    
    # Document management
    attachment_ids = fields.One2many(
        'ir.attachment',
        'res_id',
        domain=[('res_model', '=', 'knowledge.page')],
        string='Attachments'
    )
    
    # Metadata
    author_id = fields.Many2one(
        'res.users',
        string='Author',
        default=lambda self: self.env.user,
        readonly=True
    )
    created_date = fields.Datetime(
        string='Created',
        default=fields.Datetime.now,
        readonly=True
    )
    modified_date = fields.Datetime(
        string='Last Modified',
        default=fields.Datetime.now
    )
    
    # Access control
    access_level = fields.Selection(
        [
            ('private', 'Private'),
            ('internal', 'Internal'),
            ('public', 'Public'),
        ],
        string='Access Level',
        default='internal',
        tracking=True
    )
    user_ids = fields.Many2many(
        'res.users',
        string='Shared With'
    )
    
    sequence = fields.Integer(string='Sequence', default=10)
    is_archived = fields.Boolean(string='Archived', default=False)
    
    @api.depends('name')
    def _compute_slug(self):
        for record in self:
            if record.name:
                record.slug = record.name.lower().replace(' ', '-')
            else:
                record.slug = ''
    
    def action_archive(self):
        self.is_archived = True
    
    def action_unarchive(self):
        self.is_archived = False
