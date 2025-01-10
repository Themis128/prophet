#!/bin/bash

echo "Cleaning up unneeded Docker containers, images, and volumes..."

# Remove all stopped containers
echo "Removing stopped containers..."
docker rm $(docker ps -aq -f status=exited) 2>/dev/null || echo "No stopped containers to remove."

# Remove dangling images
echo "Removing dangling images..."
docker rmi $(docker images -f "dangling=true" -q) 2>/dev/null || echo "No dangling images to remove."

# Remove unused volumes
echo "Removing unused volumes..."
docker volume rm $(docker volume ls -qf dangling=true) 2>/dev/null || echo "No unused volumes to remove."

# Restarting Docker Compose services
echo "Rebuilding and restarting Docker Compose services..."
docker-compose down
docker-compose up --build -d

# Checking service statuses
echo "Checking running containers..."
docker ps

# Checking for errors in exited containers
echo "Checking logs for any errors in recently exited containers..."
EXITED_CONTAINERS=$(docker ps -aq -f status=exited)
if [ -n "$EXITED_CONTAINERS" ]; then
  echo "Found exited containers. Checking logs..."
  for container in $EXITED_CONTAINERS; do
    echo "Logs for container ID $container:"
    docker logs $container
    echo "---------------------------------------"
  done
else
  echo "No exited containers found."
fi

echo "Docker cleanup and restart completed. Please check the logs above for any unresolved errors."
