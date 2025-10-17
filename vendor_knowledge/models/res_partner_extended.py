from odoo import models, fields, api

class ResPartnerExtended(models.Model):
    _inherit = 'res.partner'

    # Vendor classification
    is_vendor_kb = fields.Boolean(string='Include in Knowledge Base', default=False)
    
    # Knowledge integration
    knowledge_page_id = fields.Many2one(
        'knowledge.page',
        string='Vendor Knowledge Page',
        ondelete='set null'
    )
    
    # Vendor documents
    vendor_document_ids = fields.One2many(
        'vendor.document',
        'vendor_id',
        string='Vendor Documents'
    )
    
    # Communication history
    vendor_communication_ids = fields.One2many(
        'vendor.communication',
        'vendor_id',
        string='Communications'
    )
    
    # Extended vendor information
    vendor_category = fields.Selection(
        [
            ('supplier', 'Supplier'),
            ('manufacturer', 'Manufacturer'),
            ('distributor', 'Distributor'),
            ('service', 'Service Provider'),
            ('other', 'Other'),
        ],
        string='Vendor Category'
    )
    
    vendor_rating = fields.Selection(
        [
            ('1', 'Poor'),
            ('2', 'Fair'),
            ('3', 'Good'),
            ('4', 'Very Good'),
            ('5', 'Excellent'),
        ],
        string='Vendor Rating'
    )
    
    vendor_notes = fields.Text(string='Vendor Notes')
    
    # Compliance and certifications
    certifications = fields.Text(string='Certifications')
    compliance_status = fields.Selection(
        [
            ('compliant', 'Compliant'),
            ('non_compliant', 'Non-Compliant'),
            ('pending', 'Pending Review'),
        ],
        string='Compliance Status'
    )
    
    # Computed fields for analytics
    total_documents = fields.Integer(
        string='Total Documents',
        compute='_compute_total_documents'
    )
    
    total_communications = fields.Integer(
        string='Total Communications',
        compute='_compute_total_communications'
    )
    
    total_purchase_orders = fields.Integer(
        string='Total Purchase Orders',
        compute='_compute_total_purchase_orders'
    )
    
    total_spent = fields.Float(
        string='Total Amount Spent',
        compute='_compute_total_spent'
    )
    
    average_lead_time = fields.Float(
        string='Average Lead Time (days)',
        compute='_compute_average_lead_time'
    )
    
    def _compute_total_documents(self):
        for record in self:
            record.total_documents = len(record.vendor_document_ids)
    
    def _compute_total_communications(self):
        for record in self:
            record.total_communications = len(record.vendor_communication_ids)
    
    def _compute_total_purchase_orders(self):
        for record in self:
            po_count = self.env['purchase.order'].search_count([
                ('partner_id', '=', record.id),
                ('state', 'in', ['purchase', 'done'])
            ])
            record.total_purchase_orders = po_count
    
    def _compute_total_spent(self):
        for record in self:
            total = sum(self.env['purchase.order'].search([
                ('partner_id', '=', record.id),
                ('state', 'in', ['purchase', 'done'])
            ]).mapped('amount_total'))
            record.total_spent = total
    
    def _compute_average_lead_time(self):
        for record in self:
            pos = self.env['purchase.order'].search([
                ('partner_id', '=', record.id),
                ('state', '=', 'done')
            ])
            if pos:
                lead_times = []
                for po in pos:
                    if po.date_order and po.date_approve:
                        lead_times.append((po.date_approve - po.date_order).days)
                record.average_lead_time = sum(lead_times) / len(lead_times) if lead_times else 0
            else:
                record.average_lead_time = 0
