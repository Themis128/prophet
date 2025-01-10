#!/bin/bash

# Define paths
WORK_DIR="/home/tbaltzakis/prophet-main/prophet-main"
STATIC_DIR="$WORK_DIR/docs/static"
DOCS_DIR="$WORK_DIR/docs/docs/static"
CONFIG_FILE="$WORK_DIR/docs/_config.yml"
DOCKER_COMPOSE="$WORK_DIR/docker-compose.yml"

echo "Ensuring the correct location of prophet_paper_20170113.pdf..."

# Ensure the static directory and file exist
if [ ! -f "$STATIC_DIR/prophet_paper_20170113.pdf" ]; then
  echo "Error: File 'prophet_paper_20170113.pdf' not found in $STATIC_DIR."
  exit 1
fi

# Create missing directory if necessary
if [ ! -d "$DOCS_DIR" ]; then
  echo "Creating missing directory: $DOCS_DIR"
  mkdir -p "$DOCS_DIR"
fi

# Copy the file to the required location
echo "Copying the file to $DOCS_DIR..."
cp "$STATIC_DIR/prophet_paper_20170113.pdf" "$DOCS_DIR"

# Fix incorrect references in the Jekyll configuration file
echo "Fixing configuration references in $CONFIG_FILE..."
if grep -q "docs/docs/static/prophet_paper_20170113.pdf" "$CONFIG_FILE"; then
  sed -i 's|docs/docs/static/prophet_paper_20170113.pdf|static/prophet_paper_20170113.pdf|g' "$CONFIG_FILE"
else
  echo "No incorrect references found in $CONFIG_FILE."
fi

# Update docker-compose.yml for start-notebook.sh
echo "Ensuring start-notebook.sh is properly referenced in $DOCKER_COMPOSE..."
if grep -q "start-notebook.sh" "$DOCKER_COMPOSE"; then
  sed -i 's|start-notebook.sh|/usr/local/bin/start-notebook.sh|g' "$DOCKER_COMPOSE"
else
  echo "start-notebook.sh reference not found in $DOCKER_COMPOSE."
fi

# Rebuild and restart Docker containers
echo "Rebuilding and restarting Docker containers..."
cd "$WORK_DIR"
docker compose down
docker compose up -d --build

# Check container logs for issues
echo "Checking logs for the prophet_service container..."
docker logs prophet_service

echo "Script completed."
