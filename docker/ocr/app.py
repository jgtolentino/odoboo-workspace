#!/usr/bin/env python3
"""
PaddleOCR Receipt/Invoice Processing API
Provides OCR services for Odoo hr.expense integration
"""

import io
import json
import logging
import re
from datetime import datetime
from typing import Dict, List, Optional

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
from PIL import Image
from paddleocr import PaddleOCR
import cv2
import numpy as np

from preprocess import preprocess_image

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI
app = FastAPI(
    title="PaddleOCR Receipt Processing Service",
    description="OCR service for receipt/invoice extraction",
    version="1.0.0"
)

# Initialize PaddleOCR (CPU mode for cost efficiency)
ocr_engine = PaddleOCR(
    use_angle_cls=True,
    lang='en',
    use_gpu=False,
    show_log=False,
    det_model_dir=None,  # Use default
    rec_model_dir=None,  # Use default
    cls_model_dir=None   # Use default
)

# Regex patterns for field extraction
PATTERNS = {
    'total': [
        r'total[:\s]+[$£€]?\s*(\d+[.,]\d{2})',
        r'amount due[:\s]+[$£€]?\s*(\d+[.,]\d{2})',
        r'balance[:\s]+[$£€]?\s*(\d+[.,]\d{2})',
    ],
    'date': [
        r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})',
        r'(\d{4}[/-]\d{1,2}[/-]\d{1,2})',
        r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{1,2},?\s+\d{4}',
    ],
    'merchant': [
        r'^([A-Z][A-Za-z\s&]+)$',  # Capitalized names at start
    ],
    'tax': [
        r'tax[:\s]+[$£€]?\s*(\d+[.,]\d{2})',
        r'vat[:\s]+[$£€]?\s*(\d+[.,]\d{2})',
        r'gst[:\s]+[$£€]?\s*(\d+[.,]\d{2})',
    ],
}


@app.get("/health")
async def health_check():
    """Health check endpoint for monitoring"""
    return {
        "status": "healthy",
        "service": "paddleocr-receipt-service",
        "version": "1.0.0",
        "timestamp": datetime.utcnow().isoformat()
    }


@app.get("/models")
async def list_models():
    """List available OCR models and capabilities"""
    return {
        "models": [
            {
                "name": "PP-OCRv4",
                "language": "en",
                "use_case": "receipts, invoices, documents",
                "gpu": False
            }
        ],
        "features": {
            "angle_classification": True,
            "text_detection": True,
            "text_recognition": True
        }
    }


@app.post("/v1/parse")
async def parse_receipt(file: UploadFile = File(...)):
    """
    Process receipt/invoice image and extract structured data

    Args:
        file: Image file (JPEG, PNG, PDF)

    Returns:
        JSON with extracted fields and confidence scores
    """
    try:
        # Validate file type
        if not file.content_type.startswith('image/'):
            raise HTTPException(
                status_code=400,
                detail=f"Invalid file type: {file.content_type}. Expected image/*"
            )

        # Read image
        contents = await file.read()
        image = Image.open(io.BytesIO(contents))

        # Preprocess image
        processed_img = preprocess_image(image)

        # Convert PIL to numpy array for PaddleOCR
        img_array = np.array(processed_img)

        # Run OCR
        logger.info(f"Processing image: {file.filename}")
        result = ocr_engine.ocr(img_array, cls=True)

        # Extract text lines with confidence scores
        text_lines = []
        confidence_scores = []

        if result and result[0]:
            for line in result[0]:
                text = line[1][0]
                confidence = line[1][1]
                text_lines.append(text)
                confidence_scores.append(confidence)

        # Combine all text for pattern matching
        full_text = '\n'.join(text_lines)

        # Extract structured fields
        extracted_data = extract_fields(full_text, text_lines)

        # Calculate overall confidence (average of all line confidences)
        overall_confidence = sum(confidence_scores) / len(confidence_scores) if confidence_scores else 0.0

        # Response
        response = {
            "success": True,
            "filename": file.filename,
            "confidence": round(overall_confidence, 3),
            "extracted_fields": extracted_data,
            "raw_text": text_lines,
            "line_count": len(text_lines),
            "needs_review": overall_confidence < 0.85,
            "processed_at": datetime.utcnow().isoformat()
        }

        logger.info(f"OCR completed: confidence={overall_confidence:.2f}, fields={len(extracted_data)}")
        return JSONResponse(content=response)

    except Exception as e:
        logger.error(f"OCR processing failed: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"OCR processing failed: {str(e)}")


def extract_fields(full_text: str, lines: List[str]) -> Dict[str, any]:
    """
    Extract structured fields from OCR text using regex patterns

    Args:
        full_text: Combined text from all lines
        lines: Individual text lines

    Returns:
        Dictionary of extracted fields
    """
    fields = {}

    # Extract total amount
    for pattern in PATTERNS['total']:
        match = re.search(pattern, full_text, re.IGNORECASE)
        if match:
            amount_str = match.group(1).replace(',', '')
            try:
                fields['total_amount'] = float(amount_str)
                break
            except ValueError:
                pass

    # Extract date
    for pattern in PATTERNS['date']:
        match = re.search(pattern, full_text, re.IGNORECASE)
        if match:
            fields['date'] = match.group(1)
            break

    # Extract merchant (usually first capitalized line)
    for line in lines[:5]:  # Check first 5 lines
        for pattern in PATTERNS['merchant']:
            match = re.match(pattern, line.strip())
            if match and len(match.group(1)) > 3:  # At least 3 chars
                fields['merchant'] = match.group(1)
                break
        if 'merchant' in fields:
            break

    # Extract tax/VAT
    for pattern in PATTERNS['tax']:
        match = re.search(pattern, full_text, re.IGNORECASE)
        if match:
            tax_str = match.group(1).replace(',', '')
            try:
                fields['tax_amount'] = float(tax_str)
                break
            except ValueError:
                pass

    # Infer currency (default USD)
    currency_symbols = {
        '$': 'USD',
        '£': 'GBP',
        '€': 'EUR',
        '¥': 'JPY',
        '₹': 'INR'
    }

    for symbol, code in currency_symbols.items():
        if symbol in full_text:
            fields['currency'] = code
            break

    if 'currency' not in fields:
        fields['currency'] = 'USD'  # Default

    return fields


@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """Global exception handler for unhandled errors"""
    logger.error(f"Unhandled exception: {str(exc)}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={
            "success": False,
            "error": "Internal server error",
            "detail": str(exc)
        }
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, workers=2)
