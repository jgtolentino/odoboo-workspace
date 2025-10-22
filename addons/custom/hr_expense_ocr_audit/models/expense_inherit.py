# -*- coding: utf-8 -*-

import base64
import logging

from odoo import models, fields, api
from odoo.exceptions import UserError

_logger = logging.getLogger(__name__)


class HrExpenseInherit(models.Model):
    _inherit = 'hr.expense'

    ocr_confidence = fields.Float('OCR Confidence', digits=(3, 3), readonly=True,
                                   help="Confidence score from OCR processing (0.0 - 1.0)")
    ocr_processed = fields.Boolean('OCR Processed', default=False, readonly=True)
    ocr_record_id = fields.Many2one('hr.expense.ocr', string='OCR Record', readonly=True)

    def action_process_with_ocr(self):
        """
        Manual button to trigger OCR processing on attached images
        """
        self.ensure_one()

        # Get attached images
        attachments = self.env['ir.attachment'].search([
            ('res_model', '=', 'hr.expense'),
            ('res_id', '=', self.id),
            ('mimetype', 'in', ['image/jpeg', 'image/png', 'image/jpg'])
        ], limit=1)

        if not attachments:
            raise UserError("No image attachment found. Please attach a receipt image first.")

        attachment = attachments[0]

        # Create OCR record
        ocr_vals = {
            'expense_id': self.id,
            'image_data': attachment.datas,
            'image_filename': attachment.name,
        }

        ocr_record = self.env['hr.expense.ocr'].create(ocr_vals)

        # Process image
        try:
            ocr_record.process_image()

            # Update expense with OCR data if successful
            if ocr_record.state == 'done' and not ocr_record.needs_review:
                self._apply_ocr_data(ocr_record)

            return {
                'type': 'ir.actions.client',
                'tag': 'display_notification',
                'params': {
                    'title': 'OCR Processing Complete',
                    'message': f'Confidence: {ocr_record.confidence:.1%}. Review required: {ocr_record.needs_review}',
                    'type': 'success' if not ocr_record.needs_review else 'warning',
                    'sticky': False,
                }
            }

        except Exception as e:
            _logger.error(f"OCR processing failed for expense #{self.id}: {str(e)}", exc_info=True)
            return {
                'type': 'ir.actions.client',
                'tag': 'display_notification',
                'params': {
                    'title': 'OCR Processing Failed',
                    'message': str(e),
                    'type': 'danger',
                    'sticky': True,
                }
            }

    def _apply_ocr_data(self, ocr_record):
        """
        Apply OCR extracted data to expense record

        Args:
            ocr_record: hr.expense.ocr record
        """
        self.ensure_one()

        update_vals = {
            'ocr_processed': True,
            'ocr_confidence': ocr_record.confidence,
            'ocr_record_id': ocr_record.id,
        }

        # Only update if fields are empty (don't overwrite existing data)
        if not self.name or self.name == 'New Expense':
            update_vals['name'] = ocr_record.merchant_name or 'Receipt'

        if not self.total_amount:
            update_vals['total_amount'] = ocr_record.total_amount

        if not self.date:
            update_vals['date'] = ocr_record.receipt_date or fields.Date.today()

        self.write(update_vals)
        _logger.info(f"Applied OCR data to expense #{self.id}: confidence={ocr_record.confidence:.2f}")

    @api.model_create_multi
    def create(self, vals_list):
        """
        Override create to automatically process OCR if image is attached
        """
        expenses = super(HrExpenseInherit, self).create(vals_list)

        # Auto-process OCR for new expenses with images (optional, can be disabled)
        auto_ocr_enabled = self.env['ir.config_parameter'].sudo().get_param('hr_expense_ocr.auto_process', 'False')

        if auto_ocr_enabled == 'True':
            for expense in expenses:
                try:
                    expense.action_process_with_ocr()
                except Exception as e:
                    _logger.warning(f"Auto-OCR failed for expense #{expense.id}: {str(e)}")

        return expenses
