# Base image using Alpine 3.20
FROM alpine:3.20

# Install dependencies
RUN apk add --no-cache python3 py3-pip tesseract-ocr tesseract-ocr-data-eng ghostscript unpaper pngquant qpdf \
    python3-dev gcc libc-dev libffi-dev jpeg-dev zlib-dev

# Create Python virtual environment and install packages
RUN python3 -m venv /opt/venv

RUN /opt/venv/bin/pip install --upgrade pip && \
    /opt/venv/bin/pip install --no-cache-dir \
    ocrmypdf \
    boto3 \
    pillow

# Symlink ocrmypdf binary to make it available in PATH
RUN ln -sf /opt/venv/bin/ocrmypdf /usr/local/bin/ocrmypdf

# Set working directory
WORKDIR /app

# Copy OCR processor script into container
COPY ocr_processor.py /app/ocr_processor.py

# Make the OCR processor script executable
RUN chmod +x /app/ocr_processor.py

# Start the OCR processor
CMD ["/opt/venv/bin/python", "/app/ocr_processor.py"]