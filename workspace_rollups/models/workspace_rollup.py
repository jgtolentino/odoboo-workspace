from odoo import models, fields, api

class WorkspaceRollup(models.Model):
    _name = 'workspace.rollup'
    _description = 'Workspace Rollup Configuration'
    _order = 'sequence, name'

    name = fields.Char(string='Rollup Name', required=True)
    description = fields.Text(string='Description')
    
    # Rollup configuration
    rollup_type = fields.Selection(
        [
            ('sum', 'Sum'),
            ('count', 'Count'),
            ('average', 'Average'),
            ('max', 'Maximum'),
            ('min', 'Minimum'),
            ('concatenate', 'Concatenate'),
        ],
        string='Rollup Type',
        required=True
    )
    
    source_model = fields.Selection(
        [
            ('knowledge.page', 'Knowledge Page'),
            ('hr.expense', 'HR Expense'),
            ('project.task', 'Project Task'),
            ('account.move', 'Invoice'),
            ('res.partner', 'Vendor'),
        ],
        string='Source Model',
        required=True
    )
    
    source_field = fields.Char(
        string='Source Field',
        required=True,
        help='Field name to aggregate (e.g., total_amount, amount_total)'
    )
    
    filter_domain = fields.Char(
        string='Filter Domain',
        help='Optional domain filter as Python list (e.g., [("state", "=", "done")])'
    )
    
    # Grouping
    group_by_field = fields.Char(
        string='Group By Field',
        help='Optional field to group results by'
    )
    
    # Metadata
    sequence = fields.Integer(string='Sequence', default=10)
    is_active = fields.Boolean(string='Active', default=True)
    
    # Computed result
    rollup_result = fields.Char(
        string='Rollup Result',
        compute='_compute_rollup_result',
        help='Result of the rollup calculation'
    )
    
    def _compute_rollup_result(self):
        for record in self:
            try:
                model = self.env[record.source_model]
                
                # Build domain
                domain = []
                if record.filter_domain:
                    domain = eval(record.filter_domain)
                
                records = model.search(domain)
                
                if not records:
                    record.rollup_result = '0'
                    continue
                
                values = records.mapped(record.source_field)
                
                if record.rollup_type == 'sum':
                    result = sum(values)
                elif record.rollup_type == 'count':
                    result = len(values)
                elif record.rollup_type == 'average':
                    result = sum(values) / len(values) if values else 0
                elif record.rollup_type == 'max':
                    result = max(values) if values else 0
                elif record.rollup_type == 'min':
                    result = min(values) if values else 0
                elif record.rollup_type == 'concatenate':
                    result = ', '.join(str(v) for v in values)
                else:
                    result = 0
                
                record.rollup_result = str(result)
            except Exception as e:
                record.rollup_result = f'Error: {str(e)}'
