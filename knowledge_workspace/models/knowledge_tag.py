from odoo import models, fields

class KnowledgeTag(models.Model):
    _name = 'knowledge.tag'
    _description = 'Knowledge Tag'
    _order = 'name'

    name = fields.Char(string='Tag Name', required=True)
    color = fields.Integer(string='Color Index', default=0)
    
    page_ids = fields.Many2many(
        'knowledge.page',
        string='Pages'
    )
