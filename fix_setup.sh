#!/bin/bash

# Exit on any error
set -e

echo "=== Fixing directory structure ==="

# Ensure necessary directories exist
mkdir -p notebooks
mkdir -p docs/static
mkdir -p R

# Example files
echo "Creating example files for required directories..."
touch notebooks/example_notebook.ipynb
echo "# Welcome to Jupyter!" > notebooks/example_notebook.ipynb

cat > docs/_config.yml <<EOL
title: Prophet Documentation
description: Documentation for Prophet Project
baseurl: ""
url: ""
plugins:
  - jekyll-feed
EOL

echo "Prophet Documentation" > docs/index.md
echo "This is an example static file." > docs/static/example.txt

echo "print('Example R script')" > R/example_script.R

echo "=== Fixing Dockerfile issues ==="

# Check for and download start-notebook.sh if not present
if ! grep -q "start-notebook.sh" Dockerfile; then
  echo "Adding start-notebook.sh installation to Dockerfile..."
  sed -i '/# Expose ports for JupyterLab and Jekyll/i \
RUN wget -O /usr/local/bin/start-notebook.sh https://raw.githubusercontent.com/jupyter/docker-stacks/main/base-notebook/start-notebook.sh && chmod +x /usr/local/bin/start-notebook.sh' Dockerfile
else
  echo "start-notebook.sh installation already present in Dockerfile."
fi

echo "=== Fixing Python dependencies ==="

# Create an example requirements.txt if not already present
if [ ! -f requirements.txt ]; then
  echo "flask" > requirements.txt
  echo "requests" >> requirements.txt
  echo "numpy" >> requirements.txt
  echo "Example requirements.txt created."
else
  echo "requirements.txt already exists."
fi

echo "=== Fixing Ruby dependencies ==="

# Create a Gemfile if not present
if [ ! -f docs/Gemfile ]; then
  cat > docs/Gemfile <<EOL
source "https://rubygems.org"
gem "jekyll", "~> 3.9"
gem "jekyll-feed", "~> 0.12"
EOL
  echo "Gemfile created in docs directory."
else
  echo "Gemfile already exists in docs directory."
fi

# Run bundle install for Jekyll
echo "Installing Ruby dependencies..."
docker run --rm -v $(pwd)/docs:/docs -w /docs ruby:3.2 bash -c "gem install bundler && bundle install"

echo "=== Fixing database health check ==="

# Add database health check to docker-compose.yml if missing
if ! grep -q "healthcheck:" docker-compose.yml; then
  sed -i '/environment:/a \
    healthcheck: \
      test: ["CMD-SHELL", "pg_isready -U user"] \
      interval: 10s \
      retries: 5' docker-compose.yml
  echo "Database health check added to docker-compose.yml."
else
  echo "Database health check already exists in docker-compose.yml."
fi

echo "=== Building and starting services ==="

# Build and start services
docker-compose build
docker-compose up -d

echo "=== Setup complete! ==="
echo "Access JupyterLab at http://localhost:8889"
echo "Access Jekyll at http://localhost:4000"
