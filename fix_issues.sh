#!/bin/bash

echo "Fixing PostgreSQL Database Initialization and Services Setup..."

# Step 1: Remove existing Docker volumes and containers
echo "Removing existing Docker volumes and containers..."
docker-compose down -v

# Step 2: Check and fix database initialization
echo "Setting up PostgreSQL database initialization..."
DB_INIT_SCRIPT="./db/init.sql"
DB_VOLUME="prophet-main_db_data"

# Ensure the init script exists
if [ ! -f "$DB_INIT_SCRIPT" ]; then
  echo "Database initialization script not found. Creating one..."
  mkdir -p ./db
  cat <<EOF > "$DB_INIT_SCRIPT"
CREATE DATABASE prophet_db;
EOF
fi

# Recreate database volume
echo "Recreating database volume..."
docker volume rm $DB_VOLUME || true
docker volume create $DB_VOLUME

# Step 3: Fix Flask, Prophet, and JupyterLab service entry points
echo "Fixing service entry points in Dockerfiles..."
# Check and update Flask Dockerfile
FLASK_DOCKERFILE="./flask/Dockerfile"
if [ -f "$FLASK_DOCKERFILE" ]; then
  sed -i 's/^CMD.*/CMD ["python", "main.py"]/g' "$FLASK_DOCKERFILE"
fi

# Check and update Prophet Dockerfile
PROPHET_DOCKERFILE="./prophet/Dockerfile"
if [ -f "$PROPHET_DOCKERFILE" ]; then
  sed -i 's/^CMD.*/CMD ["python", "main.py"]/g' "$PROPHET_DOCKERFILE"
fi

# Check and update JupyterLab Dockerfile
JUPYTER_DOCKERFILE="./jupyterlab/Dockerfile"
if [ -f "$JUPYTER_DOCKERFILE" ]; then
  sed -i 's/^CMD.*/CMD ["jupyter", "lab", "--ip=0.0.0.0", "--allow-root"]/g' "$JUPYTER_DOCKERFILE"
fi

# Step 4: Rebuild the Docker images
echo "Rebuilding Docker images..."
docker-compose build

# Step 5: Start services
echo "Starting services..."
docker-compose up -d

# Step 6: Verify database and services
echo "Verifying PostgreSQL database..."
docker exec -it postgres_service psql -U postgres -c '\l' || {
  echo "Database 'prophet_db' not found. Creating it now..."
  docker exec -it postgres_service psql -U postgres -c 'CREATE DATABASE prophet_db;'
}

echo "Testing Flask service..."
curl -s http://localhost:5000 || echo "Flask service may not be running correctly. Check logs."

echo "Testing JupyterLab service..."
curl -s http://localhost:8888 || echo "JupyterLab service may not be running correctly. Check logs."

# Step 7: Provide instructions for further debugging if necessary
echo "If services are not working as expected, check their logs:"
echo "  docker logs flask_service"
echo "  docker logs prophet_service"
echo "  docker logs jupyterlab_service"
echo "  docker logs postgres_service"

echo "Done! All services should be running now."
