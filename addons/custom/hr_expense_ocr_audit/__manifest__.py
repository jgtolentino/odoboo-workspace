# -*- coding: utf-8 -*-
{
    'name': 'HR Expense OCR Integration',
    'version': '18.0.1.0.0',
    'category': 'Human Resources/Expenses',
    'summary': 'Receipt/Invoice OCR processing with PaddleOCR',
    'description': """
HR Expense OCR Integration
===========================

Automated receipt and invoice processing using PaddleOCR:

Features:
- Automatic OCR processing on image attachment
- Confidence-based review workflow (>85% auto-approved)
- Manual "Process with OCR" button
- Review queue dashboard for low-confidence results
- Field extraction: merchant, amount, date, tax, currency

Technical Stack:
- PaddleOCR PP-OCRv4 engine
- FastAPI OCR microservice
- Image preprocessing pipeline
- Confidence scoring and validation
    """,
    'author': 'InsightPulse AI',
    'website': 'https://insightpulseai.net',
    'license': 'LGPL-3',
    'depends': [
        'base',
        'hr_expense',
        'mail',
    ],
    'data': [
        'data/sequence.xml',
        'security/ir.model.access.csv',
        'views/expense_views.xml',
        'views/expense_ocr_views.xml',
        'views/menus.xml',
    ],
    'demo': [],
    'installable': True,
    'application': False,
    'auto_install': False,
}
