# -*- coding: utf-8 -*-
{
    "name": "HR Expense OCR Audit",
    "version": "18.0.1.0.0",
    "category": "Human Resources/Expenses",
    "summary": "PaddleOCR-VL integration with visual diff for expense document verification",
    "description": """
HR Expense OCR Audit
====================

Document-aware visual diff and OCR pipeline for expense management:

Features:
* PaddleOCR-VL integration for receipt/invoice text extraction
* LPIPS/SSIM visual diff for document comparison
* JSON diff for structured data change detection
* Automated anomaly detection for expense submissions
* Version tracking for document modifications
* Confidence scoring and validation workflows
* Integration with hr.expense module

Technical Stack:
* PaddleOCR-VL-900M for vision-language understanding
* FastAPI microservice for OCR processing
* LPIPS/SSIM for perceptual visual comparison
* jsondiffpatch for structured data diffing
    """,
    "author": "Your Name, Odoo Community Association (OCA)",
    "website": "https://github.com/OCA/hr",
    "license": "AGPL-3",
    "depends": [
        "hr_expense",
        "mail",
    ],
    "external_dependencies": {
        "python": [
            "requests",
            "Pillow",
        ],
    },
    "data": [
        "security/ir.model.access.csv",
        "views/hr_expense_views.xml",
        "views/ocr_audit_log_views.xml",
        "views/ocr_dashboard.xml",
        "data/ir_cron.xml",
    ],
    "assets": {},
    "installable": True,
    "application": False,
    "auto_install": False,
}
