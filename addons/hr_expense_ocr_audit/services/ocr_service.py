# -*- coding: utf-8 -*-
import base64
import json
import logging
import requests
from io import BytesIO
from PIL import Image
from odoo import models, api, _
from odoo.exceptions import UserError

_logger = logging.getLogger(__name__)


class HrExpenseOCRService(models.AbstractModel):
    _name = "hr.expense.ocr.service"
    _description = "HR Expense OCR Service Integration"

    @api.model
    def _get_ocr_api_url(self):
        """Get OCR API endpoint from system parameters."""
        return (
            self.env["ir.config_parameter"]
            .sudo()
            .get_param(
                "hr_expense_ocr_audit.ocr_api_url",
                default="http://localhost:8000/ocr",
            )
        )

    @api.model
    def _get_ocr_api_key(self):
        """Get OCR API key from system parameters."""
        return (
            self.env["ir.config_parameter"]
            .sudo()
            .get_param("hr_expense_ocr_audit.ocr_api_key", default="")
        )

    def process_expense_document(self, expense):
        """
        Process expense document through PaddleOCR-VL API.

        Args:
            expense: hr.expense record

        Returns:
            dict: OCR result with extracted data and confidence scores
        """
        if not expense.attachment_ids:
            raise UserError(_("No document attached to expense."))

        # Get first attachment (receipt/invoice image)
        attachment = expense.attachment_ids[0]

        # Prepare image data
        image_data = base64.b64decode(attachment.datas)

        # Validate image
        try:
            img = Image.open(BytesIO(image_data))
            _logger.info(
                f"Processing image for expense {expense.id}: {img.size}, {img.format}"
            )
        except Exception as e:
            raise UserError(_("Invalid image file: %s") % str(e))

        # Call OCR API
        api_url = self._get_ocr_api_url()
        api_key = self._get_ocr_api_key()

        headers = {}
        if api_key:
            headers["Authorization"] = f"Bearer {api_key}"

        try:
            # Prepare multipart form data
            files = {
                "file": (
                    attachment.name,
                    BytesIO(image_data),
                    attachment.mimetype or "image/jpeg",
                )
            }

            # Add metadata
            data = {
                "expense_id": expense.id,
                "employee_id": expense.employee_id.id,
                "company_id": expense.company_id.id,
            }

            _logger.info(f"Calling OCR API: {api_url}")
            response = requests.post(
                api_url, headers=headers, files=files, data=data, timeout=60
            )

            response.raise_for_status()
            result = response.json()

            _logger.info(f"OCR API response for expense {expense.id}: {result}")

            # Parse OCR result
            ocr_data = self._parse_ocr_response(result)

            return {
                "ocr_data": ocr_data,
                "confidence": ocr_data.get("confidence", 0.0),
                "raw_response": result,
            }

        except requests.exceptions.RequestException as e:
            _logger.error(f"OCR API request failed: {str(e)}")
            raise UserError(_("OCR service unavailable: %s") % str(e))
        except Exception as e:
            _logger.error(f"OCR processing error: {str(e)}")
            raise UserError(_("OCR processing failed: %s") % str(e))

    def compare_expense_documents(self, expense):
        """
        Compare current expense document with original version.

        Args:
            expense: hr.expense record

        Returns:
            dict: Comparison result with visual similarity and JSON diff
        """
        if not expense.attachment_ids:
            raise UserError(_("No current document attached to expense."))

        if not expense.original_ocr_payload:
            raise UserError(_("No original OCR data available for comparison."))

        # Get current attachment
        attachment = expense.attachment_ids[0]
        image_data = base64.b64decode(attachment.datas)

        # Call comparison API
        api_url = self._get_ocr_api_url().replace("/ocr", "/compare")
        api_key = self._get_ocr_api_key()

        headers = {}
        if api_key:
            headers["Authorization"] = f"Bearer {api_key}"

        try:
            # Prepare request
            files = {
                "current_file": (
                    attachment.name,
                    BytesIO(image_data),
                    attachment.mimetype or "image/jpeg",
                )
            }

            data = {
                "expense_id": expense.id,
                "original_ocr_data": expense.original_ocr_payload,
            }

            _logger.info(f"Calling comparison API: {api_url}")
            response = requests.post(
                api_url, headers=headers, files=files, data=data, timeout=90
            )

            response.raise_for_status()
            result = response.json()

            _logger.info(f"Comparison API response for expense {expense.id}: {result}")

            return {
                "visual_similarity": result.get("visual_similarity", 1.0),
                "json_diff": result.get("json_diff", {}),
                "changes_detected": result.get("changes_detected", False),
                "raw_response": result,
            }

        except requests.exceptions.RequestException as e:
            _logger.error(f"Comparison API request failed: {str(e)}")
            raise UserError(_("Comparison service unavailable: %s") % str(e))
        except Exception as e:
            _logger.error(f"Comparison processing error: {str(e)}")
            raise UserError(_("Document comparison failed: %s") % str(e))

    def _parse_ocr_response(self, response):
        """
        Parse OCR API response into standardized format.

        Args:
            response: dict from OCR API

        Returns:
            dict: Standardized OCR data
        """
        # Extract fields from PaddleOCR-VL response
        extracted = response.get("extracted_fields", {})

        return {
            "confidence": response.get("confidence", 0.0),
            "extracted_fields": {
                "total_amount": extracted.get("total_amount"),
                "date": extracted.get("date"),
                "vendor": extracted.get("vendor"),
                "description": extracted.get("description"),
                "tax_amount": extracted.get("tax_amount"),
                "currency": extracted.get("currency"),
                "payment_method": extracted.get("payment_method"),
            },
            "text_regions": response.get("text_regions", []),
            "layout_analysis": response.get("layout_analysis", {}),
            "raw_text": response.get("raw_text", ""),
        }
