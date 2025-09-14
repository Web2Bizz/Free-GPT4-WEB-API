# FreeGPT4 API Service Dockerfile

FROM python:3.12-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    chromium \
    libsqlite3-dev \
    gcc \
    g++ \
    make \
    && rm -rf /var/lib/apt/lists/*

# Create user
# RUN groupadd -r freegpt && useradd -r -g freegpt freegpt

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Install the package in development mode
RUN pip install -e .

# Create necessary directories
RUN mkdir -p /app/logs \
    && mkdir -p /app/data \
    && chmod -R 755 /app/data \
    && chmod -R 755 /app/logs

# Keep running as root for now to avoid permission issues with mounted volumes
# USER freegpt

# Set Python path
ENV PYTHONPATH="/app/src"

# Expose port
EXPOSE 5500

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:5500/models || exit 1

# Default command
CMD ["python", "-m", "freegpt4.FreeGPT4_Server"]
