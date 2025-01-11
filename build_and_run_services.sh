#!/bin/bash

# Set the project root and version tag
PROJECT_ROOT="/home/tbaltzakis/prophet-main/prophet-main"
VERSION_TAG="v0.0.1"

echo "Starting the build and setup process with docker-compose..."

# Step 1: Navigate to the project root
if cd "$PROJECT_ROOT"; then
  echo "Navigated to project root: $PROJECT_ROOT"
else
  echo "Error: Project root not found: $PROJECT_ROOT. Exiting."
  exit 1
fi

# Step 2: Stop and remove all existing containers managed by docker-compose
echo "Stopping and removing existing containers..."
if docker-compose down --volumes --remove-orphans; then
  echo "Containers stopped and removed successfully."
else
  echo "Warning: Some containers may not have been stopped or removed. Continuing."
fi

# Step 3: Remove any stray containers with conflicting names
echo "Removing any conflicting containers..."
for container in postgres_service flask_service prophet_service jupyterlab_service; do
  if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
    if docker rm -f "$container"; then
      echo "Removed container: $container"
    else
      echo "Warning: Failed to remove container: $container"
    fi
  fi
done

# Step 4: Remove old images
echo "Removing old images..."
for image in baltzakist/flask_service:$VERSION_TAG baltzakist/prophet_service:$VERSION_TAG baltzakist/jupyterlab_service:$VERSION_TAG; do
  if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${image}$"; then
    if docker rmi -f "$image"; then
      echo "Removed image: $image"
    else
      echo "Warning: Failed to remove image: $image"
    fi
  fi
done

# Step 5: Build new images
echo "Building new images..."
if docker-compose build; then
  echo "Docker images built successfully."
else
  echo "Error: Failed to build Docker images. Exiting."
  exit 1
fi

# Step 6: Tag images
echo "Tagging new images..."
for service in flask_service prophet_service jupyterlab_service; do
  if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${service}:latest$"; then
    if docker tag "${service}:latest" "baltzakist/${service}:${VERSION_TAG}"; then
      echo "Tagged image: ${service}"
    else
      echo "Error: Failed to tag image for ${service}. Exiting."
      exit 1
    fi
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

# Step 8: Confirm running containers
echo "Checking running containers..."
if docker ps; then
  echo "All services are running:"
  docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
else
  echo "Warning: Unable to verify running containers."
fi

# Step 9: Wait for PostgreSQL to be ready
echo "Verifying PostgreSQL database initialization..."
for i in {1..10}; do
  if docker exec postgres_service pg_isready -U user; then
    echo "PostgreSQL is ready and accepting connections."
    break
  else
    echo "Waiting for PostgreSQL to be ready... (attempt $i)"
    sleep 5
  fi

  if [ "$i" -eq 10 ]; then
    echo "Error: PostgreSQL is not ready after multiple attempts. Check PostgreSQL logs."
    docker logs postgres_service
    exit 1
  fi
done

# Step 10: Test database connectivity
echo "Testing database connectivity..."
if docker exec postgres_service psql -U user -d prophet_db -c "\dt"; then
  echo "Database initialized and accessible."
else
  echo "Warning: Database initialization verification failed. Check PostgreSQL logs."
  docker logs postgres_service
fi

# Final Message
echo "All services are up and running!"
