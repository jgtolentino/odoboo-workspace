from odoo import models, fields, api

class ProjectExtended(models.Model):
    _inherit = 'project.project'

    # Wiki integration
    wiki_page_id = fields.Many2one(
        'knowledge.page',
        string='Project Wiki',
        ondelete='set null'
    )
    
    # Project metadata
    project_color = fields.Integer(string='Color Index', default=0)
    project_icon = fields.Char(string='Icon', default='fa-project-diagram')
    
    # Team collaboration
    team_member_ids = fields.Many2many(
        'res.users',
        string='Team Members'
    )
    
    # Computed fields for metrics
    total_tasks = fields.Integer(
        string='Total Tasks',
        compute='_compute_total_tasks'
    )
    
    completed_tasks = fields.Integer(
        string='Completed Tasks',
        compute='_compute_completed_tasks'
    )
    
    project_progress = fields.Float(
        string='Progress %',
        compute='_compute_project_progress'
    )
    
    overdue_tasks = fields.Integer(
        string='Overdue Tasks',
        compute='_compute_overdue_tasks'
    )
    
    def _compute_total_tasks(self):
        for record in self:
            record.total_tasks = len(record.task_ids)
    
    def _compute_completed_tasks(self):
        for record in self:
            record.completed_tasks = len(record.task_ids.filtered(lambda t: t.state == 'done'))
    
    def _compute_project_progress(self):
        for record in self:
            if record.total_tasks > 0:
                record.project_progress = (record.completed_tasks / record.total_tasks) * 100
            else:
                record.project_progress = 0
    
    def _compute_overdue_tasks(self):
        from datetime import datetime
        for record in self:
            record.overdue_tasks = len(record.task_ids.filtered(
                lambda t: t.date_deadline and t.date_deadline < datetime.now().date() and t.state != 'done'
            ))
