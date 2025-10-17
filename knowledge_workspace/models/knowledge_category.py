from odoo import models, fields

class KnowledgeCategory(models.Model):
    _name = 'knowledge.category'
    _description = 'Knowledge Category'
    _order = 'sequence, name'

    name = fields.Char(string='Category Name', required=True)
    description = fields.Text(string='Description')
    parent_id = fields.Many2one(
        'knowledge.category',
        string='Parent Category',
        ondelete='cascade'
    )
    child_ids = fields.One2many(
        'knowledge.category',
        'parent_id',
        string='Subcategories'
    )
    
    page_ids = fields.One2many(
        'knowledge.page',
        'category_id',
        string='Pages'
    )
    
    color = fields.Integer(string='Color Index', default=0)
    sequence = fields.Integer(string='Sequence', default=10)
    icon = fields.Char(string='Icon', default='fa-folder')
    
    page_count = fields.Integer(
        string='Page Count',
        compute='_compute_page_count'
    )
    
    def _compute_page_count(self):
        for record in self:
            record.page_count = len(record.page_ids)
