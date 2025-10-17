{
    'name': 'Vendor Knowledge Base',
    'version': '16.0.1.0.0',
    'category': 'Purchasing',
    'summary': 'Centralized vendor information and knowledge management',
    'description': """
        Vendor knowledge base module with:
        - Vendor profiles with extended information
        - Vendor documents (contracts, agreements, certifications)
        - Communication history and notes
        - Vendor performance metrics
        - Knowledge pages linked to vendors
        - Computed fields for vendor analytics
    """,
    'author': 'OCA Community',
    'website': 'https://github.com/oca',
    'depends': [
        'purchase',
        'knowledge_workspace',
    ],
    'data': [
        'security/ir.model.access.csv',
        'views/res_partner_views.xml',
        'views/vendor_document_views.xml',
        'views/vendor_communication_views.xml',
    ],
    'installable': True,
    'license': 'AGPL-3',
}
