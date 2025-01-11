#!/bin/bash

# Constants
PROJECT_ROOT="/home/tbaltzakis/prophet-main/prophet-main"
VERSION_TAG="v0.0.1"
SERVICES=("postgres_service" "flask_service" "prophet_service" "jupyterlab_service")
IMAGES=("baltzakist/flask_service:$VERSION_TAG" "baltzakist/prophet_service:$VERSION_TAG" "baltzakist/jupyterlab_service:$VERSION_TAG")

echo "Starting the build and setup process with docker-compose..."

# Step 1: Navigate to the project root
if cd "$PROJECT_ROOT"; then
  echo "Navigated to project root: $PROJECT_ROOT"
else
  echo "Error: Project root not found: $PROJECT_ROOT. Exiting."
  exit 1
fi

# Step 2: Stop and remove existing containers and volumes
echo "Stopping and removing existing containers and volumes..."
docker-compose down --volumes --remove-orphans || echo "Warning: Some containers may not have been removed. Continuing."

# Step 3: Remove conflicting containers
echo "Removing any conflicting containers..."
for container in "${SERVICES[@]}"; do
  if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
    docker rm -f "$container" && echo "Removed container: $container" || echo "Warning: Failed to remove container: $container"
  fi
done

# Step 4: Remove old images
echo "Removing old images..."
for image in "${IMAGES[@]}"; do
  if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${image}$"; then
    docker rmi -f "$image" && echo "Removed image: $image" || echo "Warning: Failed to remove image: $image"
  fi
done

# Step 5: Build new images
echo "Building new Docker images..."
if docker-compose build --no-cache; then
  echo "Docker images built successfully."
else
  echo "Error: Failed to build Docker images. Exiting."
  exit 1
fi

# Step 6: Tag images
echo "Tagging new images..."
for service in flask_service prophet_service jupyterlab_service; do
  if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${service}:latest$"; then
    docker tag "${service}:latest" "baltzakist/${service}:${VERSION_TAG}" && echo "Tagged image: ${service}" || {
      echo "Error: Failed to tag image for ${service}. Exiting."
      exit 1
    }
  else
    echo "Error: Could not find image for ${service}. Exiting."
    exit 1
  fi
done

# Step 7: Start all services
echo "Starting all services with docker-compose..."
if docker-compose up -d; then
  echo "Services started successfully."
else
  echo "Error: Failed to start services. Exiting."
  exit 1
fi

# Step 8: Verify running containers
echo "Checking running containers..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || echo "Warning: Unable to verify running containers."

# Step 9: Wait for PostgreSQL readiness
echo "Verifying PostgreSQL database initialization..."
for attempt in {1..10}; do
  if docker exec postgres_service pg_isready -U user; then
    echo "PostgreSQL is ready and accepting connections."
    break
  else
    echo "Waiting for PostgreSQL to be ready... (attempt $attempt)"
    sleep 5
  fi
  if [ "$attempt" -eq 10 ]; then
    echo "Error: PostgreSQL is not ready after multiple attempts. Check PostgreSQL logs."
    docker logs postgres_service
    exit 1
  fi
done

# Step 10: Test database connectivity and create the database if it does not exist
echo "Testing database connectivity..."
if docker exec postgres_service psql -U user -d postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'prophet_db';" | grep -q 1; then
  echo "Database 'prophet_db' already exists."
else
  echo "Database 'prophet_db' does not exist. Creating it..."
  if docker exec postgres_service psql -U user -d postgres -c "CREATE DATABASE prophet_db;"; then
    echo "Database 'prophet_db' created successfully."
  else
    echo "Error: Failed to create database 'prophet_db'. Check PostgreSQL logs."
    docker logs postgres_service
    exit 1
  fi
fi

if docker exec postgres_service psql -U user -d prophet_db -c "\dt"; then
  echo "Database initialized and accessible."
else
  echo "Error: Database connectivity verification failed. Check logs."
  docker logs postgres_service
  exit 1
fi

# Step 11: Verify health of services
echo "Verifying the health of services..."
for service in "${SERVICES[@]}"; do
  echo "Checking $service..."
  if docker ps --filter "name=$service" --filter "health=healthy" --format '{{.Names}}' | grep -q "^${service}$"; then
    echo "$service is healthy."
  else
    echo "Warning: $service is not healthy or health check not configured. Checking logs..."
    docker logs "$service" || echo "Warning: Unable to fetch logs for $service."
  fi
done

# Final Message
echo "All services are up and running! Visit your application or check logs for further details."
