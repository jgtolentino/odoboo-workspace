# -*- coding: utf-8 -*-
import re
import logging
from typing import Dict, Any, List
from PIL import Image
import numpy as np
from paddleocr import PaddleOCR

from .models import ExtractedFields

logger = logging.getLogger(__name__)


class OCREngine:
    """PaddleOCR-VL engine for expense document processing."""

    def __init__(self):
        self.ocr = None
        self.ready = False

    async def initialize(self):
        """Initialize PaddleOCR model."""
        try:
            logger.info("Initializing PaddleOCR model...")

            # Initialize PaddleOCR with English language
            self.ocr = PaddleOCR(
                use_angle_cls=True,  # Enable text angle classification
                lang="en",  # English language
                show_log=False,  # Disable verbose logging
                use_gpu=False,  # CPU mode (change to True if GPU available)
            )

            self.ready = True
            logger.info("PaddleOCR model initialized successfully")

        except Exception as e:
            logger.error(f"Failed to initialize PaddleOCR: {str(e)}")
            raise

    def is_ready(self) -> bool:
        """Check if OCR engine is ready."""
        return self.ready and self.ocr is not None

    async def extract_text(self, image: Image.Image) -> Dict[str, Any]:
        """
        Extract text from image using PaddleOCR.

        Args:
            image: PIL Image object

        Returns:
            dict: OCR result with text regions, confidence scores, and raw text
        """
        if not self.is_ready():
            raise RuntimeError("OCR engine not initialized")

        # Convert PIL Image to numpy array
        img_array = np.array(image)

        # Run OCR
        result = self.ocr.ocr(img_array, cls=True)

        # Parse OCR result
        text_regions = []
        raw_text_parts = []
        total_confidence = 0.0
        num_regions = 0

        if result and result[0]:
            for line in result[0]:
                bbox = line[0]  # Bounding box coordinates
                text_info = line[1]  # (text, confidence)
                text = text_info[0]
                confidence = text_info[1]

                text_regions.append(
                    {
                        "bbox": bbox,
                        "text": text,
                        "confidence": confidence,
                    }
                )

                raw_text_parts.append(text)
                total_confidence += confidence
                num_regions += 1

        avg_confidence = total_confidence / num_regions if num_regions > 0 else 0.0
        raw_text = " ".join(raw_text_parts)

        return {
            "text_regions": text_regions,
            "raw_text": raw_text,
            "average_confidence": avg_confidence,
            "layout_analysis": self._analyze_layout(text_regions),
        }

    async def extract_expense_fields(self, ocr_result: Dict[str, Any]) -> ExtractedFields:
        """
        Extract structured expense fields from OCR result.

        Args:
            ocr_result: OCR extraction result

        Returns:
            ExtractedFields: Structured expense data
        """
        raw_text = ocr_result.get("raw_text", "")
        text_regions = ocr_result.get("text_regions", [])

        # Extract total amount
        total_amount = self._extract_amount(raw_text, text_regions)

        # Extract date
        date = self._extract_date(raw_text)

        # Extract vendor/merchant
        vendor = self._extract_vendor(text_regions)

        # Extract description
        description = self._extract_description(raw_text)

        # Extract tax amount
        tax_amount = self._extract_tax(raw_text, text_regions)

        # Extract currency
        currency = self._extract_currency(raw_text)

        # Extract payment method
        payment_method = self._extract_payment_method(raw_text)

        return ExtractedFields(
            total_amount=total_amount,
            date=date,
            vendor=vendor,
            description=description,
            tax_amount=tax_amount,
            currency=currency,
            payment_method=payment_method,
        )

    def _analyze_layout(self, text_regions: List[Dict]) -> Dict[str, Any]:
        """Analyze document layout."""
        if not text_regions:
            return {}

        # Calculate bounding box statistics
        all_y_coords = []
        for region in text_regions:
            bbox = region["bbox"]
            y_coords = [point[1] for point in bbox]
            all_y_coords.extend(y_coords)

        return {
            "num_text_regions": len(text_regions),
            "avg_y_position": np.mean(all_y_coords) if all_y_coords else 0,
            "document_type": "receipt",  # Could be enhanced with ML classification
        }

    def _extract_amount(self, text: str, regions: List[Dict]) -> Optional[float]:
        """Extract total amount from text."""
        # Common patterns for amounts
        patterns = [
            r"total[:\s]+\$?([\d,]+\.?\d*)",
            r"amount[:\s]+\$?([\d,]+\.?\d*)",
            r"grand\s+total[:\s]+\$?([\d,]+\.?\d*)",
            r"\$\s*([\d,]+\.?\d{2})",
        ]

        for pattern in patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                amount_str = match.group(1).replace(",", "")
                try:
                    return float(amount_str)
                except ValueError:
                    continue

        # Fallback: Find largest amount in text
        amounts = re.findall(r"\$?\s*([\d,]+\.\d{2})", text)
        if amounts:
            try:
                return max(float(amt.replace(",", "")) for amt in amounts)
            except ValueError:
                pass

        return None

    def _extract_date(self, text: str) -> Optional[str]:
        """Extract date from text."""
        # Common date patterns
        patterns = [
            r"(\d{4}[-/]\d{1,2}[-/]\d{1,2})",  # YYYY-MM-DD or YYYY/MM/DD
            r"(\d{1,2}[-/]\d{1,2}[-/]\d{4})",  # MM-DD-YYYY or DD/MM/YYYY
            r"(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+\d{1,2},?\s+\d{4}",
        ]

        for pattern in patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                return match.group(0)

        return None

    def _extract_vendor(self, regions: List[Dict]) -> Optional[str]:
        """Extract vendor name (usually first/top text region)."""
        if not regions:
            return None

        # Sort by vertical position (top to bottom)
        sorted_regions = sorted(regions, key=lambda r: min(p[1] for p in r["bbox"]))

        # Return first region with high confidence
        for region in sorted_regions[:3]:  # Check top 3 regions
            if region["confidence"] > 0.8 and len(region["text"]) > 3:
                return region["text"]

        return sorted_regions[0]["text"] if sorted_regions else None

    def _extract_description(self, text: str) -> Optional[str]:
        """Extract expense description."""
        # Look for common description keywords
        patterns = [
            r"description[:\s]+(.+)",
            r"memo[:\s]+(.+)",
            r"note[:\s]+(.+)",
        ]

        for pattern in patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                return match.group(1).strip()

        # Fallback: Use first 50 characters of text
        return text[:50] if text else None

    def _extract_tax(self, text: str, regions: List[Dict]) -> Optional[float]:
        """Extract tax amount."""
        patterns = [
            r"tax[:\s]+\$?([\d,]+\.?\d*)",
            r"vat[:\s]+\$?([\d,]+\.?\d*)",
            r"gst[:\s]+\$?([\d,]+\.?\d*)",
        ]

        for pattern in patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                tax_str = match.group(1).replace(",", "")
                try:
                    return float(tax_str)
                except ValueError:
                    continue

        return None

    def _extract_currency(self, text: str) -> Optional[str]:
        """Extract currency code."""
        # Look for currency symbols or codes
        if "$" in text or "usd" in text.lower():
            return "USD"
        elif "€" in text or "eur" in text.lower():
            return "EUR"
        elif "£" in text or "gbp" in text.lower():
            return "GBP"

        return "USD"  # Default

    def _extract_payment_method(self, text: str) -> Optional[str]:
        """Extract payment method."""
        text_lower = text.lower()

        if "credit" in text_lower or "visa" in text_lower or "mastercard" in text_lower:
            return "Credit Card"
        elif "debit" in text_lower:
            return "Debit Card"
        elif "cash" in text_lower:
            return "Cash"
        elif "paypal" in text_lower:
            return "PayPal"

        return None
