from odoo import models, fields

class ProjectWiki(models.Model):
    _name = 'project.wiki'
    _description = 'Project Wiki Page'
    _inherit = ['mail.thread', 'mail.activity.mixin']
    _order = 'sequence, name'

    name = fields.Char(string='Title', required=True, tracking=True)
    project_id = fields.Many2one(
        'project.project',
        string='Project',
        required=True,
        ondelete='cascade'
    )
    
    content = fields.Html(string='Content', tracking=True)
    description = fields.Text(string='Description')
    
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
    
    # Organization
    parent_wiki_id = fields.Many2one(
        'project.wiki',
        string='Parent Page',
        ondelete='cascade'
    )
    
    child_wiki_ids = fields.One2many(
        'project.wiki',
        'parent_wiki_id',
        string='Sub Pages'
    )
    
    sequence = fields.Integer(string='Sequence', default=10)
    is_published = fields.Boolean(string='Published', default=True)
