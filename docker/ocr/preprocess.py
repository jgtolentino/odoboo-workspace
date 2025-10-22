#!/usr/bin/env python3
"""
Image Preprocessing for OCR
Implements deskew, denoise, and binarization for better OCR accuracy
"""

import cv2
import numpy as np
from PIL import Image


def preprocess_image(pil_image: Image.Image, target_dpi: int = 300) -> Image.Image:
    """
    Preprocess image for optimal OCR results

    Steps:
    1. Convert to grayscale
    2. Resize to target DPI (300)
    3. Denoise with bilateral filter
    4. Deskew using Hough transform
    5. Adaptive threshold binarization

    Args:
        pil_image: PIL Image object
        target_dpi: Target DPI for OCR (default 300)

    Returns:
        Preprocessed PIL Image
    """
    # Convert PIL to OpenCV format
    img_array = np.array(pil_image)

    # Convert to grayscale
    if len(img_array.shape) == 3:
        gray = cv2.cvtColor(img_array, cv2.COLOR_RGB2GRAY)
    else:
        gray = img_array

    # Resize to target DPI if needed
    height, width = gray.shape
    if width > 2000:  # Downscale if too large
        scale = 2000 / width
        new_width = int(width * scale)
        new_height = int(height * scale)
        gray = cv2.resize(gray, (new_width, new_height), interpolation=cv2.INTER_AREA)

    # Denoise
    denoised = cv2.bilateralFilter(gray, 9, 75, 75)

    # Deskew
    deskewed = deskew_image(denoised)

    # Adaptive threshold binarization
    binary = cv2.adaptiveThreshold(
        deskewed,
        255,
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY,
        11,
        2
    )

    # Convert back to PIL
    return Image.fromarray(binary)


def deskew_image(image: np.ndarray, max_angle: float = 10.0) -> np.ndarray:
    """
    Deskew image using Hough line detection

    Args:
        image: Grayscale image array
        max_angle: Maximum rotation angle to consider (degrees)

    Returns:
        Deskewed image array
    """
    # Edge detection
    edges = cv2.Canny(image, 50, 150, apertureSize=3)

    # Hough line detection
    lines = cv2.HoughLines(edges, 1, np.pi / 180, 200)

    if lines is None:
        return image  # No lines detected, return original

    # Calculate dominant angle
    angles = []
    for rho, theta in lines[:, 0]:
        angle = np.degrees(theta) - 90
        if -max_angle <= angle <= max_angle:
            angles.append(angle)

    if not angles:
        return image

    # Median angle
    median_angle = np.median(angles)

    # Rotate image
    (h, w) = image.shape
    center = (w // 2, h // 2)
    M = cv2.getRotationMatrix2D(center, median_angle, 1.0)
    rotated = cv2.warpAffine(
        image,
        M,
        (w, h),
        flags=cv2.INTER_CUBIC,
        borderMode=cv2.BORDER_REPLICATE
    )

    return rotated


def remove_borders(image: np.ndarray, border_percent: float = 0.02) -> np.ndarray:
    """
    Remove borders from scanned documents

    Args:
        image: Image array
        border_percent: Percentage of border to remove (0.02 = 2%)

    Returns:
        Image with borders removed
    """
    h, w = image.shape[:2]
    border_h = int(h * border_percent)
    border_w = int(w * border_percent)

    return image[border_h:h-border_h, border_w:w-border_w]


def enhance_contrast(image: np.ndarray) -> np.ndarray:
    """
    Enhance image contrast using CLAHE (Contrast Limited Adaptive Histogram Equalization)

    Args:
        image: Grayscale image array

    Returns:
        Contrast-enhanced image
    """
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    return clahe.apply(image)
