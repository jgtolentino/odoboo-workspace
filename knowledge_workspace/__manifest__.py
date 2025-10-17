{
    'name': 'Knowledge Workspace',
    'version': '16.0.1.0.0',
    'category': 'Knowledge Management',
    'summary': 'Notion-style workspace for document and knowledge management',
    'description': """
        Core knowledge management module providing:
        - Document/page creation and editing
        - Category and tag organization
        - Full-text search
        - Document versioning
        - User permissions and access control
    """,
    'author': 'OCA Community',
    'website': 'https://github.com/oca',
    'depends': [
        'base',
        'web',
        'mail',
    ],
    'data': [
        'security/ir.model.access.csv',
        'views/knowledge_page_views.xml',
        'views/knowledge_category_views.xml',
        'views/knowledge_tag_views.xml',
        'views/knowledge_menu.xml',
    ],
    'installable': True,
    'application': True,
    'license': 'AGPL-3',
}
