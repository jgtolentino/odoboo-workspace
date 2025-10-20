# -*- coding: utf-8 -*-
import logging
from odoo import models, api

_logger = logging.getLogger(__name__)

class ProjectTask(models.Model):
    _inherit = 'project.task'
    
    @api.model
    def sync_to_supabase(self):
        """Sync all tasks to Supabase"""
        client = self.env['supabase.sync'].get_supabase_client()
        
        tasks = self.search([])
        synced_count = 0
        
        for task in tasks:
            try:
                data = {
                    'odoo_id': task.id,
                    'name': task.name or '',
                    'project_id': task.project_id.id if task.project_id else None,
                    'user_ids': [u.id for u in task.user_ids],
                    'stage_id': task.stage_id.id if task.stage_id else None,
                    'priority': task.priority or '0',
                    'date_deadline': str(task.date_deadline) if task.date_deadline else None,
                    'description': task.description or '',
                }
                
                client.table('project_task').upsert(data, on_conflict='odoo_id').execute()
                synced_count += 1
                
            except Exception as e:
                _logger.error(f"Error syncing task {task.id}: {e}")
                continue
        
        _logger.info(f"Synced {synced_count}/{len(tasks)} tasks to Supabase")
        return synced_count
