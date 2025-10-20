# -*- coding: utf-8 -*-
from odoo import models, api, _
from odoo.exceptions import UserError
import requests
import base64


class HrExpense(models.Model):
    """Extend hr.expense for OCR integration"""
    _inherit = 'hr.expense'

    def action_scan_receipt_ocr(self):
        """
        Server Action: Scan receipt using odoobo-expert OCR skill

        Triggered by button on expense form
        """
        self.ensure_one()

        # Get OCR service URL from system parameters
        ocr_url = self.env['ir.config_parameter'].sudo().get_param(
            'hr_expense_ocr_audit.ocr_api_url'
        )
        min_confidence = float(
            self.env['ir.config_parameter'].sudo().get_param(
                'odoobo.ocr_min_confidence', '0.6'
            )
        )

        if not ocr_url:
            raise UserError(_(
                "OCR service not configured. Please set system parameter "
                "'hr_expense_ocr_audit.ocr_api_url'"
            ))

        # Check for attachment
        attachment = self.message_main_attachment_id
        if not attachment:
            raise UserError(_(
                "Please attach a receipt image (JPG, PNG) or PDF before scanning."
            ))

        try:
            # Prepare payload
            payload = {
                "filename": attachment.name,
                "file_base64": base64.b64encode(attachment.raw).decode(),
                "min_confidence": min_confidence,
            }

            # Call OCR service
            response = requests.post(
                f"{ocr_url}/ocr",
                json=payload,
                timeout=60,
            )
            response.raise_for_status()
            data = response.json()

            # Extract fields from OCR response
            merchant = data.get('merchant') or data.get('vendor')
            total_amount = data.get('total') or data.get('amount')
            date = data.get('date')
            category = data.get('category')
            confidence = data.get('confidence', 0.0)

            # Update expense fields
            update_vals = {}

            if merchant and not self.name:
                update_vals['name'] = merchant

            if total_amount:
                update_vals['total_amount'] = float(total_amount)

            if date:
                update_vals['date'] = date

            if update_vals:
                self.write(update_vals)

            # Post OCR results to chatter
            summary = data.get('summary', '')
            confidence_pct = f"{confidence * 100:.1f}%"

            message_body = f"""
            <strong>OCR Scan Complete</strong><br/>
            <ul>
                <li><strong>Merchant:</strong> {merchant or 'Not detected'}</li>
                <li><strong>Amount:</strong> {total_amount or 'Not detected'}</li>
                <li><strong>Date:</strong> {date or 'Not detected'}</li>
                <li><strong>Category:</strong> {category or 'Not detected'}</li>
                <li><strong>Confidence:</strong> {confidence_pct}</li>
            </ul>
            <p><em>Summary:</em> {summary}</p>
            """

            if confidence < min_confidence:
                message_body += f"""
                <p><strong style="color:orange;">⚠️ Low confidence ({confidence_pct}).
                Please review and correct.</strong></p>
                """

            self.message_post(
                body=message_body,
                message_type='notification',
            )

            return {
                'type': 'ir.actions.client',
                'tag': 'display_notification',
                'params': {
                    'title': 'OCR Complete',
                    'message': f'Receipt scanned with {confidence_pct} confidence',
                    'type': 'success' if confidence >= min_confidence else 'warning',
                    'sticky': False,
                }
            }

        except requests.RequestException as e:
            raise UserError(_(
                f"OCR service error: {str(e)}\n\n"
                "Please check service availability and try again."
            ))
        except Exception as e:
            raise UserError(_(
                f"Unexpected error during OCR: {str(e)}"
            ))
