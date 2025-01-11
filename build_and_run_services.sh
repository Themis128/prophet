#!/bin/bash

# Set the project root and version tag
PROJECT_ROOT="/home/tbaltzakis/prophet-main/prophet-main"
VERSION_TAG="v0.0.1"

echo "Starting the build and setup process with docker-compose..."

# Step 1: Navigate to the project root
if cd "$PROJECT_ROOT"; then
  echo "Navigated to project root: $PROJECT_ROOT"
else
  echo "Project root not found: $PROJECT_ROOT. Exiting."
  exit 1
fi

# Step 2: Stop and remove all existing containers managed by docker-compose
echo "Stopping and removing existing containers..."
docker-compose down --volumes --remove-orphans

# Step 3: Remove any stray containers with conflicting names
echo "Removing any conflicting containers..."
docker rm -f postgres_service flask_service prophet_service jupyterlab_service 2>/dev/null || true

# Step 4: Clean up old images
echo "Removing old images..."
docker rmi -f baltzakist/flask_service:$VERSION_TAG 2>/dev/null || true
docker rmi -f baltzakist/prophet_service:$VERSION_TAG 2>/dev/null || true
docker rmi -f baltzakist/jupyterlab_service:$VERSION_TAG 2>/dev/null || true

# Step 5: Build new images and tag them
echo "Building services using docker-compose..."
if docker-compose build; then
  echo "Docker images built successfully."
else
  echo "Failed to build Docker images. Exiting."
  exit 1
fi

# Step 6: Start all services
echo "Starting all services with docker-compose..."
if docker-compose up -d; then
  echo "Services started successfully."
else
  echo "Failed to start services. Exiting."
  exit 1
fi

# Step 7: Confirm running containers
echo "Checking running containers..."
docker ps

# Final Message
echo "All services are up and running!"
