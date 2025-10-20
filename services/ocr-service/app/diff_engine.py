# -*- coding: utf-8 -*-
import logging
from typing import Dict, Any
from jsondiff import diff

logger = logging.getLogger(__name__)


class DiffEngine:
    """Visual and JSON diff engine for document comparison."""

    def calculate_field_similarity(
        self, original_fields: Dict[str, Any], current_fields: Dict[str, Any]
    ) -> float:
        """
        Calculate similarity score based on field matching.

        Args:
            original_fields: Original extracted fields
            current_fields: Current extracted fields

        Returns:
            float: Similarity score (0-1)
        """
        # Compare key fields
        key_fields = ["total_amount", "date", "vendor", "currency"]

        matches = 0
        comparisons = 0

        for field in key_fields:
            original_val = original_fields.get(field)
            current_val = current_fields.get(field)

            if original_val is not None or current_val is not None:
                comparisons += 1

                if original_val == current_val:
                    matches += 1
                elif isinstance(original_val, (int, float)) and isinstance(
                    current_val, (int, float)
                ):
                    # Allow small differences for amounts (within 1%)
                    if abs(original_val - current_val) / max(original_val, 1) < 0.01:
                        matches += 1

        return matches / comparisons if comparisons > 0 else 1.0

    def calculate_json_diff(
        self, original_fields: Dict[str, Any], current_fields: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Calculate JSON diff between original and current fields.

        Args:
            original_fields: Original extracted fields
            current_fields: Current extracted fields

        Returns:
            dict: Changes with old and new values
        """
        changes = {}

        # Get all unique keys
        all_keys = set(original_fields.keys()) | set(current_fields.keys())

        for key in all_keys:
            original_val = original_fields.get(key)
            current_val = current_fields.get(key)

            if original_val != current_val:
                changes[key] = {"old": original_val, "new": current_val}

        return changes
