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

# Add and set up start-notebook.sh for JupyterLab
COPY start-notebook.sh /usr/local/bin/start-notebook.sh
RUN chmod +x /usr/local/bin/start-notebook.sh

# Environment variables for Flask, Gunicorn, and Prophet
ENV FLASK_APP=app.py
ENV FLASK_ENV=production

# Expose ports for Flask and JupyterLab
EXPOSE 5000 8888

# Default command for determining service behavior
# Use an environment variable to switch between services
ARG SERVICE=flask

# Default command
CMD ["/bin/bash", "-c", "\
    if [ \"$SERVICE\" = \"flask\" ]; then \
        gunicorn -b 0.0.0.0:5000 app:app; \
    elif [ \"$SERVICE\" = \"jupyterlab\" ]; then \
        /usr/local/bin/start-notebook.sh; \
    elif [ \"$SERVICE\" = \"prophet\" ]; then \
        python -m prophet.main; \
    else \
        echo \"Unknown SERVICE: $SERVICE\" && exit 1; \
    fi"]
