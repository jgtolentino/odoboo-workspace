# PaddleOCR Service for Receipt/Invoice Processing
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libgomp1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgl1 \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install --no-cache-dir \
    fastapi==0.104.1 \
    uvicorn[standard]==0.24.0 \
    python-multipart==0.0.6 \
    pillow==10.1.0 \
    paddlepaddle==2.6.0 \
    paddleocr==2.7.3 \
    pytesseract==0.3.10 \
    opencv-python-headless==4.8.1.78

# Force NumPy 1.x for ABI compatibility (must be after other dependencies)
RUN pip install --no-cache-dir --force-reinstall numpy==1.24.3

# Download PaddleOCR models on build (saves startup time)
RUN python -c "from paddleocr import PaddleOCR; ocr = PaddleOCR(use_angle_cls=True, lang='en', use_gpu=False, show_log=False)"

# Copy application code
COPY app.py /app/
COPY preprocess.py /app/

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/health')"

# Run application
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
