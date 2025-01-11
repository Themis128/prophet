# Use a lightweight Python base image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    build-essential \
    libpython3-dev \
    libpq-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements file and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY ./app /app
COPY ./data /app/data

# Environment variables for Gunicorn
ENV FLASK_APP=app.py
ENV FLASK_ENV=production

# Expose Flask port
EXPOSE 5000

# Command to start Gunicorn
CMD ["gunicorn", "-b", "0.0.0.0:5000", "app:app"]
