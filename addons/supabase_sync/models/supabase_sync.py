# -*- coding: utf-8 -*-
import os
import logging
from odoo import models, fields, api
from supabase import create_client, Client

_logger = logging.getLogger(__name__)

class SupabaseSync(models.Model):
    _name = 'supabase.sync'
    _description = 'Supabase Synchronization Configuration'
    
    name = fields.Char('Configuration Name', default='Main Supabase Config', required=True)
    active = fields.Boolean('Active', default=True)
    
    # Supabase Configuration
    supabase_url = fields.Char(
        'Supabase URL',
        default=lambda self: os.getenv('NEXT_PUBLIC_SUPABASE_URL', 'https://spdtwktxdalcfigzeqrz.supabase.co'),
        required=True
    )
    anon_key = fields.Char(
        'Anon Key',
        default=lambda self: os.getenv('NEXT_PUBLIC_SUPABASE_ANON_KEY'),
    )
    service_role_key = fields.Char(
        'Service Role Key',
        default=lambda self: os.getenv('SUPABASE_SERVICE_ROLE_KEY'),
    )
    
    # PostgreSQL Direct Connection
    postgres_host = fields.Char(
        'Postgres Host',
        default=lambda self: os.getenv('POSTGRES_HOST', 'db.spdtwktxdalcfigzeqrz.supabase.co')
    )
    postgres_port = fields.Integer(
        'Postgres Port',
        default=5432
    )
    postgres_database = fields.Char(
        'Database Name',
        default=lambda self: os.getenv('POSTGRES_DATABASE', 'postgres')
    )
    postgres_user = fields.Char(
        'Postgres User',
        default=lambda self: os.getenv('POSTGRES_USER', 'postgres')
    )
    postgres_password = fields.Char(
        'Postgres Password',
        default=lambda self: os.getenv('POSTGRES_PASSWORD')
    )
    
    # Sync Settings
    auto_sync = fields.Boolean('Auto Sync', default=True)
    sync_interval = fields.Integer('Sync Interval (minutes)', default=15)
    last_sync = fields.Datetime('Last Sync', readonly=True)
    
    @api.model
    def get_supabase_client(self):
        """Get authenticated Supabase client"""
        config = self.search([('active', '=', True)], limit=1)
        if not config:
            _logger.warning("No active Supabase configuration found. Creating default...")
            config = self.create({'name': 'Default Config'})
        
        try:
            client: Client = create_client(
                config.supabase_url,
                config.service_role_key or config.anon_key
            )
            return client
        except Exception as e:
            _logger.error(f"Failed to create Supabase client: {e}")
            raise
    
    def action_test_connection(self):
        """Test Supabase connection"""
        self.ensure_one()
        try:
            client = self.get_supabase_client()
            # Test connection by querying a simple table
            result = client.table('res_partner').select("id").limit(1).execute()
            _logger.info("Supabase connection successful!")
            return {
                'type': 'ir.actions.client',
                'tag': 'display_notification',
                'params': {
                    'title': 'Connection Successful',
                    'message': 'Successfully connected to Supabase!',
                    'type': 'success',
                    'sticky': False,
                }
            }
        except Exception as e:
            _logger.error(f"Supabase connection failed: {e}")
            return {
                'type': 'ir.actions.client',
                'tag': 'display_notification',
                'params': {
                    'title': 'Connection Failed',
                    'message': f'Error: {str(e)}',
                    'type': 'danger',
                    'sticky': True,
                }
            }
    
    @api.model
    def sync_all_data(self):
        """Main synchronization method called by cron"""
        _logger.info("Starting Supabase synchronization...")
        
        try:
            # Sync partners/customers
            self.env['res.partner'].sync_to_supabase()
            
            # Sync projects
            self.env['project.project'].sync_to_supabase()
            
            # Sync tasks
            self.env['project.task'].sync_to_supabase()
            
            # Update last sync time
            config = self.search([('active', '=', True)], limit=1)
            if config:
                config.last_sync = fields.Datetime.now()
            
            _logger.info("Supabase synchronization completed successfully")
            
        except Exception as e:
            _logger.error(f"Synchronization failed: {e}")
            raise
