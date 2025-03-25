# Base image using Alpine 3.17
FROM alpine:3.17

# Install dependencies
RUN apk add --no-cache python3 py3-pip tesseract-ocr tesseract-ocr-data-eng ghostscript unpaper pngquant qpdf \
    python3-dev gcc libc-dev libffi-dev jpeg-dev zlib-dev

# Create Python virtual environment and install packages
RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip && \
    /opt/venv/bin/pip install --no-cache-dir ocrmypdf boto3 pillow

# Set working directory
WORKDIR /app

# Copy OCR processor script into container
COPY ocr_processor.py .

# Make the OCR processor script executable
RUN chmod +x ocr_processor.py

# Start the OCR processor
CMD ["/opt/venv/bin/python", "ocr_processor.py"]
