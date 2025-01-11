#!/bin/bash

# Constants
CONTAINER_NAME="postgres_service"
VOLUME_NAME="prophet-main_db_data"

echo "Starting PostgreSQL troubleshooting..."

# Step 1: Stop the Docker Compose services
echo "Stopping services..."
docker-compose down --volumes || {
  echo "Error: Failed to stop services. Exiting."
  exit 1
}

# Step 2: Remove old PostgreSQL volume
echo "Removing old PostgreSQL volume: $VOLUME_NAME..."
docker volume rm $VOLUME_NAME || {
  echo "Warning: Failed to remove volume $VOLUME_NAME. Continuing..."
}

# Step 3: Recreate services with Docker Compose
echo "Rebuilding and starting services..."
docker-compose build && docker-compose up -d || {
  echo "Error: Failed to rebuild or start services. Exiting."
  exit 1
}

# Step 4: Wait for PostgreSQL to initialize
echo "Waiting for PostgreSQL to initialize..."
for i in {1..10}; do
  if docker exec $CONTAINER_NAME pg_isready -U user; then
    echo "PostgreSQL is ready and accepting connections."
    break
  else
    echo "Waiting for PostgreSQL to be ready... (attempt $i)"
    sleep 5
  fi
  if [ $i -eq 10 ]; then
    echo "Error: PostgreSQL is not ready after multiple attempts. Exiting."
    docker logs $CONTAINER_NAME
    exit 1
  fi
done

# Step 5: Verify database existence
echo "Verifying database 'prophet_db' existence..."
docker exec $CONTAINER_NAME psql -U user -d postgres -c "\l" | grep prophet_db > /dev/null

if [ $? -eq 0 ]; then
  echo "Database 'prophet_db' exists and is accessible."
else
  echo "Database 'prophet_db' does not exist. Creating it now..."
  docker exec $CONTAINER_NAME psql -U user -d postgres -c "CREATE DATABASE prophet_db;" || {
    echo "Error: Failed to create database 'prophet_db'. Exiting."
    exit 1
  }
fi

# Step 6: Verify health check status
echo "Checking PostgreSQL health check..."
HEALTH_STATUS=$(docker inspect --format='{{json .State.Health.Status}}' $CONTAINER_NAME)

if [ "$HEALTH_STATUS" == "\"healthy\"" ]; then
  echo "PostgreSQL is healthy."
else
  echo "Warning: PostgreSQL health check failed. Check logs for details."
  docker logs $CONTAINER_NAME
fi

# Final confirmation
echo "PostgreSQL troubleshooting complete. Verify other services if needed."
