# Use Python 3.9 slim as the base image
FROM python:3.9-slim

# Set the working directory
WORKDIR /app

# Install system dependencies required for Prophet and Stan
RUN apt-get update && apt-get install -y \
    build-essential \
    libatlas-base-dev \
    python3-dev \
    cmake \
    g++ \
    && apt-get clean

# Copy the requirements file into the container
COPY requirements.txt /app/

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Install Prophet's required Stan backend (pystan or cmdstanpy)
RUN pip install --no-cache-dir pystan==2.19.1.1 prophet

# Install optional dependencies like Plotly (if needed for interactive plots)
RUN pip install --no-cache-dir plotly

# Ensure the data directory exists
RUN mkdir -p /app/data

# Ensure the Stan model directory exists and copy files
COPY ./python/stan /app/python/stan

# Copy the entire project into the container
COPY . /app/

# Set the entry point for the container
ENTRYPOINT ["python", "-m", "prophet.main"]
