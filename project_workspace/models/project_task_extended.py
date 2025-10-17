from odoo import models, fields, api
from datetime import datetime, timedelta

class ProjectTaskExtended(models.Model):
    _inherit = 'project.task'

    # Knowledge integration
    knowledge_page_id = fields.Many2one(
        'knowledge.page',
        string='Related Documentation',
        ondelete='set null'
    )
    
    # Task dependencies
    parent_task_id = fields.Many2one(
        'project.task',
        string='Parent Task',
        ondelete='set null'
    )
    
    child_task_ids = fields.One2many(
        'project.task',
        'parent_task_id',
        string='Subtasks'
    )
    
    # Task metadata
    priority_level = fields.Selection(
        [
            ('0', 'Low'),
            ('1', 'Medium'),
            ('2', 'High'),
            ('3', 'Urgent'),
        ],
        string='Priority',
        default='1'
    )
    
    task_color = fields.Integer(string='Color Index', default=0)
    
    # Time tracking
    estimated_hours = fields.Float(string='Estimated Hours')
    actual_hours = fields.Float(string='Actual Hours')
    
    # Computed fields
    is_overdue = fields.Boolean(
        string='Is Overdue',
        compute='_compute_is_overdue'
    )
    
    progress_percentage = fields.Float(
        string='Progress %',
        compute='_compute_progress_percentage'
    )
    
    subtask_count = fields.Integer(
        string='Subtask Count',
        compute='_compute_subtask_count'
    )
    
    completed_subtasks = fields.Integer(
        string='Completed Subtasks',
        compute='_compute_completed_subtasks'
    )
    
    def _compute_is_overdue(self):
        today = datetime.now().date()
        for record in self:
            record.is_overdue = (
                record.date_deadline and 
                record.date_deadline < today and 
                record.state != 'done'
            )
    
    def _compute_progress_percentage(self):
        for record in self:
            if record.subtask_count > 0:
                record.progress_percentage = (record.completed_subtasks / record.subtask_count) * 100
            else:
                record.progress_percentage = 0 if record.state != 'done' else 100
    
    def _compute_subtask_count(self):
        for record in self:
            record.subtask_count = len(record.child_task_ids)
    
    def _compute_completed_subtasks(self):
        for record in self:
            record.completed_subtasks = len(record.child_task_ids.filtered(lambda t: t.state == 'done'))
