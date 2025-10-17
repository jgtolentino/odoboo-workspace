from odoo import models, fields

class InvoiceTemplate(models.Model):
    _name = 'invoice.template'
    _description = 'Invoice Template'
    _order = 'sequence, name'

    name = fields.Char(string='Template Name', required=True)
    description = fields.Text(string='Description')
    code = fields.Char(string='Template Code', required=True)
    
    # Template content
    template_content = fields.Html(string='Template Content')
    
    # Knowledge integration
    knowledge_page_id = fields.Many2one(
        'knowledge.page',
        string='Related Documentation',
        ondelete='set null'
    )
    
    # Usage tracking
    invoice_ids = fields.One2many(
        'account.move',
        'invoice_template_id',
        string='Invoices Using This Template'
    )
    
    usage_count = fields.Integer(
        string='Usage Count',
        compute='_compute_usage_count'
    )
    
    # Metadata
    company_id = fields.Many2one(
        'res.company',
        string='Company',
        required=True,
        default=lambda self: self.env.company
    )
    
    is_active = fields.Boolean(string='Active', default=True)
    sequence = fields.Integer(string='Sequence', default=10)
    
    def _compute_usage_count(self):
        for record in self:
            record.usage_count = len(record.invoice_ids)
