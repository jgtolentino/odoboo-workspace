from odoo import models, fields

class ExpenseCategory(models.Model):
    _name = 'expense.category'
    _description = 'Expense Category'
    _order = 'sequence, name'

    name = fields.Char(string='Category Name', required=True)
    description = fields.Text(string='Description')
    code = fields.Char(string='Code', required=True)
    
    expense_ids = fields.One2many(
        'hr.expense',
        'expense_category_id',
        string='Expenses'
    )
    
    total_expenses = fields.Float(
        string='Total Expenses',
        compute='_compute_total_expenses'
    )
    
    expense_count = fields.Integer(
        string='Expense Count',
        compute='_compute_expense_count'
    )
    
    sequence = fields.Integer(string='Sequence', default=10)
    
    def _compute_total_expenses(self):
        for record in self:
            record.total_expenses = sum(record.expense_ids.mapped('total_amount'))
    
    def _compute_expense_count(self):
        for record in self:
            record.expense_count = len(record.expense_ids)
