{
    'name': 'Project Workspace',
    'version': '16.0.1.0.0',
    'category': 'Project Management',
    'summary': 'Project management with kanban boards, wiki, and task tracking',
    'description': """
        Project management module with:
        - Kanban board views for task management
        - Project wiki and documentation
        - Task dependencies and progress tracking
        - Team collaboration features
        - Computed fields for project metrics
    """,
    'author': 'OCA Community',
    'website': 'https://github.com/oca',
    'depends': [
        'project',
        'knowledge_workspace',
    ],
    'data': [
        'security/ir.model.access.csv',
        'views/project_views.xml',
        'views/project_task_views.xml',
        'views/project_wiki_views.xml',
        'views/project_menu.xml',
    ],
    'installable': True,
    'license': 'AGPL-3',
}
