{
    'name': 'Workspace Dashboard',
    'version': '16.0.1.0.0',
    'category': 'Tools',
    'summary': 'Unified dashboard and workspace views for all modules',
    'description': """
        Workspace dashboard module providing:
        - Unified dashboard with all workspace metrics
        - Quick access to all modules
        - Recent activity tracking
        - Customizable workspace views
        - Workspace-wide search and navigation
        - Personal workspace preferences
    """,
    'author': 'OCA Community',
    'website': 'https://github.com/oca',
    'depends': [
        'knowledge_workspace',
        'hr_expense_documents',
        'project_workspace',
        'invoice_knowledge',
        'vendor_knowledge',
        'workspace_rollups',
        'web',
    ],
    'data': [
        'security/ir.model.access.csv',
        'views/workspace_dashboard_views.xml',
        'views/workspace_activity_views.xml',
        'views/workspace_preferences_views.xml',
        'views/workspace_menu.xml',
    ],
    'assets': {
        'web.assets_backend': [
            'workspace_dashboard/static/src/css/dashboard.css',
        ],
    },
    'installable': True,
    'license': 'AGPL-3',
}
