# -*- coding: utf-8 -*-

import base64
import io
import logging
import requests
from datetime import datetime

from odoo import models, fields, api
from odoo.exceptions import UserError

_logger = logging.getLogger(__name__)

OCR_SERVICE_URL = "http://ocr-service:8000"


class ExpenseOCR(models.Model):
    _name = 'hr.expense.ocr'
    _description = 'OCR Processing Result for Expenses'
    _order = 'create_date desc'

    name = fields.Char('Reference', required=True, default='New')
    expense_id = fields.Many2one('hr.expense', string='Expense', ondelete='cascade')
    image_data = fields.Binary('Receipt Image', attachment=True)
    image_filename = fields.Char('Filename')

    # OCR Results
    ocr_success = fields.Boolean('OCR Success', default=False)
    confidence = fields.Float('Confidence Score', digits=(3, 3), help="Overall OCR confidence (0.0 - 1.0)")
    raw_text = fields.Text('Raw OCR Text')
    extracted_data = fields.Text('Extracted Fields (JSON)')

    # Extracted Fields
    merchant_name = fields.Char('Merchant Name')
    total_amount = fields.Float('Total Amount', digits='Product Price')
    currency_code = fields.Char('Currency Code', default='USD')
    receipt_date = fields.Date('Receipt Date')
    tax_amount = fields.Float('Tax Amount', digits='Product Price')

    # Status
    state = fields.Selection([
        ('draft', 'Draft'),
        ('processing', 'Processing'),
        ('done', 'Done'),
        ('failed', 'Failed'),
        ('review', 'Needs Review'),
    ], string='Status', default='draft', required=True)

    needs_review = fields.Boolean('Needs Manual Review', default=False,
                                    help="Low confidence (<85%) requires human verification")

    error_message = fields.Text('Error Message')

    @api.model
    def create(self, vals):
        if vals.get('name', 'New') == 'New':
            vals['name'] = self.env['ir.sequence'].next_by_code('hr.expense.ocr') or 'New'
        return super(ExpenseOCR, self).create(vals)

    def process_image(self):
        """
        Send image to OCR service and process results
        """
        self.ensure_one()

        if not self.image_data:
            raise UserError("No image data to process.")

        self.write({'state': 'processing'})

        try:
            # Prepare image for API call
            image_bytes = base64.b64decode(self.image_data)

            # Call OCR service
            _logger.info(f"Processing OCR for expense OCR #{self.id}")
            response = requests.post(
                f"{OCR_SERVICE_URL}/v1/parse",
                files={'file': (self.image_filename or 'receipt.jpg', io.BytesIO(image_bytes), 'image/jpeg')},
                timeout=30
            )

            if response.status_code == 200:
                result = response.json()
                self._process_ocr_result(result)
            else:
                error_msg = f"OCR service returned {response.status_code}: {response.text}"
                _logger.error(error_msg)
                self.write({
                    'state': 'failed',
                    'error_message': error_msg
                })
                raise UserError(f"OCR processing failed: {error_msg}")

        except requests.exceptions.RequestException as e:
            error_msg = f"OCR service connection failed: {str(e)}"
            _logger.error(error_msg, exc_info=True)
            self.write({
                'state': 'failed',
                'error_message': error_msg
            })
            raise UserError(error_msg)

        except Exception as e:
            error_msg = f"Unexpected error during OCR processing: {str(e)}"
            _logger.error(error_msg, exc_info=True)
            self.write({
                'state': 'failed',
                'error_message': error_msg
            })
            raise UserError(error_msg)

    def _process_ocr_result(self, result):
        """
        Process OCR service JSON response and extract fields

        Args:
            result: JSON dict from OCR service
        """
        self.ensure_one()

        if not result.get('success'):
            self.write({
                'state': 'failed',
                'error_message': result.get('error', 'Unknown error')
            })
            return

        # Extract fields
        extracted = result.get('extracted_fields', {})
        confidence = result.get('confidence', 0.0)
        needs_review = result.get('needs_review', False)

        # Parse date if available
        receipt_date = None
        if extracted.get('date'):
            try:
                receipt_date = datetime.strptime(extracted['date'], '%m/%d/%Y').date()
            except ValueError:
                try:
                    receipt_date = datetime.strptime(extracted['date'], '%Y-%m-%d').date()
                except ValueError:
                    _logger.warning(f"Could not parse date: {extracted.get('date')}")

        # Update record
        vals = {
            'ocr_success': True,
            'confidence': confidence,
            'raw_text': '\n'.join(result.get('raw_text', [])),
            'extracted_data': str(extracted),
            'merchant_name': extracted.get('merchant', ''),
            'total_amount': extracted.get('total_amount', 0.0),
            'currency_code': extracted.get('currency', 'USD'),
            'receipt_date': receipt_date,
            'tax_amount': extracted.get('tax_amount', 0.0),
            'needs_review': needs_review,
            'state': 'review' if needs_review else 'done'
        }

        self.write(vals)

        # Auto-create expense if confidence is high
        if not needs_review and not self.expense_id:
            self._create_expense_from_ocr()

        _logger.info(f"OCR completed: ID={self.id}, confidence={confidence:.2f}, review={needs_review}")

    def _create_expense_from_ocr(self):
        """
        Create hr.expense record from OCR results
        """
        self.ensure_one()

        if self.expense_id:
            _logger.warning(f"Expense already exists for OCR #{self.id}")
            return

        expense_vals = {
            'name': self.merchant_name or 'Receipt',
            'total_amount': self.total_amount,
            'date': self.receipt_date or fields.Date.today(),
            'employee_id': self.env.user.employee_id.id,
            'ocr_confidence': self.confidence,
        }

        # Create expense
        expense = self.env['hr.expense'].create(expense_vals)

        # Link OCR record to expense
        self.expense_id = expense.id

        # Attach image to expense
        if self.image_data:
            self.env['ir.attachment'].create({
                'name': self.image_filename or 'receipt.jpg',
                'res_model': 'hr.expense',
                'res_id': expense.id,
                'type': 'binary',
                'datas': self.image_data,
            })

        _logger.info(f"Created expense #{expense.id} from OCR #{self.id}")
        return expense

    def action_approve_and_create_expense(self):
        """
        Manual approval button for review queue
        """
        self.ensure_one()
        if not self.expense_id:
            self._create_expense_from_ocr()
        self.write({'state': 'done', 'needs_review': False})
        return {
            'type': 'ir.actions.act_window',
            'res_model': 'hr.expense',
            'res_id': self.expense_id.id,
            'view_mode': 'form',
            'target': 'current',
        }
