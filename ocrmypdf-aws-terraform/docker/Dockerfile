FROM alpine:latest

RUN apk add --no-cache \
    python3 \
    py3-pip \
    tesseract-ocr \
    tesseract-ocr-data-eng \
    ghostscript \
    unpaper \
    pngquant \
    qpdf \
    python3-dev \
    gcc \
    libc-dev \
    libffi-dev \
    jpeg-dev \
    zlib-dev

RUN python3 -m venv /opt/venv

RUN /opt/venv/bin/pip install --upgrade pip && \
    /opt/venv/bin/pip install --no-cache-dir \
    ocrmypdf \
    boto3 \
    pillow

WORKDIR /app

COPY ocr_processor.py /app/ocr_processor.py
RUN chmod +x /app/ocr_processor.py

CMD ["/opt/venv/bin/python", "/app/ocr_processor.py"]
