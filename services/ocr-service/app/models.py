# -*- coding: utf-8 -*-
from typing import Dict, List, Any, Optional
from pydantic import BaseModel, Field


class ExtractedFields(BaseModel):
    """Structured expense fields extracted from OCR."""

    total_amount: Optional[float] = Field(None, description="Total expense amount")
    date: Optional[str] = Field(None, description="Expense date (YYYY-MM-DD)")
    vendor: Optional[str] = Field(None, description="Vendor/merchant name")
    description: Optional[str] = Field(None, description="Expense description")
    tax_amount: Optional[float] = Field(None, description="Tax amount")
    currency: Optional[str] = Field(None, description="Currency code (USD, EUR, etc.)")
    payment_method: Optional[str] = Field(
        None, description="Payment method (Cash, Credit Card, etc.)"
    )


class OCRResponse(BaseModel):
    """OCR processing response."""

    confidence: float = Field(..., description="Average OCR confidence score (0-1)")
    extracted_fields: ExtractedFields = Field(..., description="Extracted expense fields")
    text_regions: List[Dict[str, Any]] = Field(
        default_factory=list, description="Detected text regions with bounding boxes"
    )
    layout_analysis: Dict[str, Any] = Field(
        default_factory=dict, description="Document layout analysis"
    )
    raw_text: str = Field(default="", description="Raw extracted text")


class ComparisonResponse(BaseModel):
    """Document comparison response."""

    visual_similarity: float = Field(
        ..., description="Visual similarity score (0-1, higher is more similar)"
    )
    json_diff: Dict[str, Any] = Field(
        default_factory=dict, description="JSON diff of extracted fields"
    )
    changes_detected: bool = Field(..., description="Whether significant changes detected")
