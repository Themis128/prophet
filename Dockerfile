# Use Python 3.9 slim image as the base
FROM python:3.9-slim

# Set the working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    g++ \
    make \
    libffi-dev \
    libssl-dev \
    libpython3-dev \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt /app/
RUN pip install --upgrade pip && pip install --no-cache-dir -r requirements.txt

# Install cmdstan binaries for cmdstanpy
RUN python -c "from cmdstanpy import install_cmdstan; install_cmdstan(cores=2)"

# Copy application code
COPY . /app

# Add a health check to ensure the container is ready
HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:5001/health || exit 1

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH="/app"

# Expose the service port
EXPOSE 5001

# Default command to run the app
CMD ["python", "app/app.py"]
