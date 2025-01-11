# Use Python 3.9 slim as the base image
FROM python:3.9-slim

# Set the working directory
WORKDIR /app

# Install system dependencies required for Prophet and Stan
RUN apt-get update && apt-get install -y \
    build-essential \
    libatlas-base-dev \
    python3-dev \
    && apt-get clean

# Copy the requirements file and install Python dependencies
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy the entire project into the container
COPY . /app/

# Ensure the data directory exists
RUN mkdir -p /app/data

# Ensure the Stan model directory exists and copy files
COPY ./python/stan /app/python/stan

# Set the entry point for the container
ENTRYPOINT ["python", "-m", "prophet.main"]
