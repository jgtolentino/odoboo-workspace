# -*- coding: utf-8 -*-

import base64
import json
import logging

from odoo import http
from odoo.http import request

_logger = logging.getLogger(__name__)


class ExpenseOCRController(http.Controller):

    @http.route('/api/expense/ocr/upload', type='http', auth='user', methods=['POST'], csrf=False)
    def upload_receipt(self, **post):
        """
        Upload receipt image for OCR processing

        POST data:
            - file: image file (multipart)
            - employee_id: optional employee ID

        Returns:
            JSON with OCR result and expense ID
        """
        try:
            # Get uploaded file
            uploaded_file = post.get('file')
            if not uploaded_file:
                return request.make_json_response({
                    'success': False,
                    'error': 'No file uploaded'
                }, status=400)

            # Read file data
            file_data = uploaded_file.read()
            filename = uploaded_file.filename
            file_base64 = base64.b64encode(file_data).decode('utf-8')

            # Get employee (default to current user's employee)
            employee_id = post.get('employee_id')
            if not employee_id:
                employee_id = request.env.user.employee_id.id

            if not employee_id:
                return request.make_json_response({
                    'success': False,
                    'error': 'No employee associated with user'
                }, status=400)

            # Create OCR record
            ocr_record = request.env['hr.expense.ocr'].sudo().create({
                'image_data': file_base64,
                'image_filename': filename,
            })

            # Process OCR
            ocr_record.sudo().process_image()

            # Prepare response
            response_data = {
                'success': True,
                'ocr_id': ocr_record.id,
                'confidence': ocr_record.confidence,
                'needs_review': ocr_record.needs_review,
                'extracted_fields': {
                    'merchant': ocr_record.merchant_name,
                    'total_amount': ocr_record.total_amount,
                    'currency': ocr_record.currency_code,
                    'date': ocr_record.receipt_date.isoformat() if ocr_record.receipt_date else None,
                    'tax_amount': ocr_record.tax_amount,
                },
                'state': ocr_record.state,
            }

            # If expense was auto-created, include expense ID
            if ocr_record.expense_id:
                response_data['expense_id'] = ocr_record.expense_id.id
                response_data['expense_reference'] = ocr_record.expense_id.name

            return request.make_json_response(response_data)

        except Exception as e:
            _logger.error(f"Receipt upload failed: {str(e)}", exc_info=True)
            return request.make_json_response({
                'success': False,
                'error': str(e)
            }, status=500)

    @http.route('/api/expense/ocr/status/<int:ocr_id>', type='json', auth='user', methods=['GET'])
    def get_ocr_status(self, ocr_id):
        """
        Get OCR processing status

        Args:
            ocr_id: hr.expense.ocr record ID

        Returns:
            JSON with OCR status
        """
        try:
            ocr_record = request.env['hr.expense.ocr'].sudo().browse(ocr_id)

            if not ocr_record.exists():
                return {
                    'success': False,
                    'error': 'OCR record not found'
                }

            return {
                'success': True,
                'ocr_id': ocr_record.id,
                'state': ocr_record.state,
                'confidence': ocr_record.confidence,
                'needs_review': ocr_record.needs_review,
                'expense_id': ocr_record.expense_id.id if ocr_record.expense_id else None,
            }

        except Exception as e:
            _logger.error(f"Get OCR status failed: {str(e)}", exc_info=True)
            return {
                'success': False,
                'error': str(e)
            }
