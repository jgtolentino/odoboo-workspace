# -*- coding: utf-8 -*-
{
    'name': 'Supabase Synchronization',
    'version': '18.0.1.0.0',
    'category': 'Technical',
    'summary': 'Bi-directional sync between Odoo and Supabase PostgreSQL',
    'description': """
        Supabase Integration for Odoo
        ===============================
        
        Features:
        ---------
        * Real-time synchronization with Supabase
        * Direct PostgreSQL connection to Supabase database
        * Sync customers, projects, tasks, and invoices
        * Email notifications via Supabase
        * Realtime subscriptions for live updates
        
        Configuration:
        -------------
        Set environment variables in docker-compose.yml or .env file
    """,
    'author': 'Your Company',
    'website': 'https://yourcompany.com',
    'depends': [
        'base',
        'mail',
        'project',
        'sale',
        'stock',
    ],
    'data': [
        'security/ir.model.access.csv',
        'views/supabase_config_views.xml',
        'data/cron_jobs.xml',
    ],
    'installable': True,
    'application': True,
    'auto_install': False,
    'license': 'LGPL-3',
}
