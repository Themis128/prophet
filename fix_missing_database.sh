#!/bin/bash

# Define variables
POSTGRES_CONTAINER="postgres_service"   # PostgreSQL container name
POSTGRES_USER="user"                    # Match the `POSTGRES_USER` in docker-compose.yml
POSTGRES_PASSWORD="password"            # Match the `POSTGRES_PASSWORD` in docker-compose.yml
DATABASE_NAME="prophet_db"              # Match the `POSTGRES_DB` in docker-compose.yml

# Check if the container is running
echo "Checking if the PostgreSQL container is running..."
if ! docker ps | grep -q $POSTGRES_CONTAINER; then
    echo "PostgreSQL container '$POSTGRES_CONTAINER' is not running. Starting it..."
    docker start $POSTGRES_CONTAINER
    if [ $? -ne 0 ]; then
        echo "Failed to start the PostgreSQL container. Exiting."
        exit 1
    fi
fi

# Wait for the container to be ready
echo "Waiting for PostgreSQL to be ready..."
until docker exec -e PGPASSWORD=$POSTGRES_PASSWORD $POSTGRES_CONTAINER pg_isready -U $POSTGRES_USER > /dev/null 2>&1; do
    sleep 1
    echo -n "."
done
echo " PostgreSQL is ready!"

# Check if the database exists
echo "Checking if the database '$DATABASE_NAME' exists..."
DATABASE_EXISTS=$(docker exec -e PGPASSWORD=$POSTGRES_PASSWORD $POSTGRES_CONTAINER \
    psql -U $POSTGRES_USER -tAc "SELECT 1 FROM pg_database WHERE datname = '$DATABASE_NAME';")

if [ "$DATABASE_EXISTS" == "1" ]; then
    echo "Database '$DATABASE_NAME' already exists. No action needed."
else
    # Create the missing database
    echo "Database '$DATABASE_NAME' does not exist. Creating it..."
    docker exec -e PGPASSWORD=$POSTGRES_PASSWORD $POSTGRES_CONTAINER \
        psql -U $POSTGRES_USER -c "CREATE DATABASE $DATABASE_NAME;"
    if [ $? -eq 0 ]; then
        echo "Database '$DATABASE_NAME' created successfully."
    else
        echo "Failed to create the database. Please check the PostgreSQL logs for details."
        exit 1
    fi
fi

echo "Script completed successfully."
