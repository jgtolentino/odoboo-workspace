# -*- coding: utf-8 -*-
import logging
from odoo import models, api

_logger = logging.getLogger(__name__)

class ProjectProject(models.Model):
    _inherit = 'project.project'
    
    @api.model
    def sync_to_supabase(self):
        """Sync all projects to Supabase"""
        client = self.env['supabase.sync'].get_supabase_client()
        
        projects = self.search([])
        synced_count = 0
        
        for project in projects:
            try:
                data = {
                    'odoo_id': project.id,
                    'name': project.name or '',
                    'partner_id': project.partner_id.id if project.partner_id else None,
                    'user_id': project.user_id.id if project.user_id else None,
                    'date_start': str(project.date_start) if project.date_start else None,
                    'date': str(project.date) if project.date else None,
                    'active': project.active,
                }
                
                client.table('project_project').upsert(data, on_conflict='odoo_id').execute()
                synced_count += 1
                
            except Exception as e:
                _logger.error(f"Error syncing project {project.id}: {e}")
                continue
        
        _logger.info(f"Synced {synced_count}/{len(projects)} projects to Supabase")
        return synced_count
