# -*- coding: utf-8 -*-
import io
import json
import logging
from typing import Dict, Any, Optional
from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.responses import JSONResponse
from PIL import Image
import numpy as np

from .ocr_engine import OCREngine
from .diff_engine import DiffEngine
from .models import OCRResponse, ComparisonResponse

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="PaddleOCR-VL Expense OCR Service",
    description="Document-aware OCR and visual diff for Odoo expense management",
    version="1.0.0",
)

# Initialize engines
ocr_engine = OCREngine()
diff_engine = DiffEngine()


@app.on_event("startup")
async def startup_event():
    """Initialize OCR engine on startup."""
    logger.info("Starting OCR service...")
    await ocr_engine.initialize()
    logger.info("OCR service ready")


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "ok",
        "service": "ocr-service",
        "model_loaded": ocr_engine.is_ready(),
    }


@app.post("/ocr", response_model=OCRResponse)
async def process_ocr(
    file: UploadFile = File(...),
    expense_id: Optional[int] = Form(None),
    employee_id: Optional[int] = Form(None),
    company_id: Optional[int] = Form(None),
):
    """
    Process expense document through PaddleOCR-VL.

    Args:
        file: Image file (JPEG, PNG, PDF)
        expense_id: Optional Odoo expense ID
        employee_id: Optional Odoo employee ID
        company_id: Optional Odoo company ID

    Returns:
        OCRResponse with extracted fields and confidence scores
    """
    try:
        # Read and validate image
        contents = await file.read()
        image = Image.open(io.BytesIO(contents))

        logger.info(
            f"Processing OCR for expense_id={expense_id}, "
            f"image_size={image.size}, format={image.format}"
        )

        # Run OCR
        ocr_result = await ocr_engine.extract_text(image)

        # Extract structured fields
        extracted_fields = await ocr_engine.extract_expense_fields(ocr_result)

        # Calculate average confidence
        confidence = ocr_result.get("average_confidence", 0.0)

        response = OCRResponse(
            confidence=confidence,
            extracted_fields=extracted_fields,
            text_regions=ocr_result.get("text_regions", []),
            layout_analysis=ocr_result.get("layout_analysis", {}),
            raw_text=ocr_result.get("raw_text", ""),
        )

        logger.info(
            f"OCR completed for expense_id={expense_id}, "
            f"confidence={confidence:.2f}, "
            f"amount={extracted_fields.get('total_amount')}"
        )

        return response

    except Exception as e:
        logger.error(f"OCR processing failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"OCR processing failed: {str(e)}")


@app.post("/compare", response_model=ComparisonResponse)
async def compare_documents(
    current_file: UploadFile = File(...),
    original_ocr_data: str = Form(...),
    expense_id: Optional[int] = Form(None),
):
    """
    Compare current document with original OCR extraction.

    Args:
        current_file: Current document image
        original_ocr_data: JSON string of original OCR extraction
        expense_id: Optional Odoo expense ID

    Returns:
        ComparisonResponse with visual similarity and JSON diff
    """
    try:
        # Read and validate current image
        contents = await current_file.read()
        current_image = Image.open(io.BytesIO(contents))

        logger.info(
            f"Starting document comparison for expense_id={expense_id}, "
            f"image_size={current_image.size}"
        )

        # Parse original OCR data
        try:
            original_data = json.loads(original_ocr_data)
        except json.JSONDecodeError as e:
            raise HTTPException(
                status_code=400, detail=f"Invalid original_ocr_data JSON: {str(e)}"
            )

        # Run OCR on current document
        current_ocr_result = await ocr_engine.extract_text(current_image)
        current_fields = await ocr_engine.extract_expense_fields(current_ocr_result)

        # Extract original fields
        original_ocr_payload = json.loads(original_data) if isinstance(original_data, str) else original_data
        original_fields = original_ocr_payload.get("extracted_fields", {})

        # Calculate visual similarity (SSIM)
        # Note: We need the original image for true visual comparison
        # For now, use field-based comparison
        visual_similarity = diff_engine.calculate_field_similarity(
            original_fields, current_fields
        )

        # Calculate JSON diff
        json_diff = diff_engine.calculate_json_diff(original_fields, current_fields)

        # Detect significant changes
        changes_detected = len(json_diff) > 0 or visual_similarity < 0.95

        response = ComparisonResponse(
            visual_similarity=visual_similarity,
            json_diff=json_diff,
            changes_detected=changes_detected,
        )

        logger.info(
            f"Comparison completed for expense_id={expense_id}, "
            f"similarity={visual_similarity:.4f}, "
            f"changes={changes_detected}"
        )

        return response

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Document comparison failed: {str(e)}")
        raise HTTPException(
            status_code=500, detail=f"Document comparison failed: {str(e)}"
        )


@app.post("/batch_ocr")
async def batch_ocr_processing(files: list[UploadFile] = File(...)):
    """
    Process multiple expense documents in batch.

    Args:
        files: List of image files

    Returns:
        List of OCR results
    """
    results = []

    for idx, file in enumerate(files):
        try:
            contents = await file.read()
            image = Image.open(io.BytesIO(contents))

            ocr_result = await ocr_engine.extract_text(image)
            extracted_fields = await ocr_engine.extract_expense_fields(ocr_result)

            results.append(
                {
                    "file_index": idx,
                    "filename": file.filename,
                    "success": True,
                    "confidence": ocr_result.get("average_confidence", 0.0),
                    "extracted_fields": extracted_fields,
                }
            )

        except Exception as e:
            logger.error(f"Batch OCR failed for file {idx} ({file.filename}): {str(e)}")
            results.append(
                {
                    "file_index": idx,
                    "filename": file.filename,
                    "success": False,
                    "error": str(e),
                }
            )

    return {"total": len(files), "results": results}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
